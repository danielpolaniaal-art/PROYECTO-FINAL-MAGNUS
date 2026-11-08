import hashlib
import json
import re
import uuid
from decimal import Decimal, InvalidOperation
from functools import wraps

from django.conf import settings
from django.contrib.auth import authenticate, login, logout, update_session_auth_hash
from django.contrib.auth.models import User
from django.core.cache import cache
from django.db import DataError, IntegrityError, transaction
from django.db.models import ProtectedError, Q
from django.http import HttpResponse, JsonResponse
from django.middleware.csrf import get_token
from django.utils import timezone
from django.views.decorators.csrf import ensure_csrf_cookie
from django.views.decorators.http import require_http_methods

from .models import Category, Client, CompanyProfile, Product, Sale, SaleItem
from .reports import sales_report

EMAIL_RE = r"[^@\s]+@[^@\s]+\.[^@\s]+"
IVA = Decimal("0.19")  # IVA Colombia
PAYMENTS = ("Efectivo", "Tarjeta débito / crédito", "Transferencia bancaria", "Nequi / Daviplata")
DELIVERY_METHODS = ("pickup", "ship", "service")
MAX_SALE_LINES = 50       # productos distintos en una sola venta
MAX_LINE_QTY = 1000       # unidades por producto en una sola venta
LOGIN_MAX_FAILS = 8       # intentos fallidos por correo antes de bloquear
LOGIN_LOCK_SECONDS = 15 * 60
# Imagen de producto: solo foto en base64 (la que genera la pantalla) o una ruta interna img/...
IMAGE_RE = re.compile(r"data:image/(?:png|jpeg|webp|gif);base64,[A-Za-z0-9+/=]+|img/[A-Za-z0-9_./-]+")
MAX_IMAGE_CHARS = 1_500_000

R = CompanyProfile
ROLES = (R.ROLE_CLIENT, R.ROLE_ADVISOR, R.ROLE_SUPERVISOR, R.ROLE_ADMIN, R.ROLE_SUPER)
# Jerarquía: un rol mayor puede gestionar a uno menor.
RANK = {R.ROLE_CLIENT: 0, R.ROLE_ADVISOR: 1, R.ROLE_SUPERVISOR: 2, R.ROLE_ADMIN: 3, R.ROLE_SUPER: 4}


def response(data, status=200):
    return JsonResponse(data, status=status)


def body(request):
    try:
        value = json.loads(request.body or "{}")
    except json.JSONDecodeError as error:
        raise ValueError("El cuerpo de la solicitud debe ser JSON válido.") from error
    if not isinstance(value, dict):
        raise ValueError("El cuerpo de la solicitud debe ser un objeto JSON.")
    return value


def error_response(error, status=400):
    return response({"error": str(error)}, status)


# ---------- Roles y permisos ----------

def get_profile(user):
    """Devuelve el perfil (rol) del usuario; si no existe, lo crea."""
    try:
        return user.company_profile
    except CompanyProfile.DoesNotExist:
        role = R.ROLE_ADMIN if user.is_superuser else R.ROLE_ADVISOR
        return CompanyProfile.objects.create(user=user, role=role)


def role_of(user):
    return get_profile(user).role


def roles_required(*allowed):
    """Solo deja pasar a usuarios con alguno de los roles indicados."""
    def decorator(view):
        @wraps(view)
        def wrapper(request, *args, **kwargs):
            if not request.user.is_authenticated:
                return error_response("Debes iniciar sesión.", 401)
            if role_of(request.user) not in allowed:
                return error_response("Tu rol no tiene permiso para realizar esta acción.", 403)
            return view(request, *args, **kwargs)
        return wrapper
    return decorator


def login_required_api(view):
    @wraps(view)
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return error_response("Debes iniciar sesión.", 401)
        return view(request, *args, **kwargs)
    return wrapper


