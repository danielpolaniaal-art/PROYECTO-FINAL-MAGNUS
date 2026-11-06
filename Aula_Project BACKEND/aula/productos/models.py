from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models


class CompanyProfile(models.Model):
    """Perfil de cada usuario: su rol, si puede entrar también como usuario y quién le dio el rol."""

    ROLE_SUPER = "Superadministrador"
    ROLE_ADMIN = "Administrador"
    ROLE_SUPERVISOR = "Supervisor"
    ROLE_ADVISOR = "Asesor de ventas"
    ROLE_CLIENT = "Cliente"
    ROLE_CHOICES = (
        (ROLE_SUPER, ROLE_SUPER),
        (ROLE_ADMIN, ROLE_ADMIN),
        (ROLE_SUPERVISOR, ROLE_SUPERVISOR),
        (ROLE_ADVISOR, ROLE_ADVISOR),
        (ROLE_CLIENT, ROLE_CLIENT),
    )

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="company_profile")
    # El nombre de la empresa ya no se pide al crear usuarios; el campo queda con un valor fijo.
    company = models.CharField(max_length=120, blank=True, default="Magnus SIG S.A.S")
    role = models.CharField(max_length=30, choices=ROLE_CHOICES, default=ROLE_ADVISOR)
    # Solo el Administrador puede tener acceso también como usuario (modo "Usuario").
    dual = models.BooleanField(default=False)
    # Quién le asignó el rol. Quien recibe un rol no puede quitárselo a quien se lo dio.
    granted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="granted_profiles"
    )

    def __str__(self):
        return f"{self.user.get_full_name()} ({self.role})"


class Client(models.Model):
    """Cliente al que se le vende. Puede tener o no una cuenta de usuario."""

    name = models.CharField(max_length=150)
    document = models.CharField(max_length=40, default="—")
    phone = models.CharField(max_length=40, blank=True, default="")
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="client_record"
    )

    class Meta:
        ordering = ("id",)

    def __str__(self):
        return f"{self.name} ({self.document})"

    def as_dict(self):
        return {"id": self.id, "name": self.name, "doc": self.document, "phone": self.phone}


class Category(models.Model):
    name = models.CharField(max_length=80, unique=True)

    class Meta:
        ordering = ("name",)

    def __str__(self):
        return self.name


class Product(models.Model):
    KIND_PRODUCT = "product"
    KIND_SERVICE = "service"
    KIND_CHOICES = ((KIND_PRODUCT, "Producto"), (KIND_SERVICE, "Servicio"))

    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="products")
    kind = models.CharField(max_length=10, choices=KIND_CHOICES, default=KIND_PRODUCT)
    name = models.CharField(max_length=120)
    sku = models.CharField(max_length=40)
    category = models.CharField(max_length=80)
    description = models.TextField(blank=True)
    # Los servicios pueden no tener costo; por eso acepta nulo.
    cost = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, validators=[MinValueValidator(0)])
    price = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(0)])
    stock = models.PositiveIntegerField(default=0)
    minimum_stock = models.PositiveIntegerField(default=0)
    active = models.BooleanField(default=True)
    image = models.TextField(blank=True, null=True)
    icon = models.CharField(max_length=40, default="box")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=("owner", "sku"), name="unique_product_sku_per_owner"),
        ]
        ordering = ("name",)

    def __str__(self):
        return f"{self.name} ({self.sku})"

    @property
    def is_service(self):
        return self.kind == self.KIND_SERVICE

    def as_dict(self, show_cost=True):
        return {
            "id": self.id,
            "kind": self.kind,
            "name": self.name,
            "sku": self.sku,
            "cat": self.category,
            "desc": self.description,
            "cost": float(self.cost) if (show_cost and self.cost is not None) else None,
            "price": float(self.price),
            "stock": self.stock,
            "min": self.minimum_stock if show_cost else 0,
            "active": self.active,
            "image": self.image,
            "icon": self.icon,
        }


class Sale(models.Model):
    STATUS_PENDING = "Pendiente"
    STATUS_DELIVERED = "Entregado"
    STATUS_CANCELED = "Anulada"
    STATUS_CHOICES = (
        (STATUS_PENDING, STATUS_PENDING),
        (STATUS_DELIVERED, STATUS_DELIVERED),
        (STATUS_CANCELED, STATUS_CANCELED),
    )
    ADVISOR_SELF_SERVICE = "Autoservicio"

    # Quién registró la venta. Si ese usuario se elimina, la venta se conserva (con los datos copiados abajo).
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="sales")
    folio = models.CharField(max_length=30)
    client = models.ForeignKey(Client, null=True, blank=True, on_delete=models.SET_NULL, related_name="sales")
    # Datos del cliente y del asesor copiados al momento de la venta (historial fiel).
    customer = models.CharField(max_length=150, default="Público general")
    customer_doc = models.CharField(max_length=40, blank=True, default="")
    customer_phone = models.CharField(max_length=40, blank=True, default="")
    advisor_name = models.CharField(max_length=150, blank=True, default="")
    advisor_email = models.CharField(max_length=150, blank=True, default="")
    advisor_role = models.CharField(max_length=30, blank=True, default="")
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default=STATUS_DELIVERED)
    payment = models.CharField(max_length=40, default="Efectivo")
    attended_by = models.CharField(max_length=150, blank=True, default="")
    # Entrega del pedido en línea (la pide el paso "Entrega y pago" de la tienda).
    delivery_method = models.CharField(max_length=20, blank=True, default="")
    delivery_city = models.CharField(max_length=80, blank=True, default="")
    delivery_address = models.CharField(max_length=200, blank=True, default="")
    notes = models.CharField(max_length=300, blank=True, default="")
    subtotal = models.DecimalField(max_digits=14, decimal_places=2)
    tax = models.DecimalField(max_digits=14, decimal_places=2)
    total = models.DecimalField(max_digits=14, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-created_at", "-id")
        constraints = [
            models.UniqueConstraint(fields=("owner", "folio"), name="unique_sale_folio_per_owner"),
        ]

    def as_dict(self):
        return {
            "folio": self.folio,
            "date": self.created_at.isoformat(),
            "client": {"id": self.client_id, "name": self.customer, "doc": self.customer_doc, "phone": self.customer_phone},
            "advisor": {"name": self.advisor_name, "email": self.advisor_email, "role": self.advisor_role},
            "status": self.status,
            "items": [
                {"id": i.product_id, "name": i.name, "sku": i.sku, "qty": i.quantity, "price": float(i.unit_price)}
                for i in self.items.all()
            ],
            "subtotal": float(self.subtotal),
            "iva": float(self.tax),
            "total": float(self.total),
            "pay": self.payment,
            "attendedBy": self.attended_by,
            "delivery": (
                {"method": self.delivery_method, "city": self.delivery_city, "address": self.delivery_address}
                if self.delivery_method else None
            ),
            "notes": self.notes,
        }


class SaleItem(models.Model):
    sale = models.ForeignKey(Sale, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name="sale_items")
    # Nombre y código copiados al vender: el historial no cambia si luego se edita el producto.
    name = models.CharField(max_length=120, blank=True, default="")
    sku = models.CharField(max_length=40, blank=True, default="")
    quantity = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