CATALOG_ROLES = (R.ROLE_ADMIN, R.ROLE_SUPERVISOR)       # crean y eliminan productos
SALE_ROLES = (R.ROLE_CLIENT, R.ROLE_ADVISOR, R.ROLE_SUPERVISOR, R.ROLE_ADMIN)
ORDER_ROLES = (R.ROLE_ADVISOR, R.ROLE_SUPERVISOR, R.ROLE_ADMIN)   # entregan o anulan pedidos


def assignable_roles(role):
    """Roles que alguien puede asignar: hasta su mismo nivel.
    El Superadministrador es único (el predeterminado): nadie puede asignar ese rol a otra persona."""
    return [r for r in ROLES if RANK[r] <= RANK[role] and r != R.ROLE_SUPER]


def can_modify(actor, target):
    """
    Un administrador puede dar rol a otros, pero nadie puede quitarle el rol
    a quien se lo dio ni al superadministrador.
      - Solo Administrador y Superadministrador gestionan usuarios.
      - No se puede modificar a uno mismo.
      - Se puede modificar a quien tenga un rol menor.
      - A uno de igual rango solo si tú le diste ese rol (y nunca a otro Superadministrador).
    """
    a, t = get_profile(actor), get_profile(target)
    if RANK[a.role] < RANK[R.ROLE_ADMIN] or actor.id == target.id:
        return False
    if RANK[a.role] > RANK[t.role]:
        return True
    return RANK[a.role] == RANK[t.role] and a.role != R.ROLE_SUPER and t.granted_by_id == actor.id


def as_client_mode(user, requested):
    """El Administrador con acceso dual puede entrar «como cliente»: compra y cancela sus pedidos como un cliente más.
    Solo se acepta si el servidor confirma que ese administrador tiene el acceso dual."""
    profile = get_profile(user)
    return bool(requested) and profile.role == R.ROLE_ADMIN and profile.dual


def user_data(user):
    profile = get_profile(user)
    client = Client.objects.filter(user=user).first()
    return {
        "id": user.id,
        "name": user.get_full_name() or user.username,
        "email": user.email,
        "role": profile.role,
        "dual": bool(profile.dual and profile.role == R.ROLE_ADMIN),
        "clientId": client.id if client else None,
        "client": client.as_dict() if client else None,
        "grantedBy": profile.granted_by.email if profile.granted_by else None,
    }


# ---------- Validaciones compartidas ----------

def clean_email(value):
    email = str(value or "").strip().lower()
    if not re.fullmatch(EMAIL_RE, email) or len(email) > 150:
        raise ValueError("Escribe un correo electrónico válido.")
    return email


def check_password_rules(password):
    if len(password) < 8 or not any(c.isalpha() for c in password) or not any(c.isdigit() for c in password):
        raise ValueError("La contraseña debe tener mínimo 8 caracteres, una letra y un número.")


def email_in_use(email, exclude_id=None):
    users = User.objects.all()
    if exclude_id is not None:
        users = users.exclude(id=exclude_id)
    return users.filter(email__iexact=email).exists() or users.filter(username__iexact=email).exists()


def clean_client_fields(data):
    doc = str(data.get("doc", "")).strip()
    phone = str(data.get("phone", "")).strip()
    if not re.fullmatch(r"[A-Za-z0-9.\-]{5,20}", doc):
        raise ValueError("La cédula o NIT debe tener entre 5 y 20 números.")
    if phone and not re.fullmatch(r"[0-9+\s\-]{7,20}", phone):
        raise ValueError("El teléfono no es válido.")
    return doc, phone


def document_in_use(doc, exclude_user=None):
    clients = Client.objects.filter(document__iexact=doc)
    if exclude_user is not None:
        clients = clients.exclude(user=exclude_user)
    return clients.exists()


# ---------- Autenticación ----------

@ensure_csrf_cookie
@require_http_methods(["GET"])
def csrf_api(request):
    return response({"csrfToken": get_token(request)})


@require_http_methods(["GET"])
def session_api(request):
    if not request.user.is_authenticated:
        return error_response("Debes iniciar sesión.", 401)
    return response({"user": user_data(request.user)})


@require_http_methods(["POST"])
def login_api(request):
    try:
        data = body(request)
        email = str(data.get("email", "")).strip().lower()
        password = data.get("password", "")
        # Límite de intentos por correo: frena adivinar contraseñas ahora que la página es pública.
        fails_key = "login-fails:" + hashlib.sha256(email.encode("utf-8")).hexdigest()
        if cache.get(fails_key, 0) >= LOGIN_MAX_FAILS:
            return error_response("Demasiados intentos fallidos. Espera unos minutos e inténtalo de nuevo.", 429)
        user = User.objects.filter(email__iexact=email).first()
        authenticated = authenticate(request, username=user.username, password=password) if user else None
        if not authenticated:
            cache.add(fails_key, 0, LOGIN_LOCK_SECONDS)
            try:
                cache.incr(fails_key)
            except ValueError:
                pass
            return error_response("Correo o contraseña incorrectos.", 401)
        cache.delete(fails_key)
        login(request, authenticated)
        if not data.get("remember", True):
            request.session.set_expiry(0)  # la sesión termina al cerrar el navegador
        return response({"user": user_data(authenticated)})
    except ValueError as error:
        return error_response(error)


@require_http_methods(["POST"])
def register_api(request):
    """Registro público: solo crea cuentas de Cliente. Los demás roles los crea el Superadministrador."""
    try:
        data = body(request)
        role = R.ROLE_CLIENT
        name = str(data.get("name", "")).strip()
        email = str(data.get("email", "")).strip().lower()
        password = str(data.get("password", ""))
        if role not in ROLES:
            raise ValueError("El rol no es válido.")
        if not name or not email or not password:
            raise ValueError("Todos los campos obligatorios deben completarse.")
        email = clean_email(email)
        check_password_rules(password)
        if len(name) > 150:
            raise ValueError("El nombre es demasiado largo.")
        doc = phone = ""
        if role == R.ROLE_CLIENT:
            doc, phone = clean_client_fields(data)
            if document_in_use(doc):
                return error_response("Ya existe un cliente con esa cédula o NIT.", 409)
        if email_in_use(email):
            return error_response("Ya existe una cuenta con ese correo.", 409)
        with transaction.atomic():
            user = User.objects.create_user(username=email, email=email, password=password, first_name=name)
            CompanyProfile.objects.create(user=user, role=role)
            if role == R.ROLE_CLIENT:
                Client.objects.create(name=name, document=doc, phone=phone, user=user)
        login(request, user)
        return response({"user": user_data(user)}, 201)
    except ValueError as error:
        return error_response(error)
    except (IntegrityError, DataError):
        return error_response("No fue posible crear la cuenta.", 409)


@require_http_methods(["POST"])
def logout_api(request):
    logout(request)
    return response({"message": "Sesión cerrada."})


# ---------- Categorías ----------

@login_required_api
@require_http_methods(["GET"])
def categories_api(request):
    return response({"categories": list(Category.objects.values_list("name", flat=True))})


@roles_required(*CATALOG_ROLES)
@require_http_methods(["POST"])
def category_create_api(request):
    try:
        name = " ".join(str(body(request).get("name", "")).split())
    except ValueError as error:
        return error_response(error)
    if not name or len(name) > 80:
        return error_response("Escribe un nombre de categoría de hasta 80 caracteres.")
    if Category.objects.filter(name__iexact=name).exists():
        return error_response("Esa categoría ya existe.", 409)
    category = Category.objects.create(name=name)
    return response({"category": category.name}, 201)


# ---------- Productos y servicios ----------
# El catálogo es compartido: todos lo ven; solo Administrador y Supervisor lo modifican.

@login_required_api
@require_http_methods(["GET"])
def products_api(request):
    is_client = role_of(request.user) == R.ROLE_CLIENT
    products = Product.objects.filter(active=True) if is_client else Product.objects.all()
    # El cliente no recibe el costo ni el stock mínimo.
    return response({"products": [p.as_dict(show_cost=not is_client) for p in products]})


def clean_image(value):
    """La foto solo puede ser vacía, una imagen en base64 o una ruta interna img/...; cualquier otra cosa se rechaza."""
    if value in (None, ""):
        return None
    value = str(value)
    if len(value) > MAX_IMAGE_CHARS or ".." in value or not IMAGE_RE.fullmatch(value):
        raise ValueError("La imagen no es válida. Sube una foto JPG o PNG.")
    return value


def product_values(data):
    kind = str(data.get("kind", Product.KIND_PRODUCT))
    if kind not in (Product.KIND_PRODUCT, Product.KIND_SERVICE):
        raise ValueError("El tipo debe ser producto o servicio.")
    service = kind == Product.KIND_SERVICE
    name = str(data.get("name", "")).strip()
    sku = str(data.get("sku", "")).strip().upper()
    category = str(data.get("cat", "")).strip()
    description = str(data.get("desc", "")).strip()
    if not name or not sku or not category:
        raise ValueError("Nombre, código y categoría son obligatorios.")
    if not description:
        raise ValueError("La descripción es obligatoria.")
    price = Decimal(str(data.get("price", "")))
    raw_cost = data.get("cost")
    cost = None if (service and raw_cost in (None, "")) else Decimal(str(raw_cost))
    stock = 0 if service else int(data.get("stock"))
    minimum = 0 if service else int(data.get("min"))
    if price < 0 or (cost is not None and cost < 0) or stock < 0 or minimum < 0:
        raise ValueError("Los precios y el stock no pueden ser negativos.")
    return {
        "kind": kind,
        "name": name,
        "sku": sku,
        "category": category,
        "description": description,
        "active": bool(data.get("active", True)),
        "image": clean_image(data.get("image")),
        "icon": str(data.get("icon", "box")),
        "cost": cost,
        "price": price,
        "stock": stock,
        "minimum_stock": minimum,
    }


@roles_required(*CATALOG_ROLES)
@require_http_methods(["POST"])
def product_create_api(request):
    try:
        values = product_values(body(request))
        if Product.objects.filter(sku=values["sku"]).exists():
            return error_response("Ya existe un producto con ese código.", 409)
        with transaction.atomic():
            Category.objects.get_or_create(name=values["category"])
            product = Product.objects.create(owner=request.user, **values)
    except ValueError as error:
        return error_response(error)
    except (InvalidOperation, TypeError, DataError):
        return error_response("Los datos del producto no son válidos.")
    except IntegrityError:
        return error_response("Ya existe un producto con ese código.", 409)
    return response({"product": product.as_dict()}, 201)


@roles_required(*CATALOG_ROLES)
@require_http_methods(["PUT", "PATCH"])
def product_update_api(request, product_id):
    product = Product.objects.filter(id=product_id).first()
    if not product:
        return error_response("Producto no encontrado.", 404)
    try:
        data = product_values(body(request))
        if Product.objects.filter(sku=data["sku"]).exclude(id=product.id).exists():
            return error_response("Ya existe un producto con ese código.", 409)
        with transaction.atomic():
            Category.objects.get_or_create(name=data["category"])
            for field, value in data.items():
                setattr(product, field, value)
            product.save()
    except ValueError as error:
        return error_response(error)
    except (InvalidOperation, TypeError, DataError):
        return error_response("Los datos del producto no son válidos.")
    except IntegrityError:
        return error_response("Ya existe un producto con ese código.", 409)
    return response({"product": product.as_dict()})


@roles_required(*CATALOG_ROLES)
@require_http_methods(["DELETE"])
def product_delete_api(request, product_id):
    product = Product.objects.filter(id=product_id).first()
    if not product:
        return error_response("Producto no encontrado.", 404)
    try:
        product.delete()
    except ProtectedError:
        return error_response("No se puede eliminar: tiene ventas registradas. Márcalo como Inactivo.", 409)
    return response({"message": "Producto eliminado."})


# ---------- Clientes ----------

@roles_required(R.ROLE_ADVISOR, R.ROLE_SUPERVISOR, R.ROLE_ADMIN)
@require_http_methods(["GET"])
def clients_api(request):
    return response({"clients": [c.as_dict() for c in Client.objects.all()]})


@roles_required(R.ROLE_ADVISOR, R.ROLE_SUPERVISOR, R.ROLE_ADMIN)
@require_http_methods(["POST"])
def client_create_api(request):
    try:
        data = body(request)
        name = str(data.get("name", "")).strip()
        if not name or len(name) > 150:
            raise ValueError("Escribe el nombre del cliente.")
        doc, phone = clean_client_fields(data)
        if document_in_use(doc):
            return error_response("Ya existe un cliente con esa cédula o NIT.", 409)
        client = Client.objects.create(name=name, document=doc, phone=phone)
    except ValueError as error:
        return error_response(error)
    return response({"client": client.as_dict()}, 201)


# ---------- Ventas ----------

def visible_sales(user):
    role = role_of(user)
    qs = Sale.objects.prefetch_related("items")
    if RANK[role] >= RANK[R.ROLE_SUPERVISOR]:
        return qs
    if role == R.ROLE_CLIENT:
        return qs.filter(client__user=user)
    # Asesor: sus ventas y los pedidos de la tienda en línea (autoservicio).
    return qs.filter(Q(owner=user) | Q(advisor_role=Sale.ADVISOR_SELF_SERVICE))


@login_required_api
@require_http_methods(["GET"])
def sales_api(request):
    return response({"sales": [s.as_dict() for s in visible_sales(request.user)[:1000]]})


@roles_required(*SALE_ROLES)
@require_http_methods(["POST"])
def sale_create_api(request):
    try:
        data = body(request)
        user = request.user
        role = role_of(user)
        if as_client_mode(user, data.get("as_client")):
            role = R.ROLE_CLIENT   # compra como un cliente más (tienda en línea)
            if not Client.objects.filter(user=user).exists():
                Client.objects.create(name=user.get_full_name() or user.username, document="—", user=user)
        raw_items = data.get("items", [])
        if not isinstance(raw_items, list) or not raw_items:
            raise ValueError("La venta debe incluir al menos un producto.")
        if len(raw_items) > MAX_SALE_LINES:
            raise ValueError("La venta tiene demasiados productos.")
        wanted = {}
        for item in raw_items:
            try:
                pid, qty = int(item["id"]), int(item["quantity"])
            except (KeyError, TypeError, ValueError):
                raise ValueError("Los productos de la venta no son válidos.")
            if qty < 1:
                raise ValueError("La cantidad debe ser mayor a cero.")
            wanted[pid] = wanted.get(pid, 0) + qty
            if wanted[pid] > MAX_LINE_QTY:
                raise ValueError(f"La cantidad máxima por producto es {MAX_LINE_QTY}.")
        payment = str(data.get("payment", "Efectivo"))
        if payment not in PAYMENTS:
            payment = "Efectivo"

        if role == R.ROLE_CLIENT:
            client = Client.objects.filter(user=user).first()
            if not client:
                raise ValueError("Tu cuenta no tiene datos de cliente.")
            # En "Tus datos" de la tienda el cliente puede corregir su nombre, documento y teléfono.
            info, new_values = data.get("customer"), None
            if isinstance(info, dict):
                new_name = " ".join(str(info.get("name", "")).split())
                if not new_name or len(new_name) > 150:
                    raise ValueError("Escribe tu nombre completo o la razón social de tu empresa.")
                new_doc, new_phone = clean_client_fields(info)
                if document_in_use(new_doc, exclude_user=user):
                    raise ValueError("Ese documento ya está registrado con otro cliente. Revisa el número.")
                new_values = (new_name, new_doc, new_phone)  # se guardan junto con la venta
            delivery = data.get("delivery") if isinstance(data.get("delivery"), dict) else {}
            delivery_method = str(delivery.get("method", "")).strip()
            if delivery_method not in DELIVERY_METHODS:
                delivery_method = ""
            delivery_city = str(delivery.get("city", "")).strip()[:80]
            delivery_address = str(delivery.get("address", "")).strip()[:200]
            notes = str(data.get("notes", "")).strip()[:300]
            advisor = {"name": "Tienda en línea", "email": "", "role": Sale.ADVISOR_SELF_SERVICE}
            status = Sale.STATUS_PENDING
        else:
            client = Client.objects.filter(id=data.get("client_id")).first() or Client.objects.filter(name="Público general").first()
            if not client:
                raise ValueError("Selecciona un cliente.")
            new_values = None
            delivery_method = delivery_city = delivery_address = notes = ""
            advisor = {"name": user.get_full_name() or user.username, "email": user.email, "role": role}
            status = Sale.STATUS_DELIVERED

        with transaction.atomic():
            if role == R.ROLE_CLIENT and new_values:
                client.name, client.document, client.phone = new_values
                client.save(update_fields=["name", "document", "phone"])
            lines, subtotal = [], Decimal("0")
            for pid in sorted(wanted):
                product = Product.objects.select_for_update().get(id=pid, active=True)
                qty = wanted[pid]
                if not product.is_service and qty > product.stock:
                    raise ValueError(f"Stock insuficiente para {product.name}.")
                lines.append((product, qty))
                subtotal += product.price * qty
            tax = (subtotal * IVA).quantize(Decimal("0.01"))
            sale = Sale.objects.create(
                owner=user, folio=uuid.uuid4().hex[:20], client=client,
                customer=client.name, customer_doc=client.document, customer_phone=client.phone,
                advisor_name=advisor["name"], advisor_email=advisor["email"], advisor_role=advisor["role"],
                status=status, payment=payment,
                attended_by="" if status == Sale.STATUS_PENDING else advisor["name"],
                delivery_method=delivery_method, delivery_city=delivery_city,
                delivery_address=delivery_address, notes=notes,
                subtotal=subtotal, tax=tax, total=subtotal + tax,
            )
            sale.folio = f"V-{1000 + sale.id}"  # el folio sale del id: nunca se repite
            sale.save(update_fields=["folio"])
            for product, qty in lines:
                SaleItem.objects.create(sale=sale, product=product, name=product.name, sku=product.sku, quantity=qty, unit_price=product.price)
                if not product.is_service:
                    product.stock -= qty
                    product.save(update_fields=["stock", "updated_at"])
    except ValueError as error:
        return error_response(error)
    except (Product.DoesNotExist, KeyError, TypeError, InvalidOperation, DataError):
        return error_response("La venta no es válida o hay productos que ya no están disponibles.")
    sale = Sale.objects.prefetch_related("items").get(id=sale.id)
    return response({"sale": sale.as_dict()}, 201)


EXPORT_ROLES = (R.ROLE_ADMIN, R.ROLE_SUPER, R.ROLE_ADVISOR)   # quienes pueden descargar el reporte en Excel
MAX_EXPORT_ROWS = 20000
XLSX_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"


@roles_required(*EXPORT_ROLES)
@require_http_methods(["GET"])
def sales_export_api(request):
    """
    Reporte de ventas en Excel (.xlsx). Incluye exactamente las ventas que el rol puede ver en el Historial
    (Administrador y Superadministrador: todas; Asesor: las suyas y los pedidos en línea).
    Con ?scope=mine solo las ventas registradas por el propio usuario (modo «Usuario» del Administrador).
    El permiso lo decide el servidor, no la pantalla.
    """
    sales = visible_sales(request.user)
    if request.GET.get("scope") == "mine":
        sales = sales.filter(advisor_email=request.user.email)
    rows = []
    for sale in sales[:MAX_EXPORT_ROWS]:
        rows.append({
            "folio": sale.folio,
            "date": timezone.localtime(sale.created_at).replace(tzinfo=None),
            "customer": sale.customer, "doc": sale.customer_doc, "phone": sale.customer_phone,
            "advisor": sale.advisor_name, "advisor_role": sale.advisor_role, "attended_by": sale.attended_by,
            "status": sale.status, "payment": sale.payment,
            "delivery_method": sale.delivery_method, "city": sale.delivery_city,
            "address": sale.delivery_address, "notes": sale.notes,
            "subtotal": sale.subtotal, "tax": sale.tax, "total": sale.total,
            "items": [{"sku": i.sku, "name": i.name, "qty": i.quantity, "price": i.unit_price} for i in sale.items.all()],
        })
    reply = HttpResponse(sales_report(rows), content_type=XLSX_TYPE)
    reply["Content-Disposition"] = f'attachment; filename="reporte_ventas_{timezone.localtime().strftime("%Y-%m-%d")}.xlsx"'
    reply["Cache-Control"] = "no-store"
    return reply


@login_required_api
@require_http_methods(["POST"])
def sale_status_api(request, folio):
    """Entregar o anular un pedido pendiente. Al anular se devuelve el stock.
    El personal de ventas atiende cualquier pedido; el cliente solo puede cancelar el suyo."""
    role = role_of(request.user)
    try:
        data = body(request)
    except ValueError as error:
        return error_response(error)
    is_client = role == R.ROLE_CLIENT or as_client_mode(request.user, data.get("as_client"))
    if not is_client and role not in ORDER_ROLES:
        return error_response("Tu rol no tiene permiso para realizar esta acción.", 403)
    action = str(data.get("action", ""))
    if action not in ("deliver", "cancel"):
        return error_response("La acción no es válida.")
    if is_client and action != "cancel":
        return error_response("Tu rol no tiene permiso para realizar esta acción.", 403)
    with transaction.atomic():
        sale = Sale.objects.select_for_update().filter(folio=folio).first()
        if not sale or (is_client and sale.client_id is None) or (is_client and sale.client.user_id != request.user.id):
            return error_response("Venta no encontrada.", 404)
        if sale.status != Sale.STATUS_PENDING:
            return error_response("Este pedido ya fue atendido.", 409)
        if action == "deliver":
            sale.status = Sale.STATUS_DELIVERED
        else:
            sale.status = Sale.STATUS_CANCELED
            for item in sale.items.select_related("product"):
                if not item.product.is_service:
                    item.product.stock += item.quantity
                    item.product.save(update_fields=["stock", "updated_at"])
        if not is_client:  # si el cliente cancela su propio pedido, ningún asesor lo atendió
            sale.attended_by = request.user.get_full_name() or request.user.username
        sale.save(update_fields=["status", "attended_by"])
    sale = Sale.objects.prefetch_related("items").get(id=sale.id)
    return response({"sale": sale.as_dict()})


# ---------- Usuarios (Administrador y Superadministrador) ----------

def user_row(user):
    """Un usuario tal como lo muestra la tabla de Administración."""
    profile = get_profile(user)
    return {
        "id": user.id,
        "name": user.get_full_name() or user.username,
        "email": user.email,
        "role": profile.role,
        "dual": bool(profile.dual and profile.role == R.ROLE_ADMIN),
        "grantedBy": profile.granted_by.email if profile.granted_by else None,
        "last": user.last_login.isoformat() if user.last_login else None,
        "joined": user.date_joined.isoformat(),
        "status": "Activo" if user.is_active else "Inactivo",
    }


@roles_required(R.ROLE_ADMIN, R.ROLE_SUPER)
@require_http_methods(["GET"])
def users_api(request):
    users = list(User.objects.select_related("company_profile", "company_profile__granted_by"))
    # Primero el que ingresó más recientemente; quien aún no ha ingresado se ordena por su fecha de creación.
    users.sort(key=lambda u: u.last_login or u.date_joined, reverse=True)
    return response({"users": [user_row(u) for u in users]})


@roles_required(R.ROLE_ADMIN, R.ROLE_SUPER)
@require_http_methods(["POST"])
def user_create_api(request):
    """El Superadministrador (y el Administrador) crean los usuarios desde la ventana «Crear usuario»."""
    try:
        data = body(request)
        name = str(data.get("name", "")).strip()
        email = clean_email(data.get("email"))
        role = str(data.get("role", R.ROLE_ADVISOR)).strip()
        password = str(data.get("password", "") or "")
        if not name or len(name) > 150:
            raise ValueError("Escribe el nombre del usuario.")
        if role not in assignable_roles(role_of(request.user)):
            raise ValueError("No puedes asignar ese rol.")
        check_password_rules(password)
        doc = phone = ""
        if role == R.ROLE_CLIENT:
            doc, phone = clean_client_fields(data)
            if document_in_use(doc):
                return error_response("Ya existe un cliente con esa cédula o NIT.", 409)
        if email_in_use(email):
            return error_response("Ya existe una cuenta con ese correo.", 409)
        with transaction.atomic():
            user = User.objects.create_user(username=email, email=email, password=password, first_name=name)
            CompanyProfile.objects.create(
                user=user, role=role, granted_by=request.user,
                dual=bool(data.get("dual")) and role == R.ROLE_ADMIN,
            )
            if role == R.ROLE_CLIENT:
                Client.objects.create(name=name, document=doc, phone=phone, user=user)
    except ValueError as error:
        return error_response(error)
    except (IntegrityError, DataError):
        return error_response("No fue posible crear el usuario.", 409)
    return response({"user": user_row(user)}, 201)


@roles_required(R.ROLE_ADMIN, R.ROLE_SUPER)
@require_http_methods(["PUT", "PATCH"])
def user_update_api(request, user_id):
    """Cambia rol, acceso dual, nombre, correo o contraseña. Todos los campos son opcionales."""
    target = User.objects.filter(id=user_id).first()
    if not target:
        return error_response("Usuario no encontrado.", 404)
    if not can_modify(request.user, target):
        return error_response("No tienes permiso para modificar a este usuario.", 403)
    try:
        data = body(request)
        profile = get_profile(target)
        name = str(data["name"]).strip() if "name" in data else target.get_full_name()
        email = clean_email(data["email"]) if "email" in data else target.email
        password = str(data.get("password", "") or "")
        role = str(data["role"]).strip() if "role" in data else profile.role
        if not name or len(name) > 150:
            raise ValueError("Escribe el nombre del usuario.")
        if role not in assignable_roles(role_of(request.user)):
            raise ValueError("No puedes asignar ese rol.")
        if password:
            check_password_rules(password)
        if email_in_use(email, exclude_id=target.id):
            return error_response("Ya existe una cuenta con ese correo.", 409)
        with transaction.atomic():
            target.first_name, target.email, target.username = name, email, email
            if password:
                target.set_password(password)
            target.save()
            if role != profile.role:
                profile.role = role
                profile.granted_by = request.user   # quien da el rol queda por encima
            if "dual" in data:
                profile.dual = bool(data["dual"])
            if profile.role != R.ROLE_ADMIN:
                profile.dual = False
            profile.save()
            if profile.role == R.ROLE_CLIENT and not Client.objects.filter(user=target).exists():
                Client.objects.create(name=name, document="—", user=target)
    except ValueError as error:
        return error_response(error)
    except (IntegrityError, DataError):
        return error_response("No fue posible actualizar el usuario.", 409)
    return response({"user": user_row(target)})


@roles_required(R.ROLE_ADMIN, R.ROLE_SUPER)
@require_http_methods(["DELETE"])
def user_delete_api(request, user_id):
    target = User.objects.filter(id=user_id).first()
    if not target:
        return error_response("Usuario no encontrado.", 404)
    if target.id == request.user.id:
        return error_response("No puedes eliminar tu propia cuenta.")
    if not can_modify(request.user, target):
        return error_response("No tienes permiso para eliminar a este usuario.", 403)
    if Product.objects.filter(owner=target).exists():
        return error_response("Este usuario registró productos en el inventario, por eso no se puede eliminar.", 409)
    try:
        target.delete()
    except ProtectedError:
        return error_response("No se puede eliminar este usuario porque tiene información asociada.", 409)
    return response({"message": "Usuario eliminado."})
