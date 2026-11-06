import json

from django.conf import settings
from django.contrib.auth.models import User
from django.core.cache import cache
from django.test import Client as HttpTestClient
from django.test import TestCase

from .models import Category, Client, CompanyProfile, Product, Sale
from .views import LOGIN_MAX_FAILS

R = CompanyProfile


def crear_usuario(email, rol, granted_by=None):
    user = User.objects.create_user(username=email, email=email, password="Password123", first_name=email.split("@")[0])
    CompanyProfile.objects.create(user=user, role=rol, granted_by=granted_by)
    if rol == R.ROLE_CLIENT:
        Client.objects.create(name=user.first_name, document="12345678", user=user)
    return user


class ApiBaseTest(TestCase):
    def setUp(self):
        self.superadmin = crear_usuario("super@example.com", R.ROLE_SUPER)
        self.admin = crear_usuario("admin@example.com", R.ROLE_ADMIN)
        self.supervisor = crear_usuario("sup@example.com", R.ROLE_SUPERVISOR)
        self.asesor = crear_usuario("asesor@example.com", R.ROLE_ADVISOR)
        self.cliente = crear_usuario("cliente@example.com", R.ROLE_CLIENT)
        self.product = Product.objects.create(
            owner=self.admin, name="Extintor", sku="TEST-001", category="Extintores",
            description="Extintor de prueba", cost=10000, price=20000, stock=5, minimum_stock=1,
        )
        self.service = Product.objects.create(
            owner=self.admin, kind="service", name="Auditoría", sku="SER-T1", category="Auditorías",
            description="Servicio de prueba", price=500000,
        )

    def send(self, method, url, data=None):
        return getattr(self.client, method)(url, data=json.dumps(data or {}), content_type="application/json")

    def payload(self, **changes):
        data = {"kind": "product", "name": "Nuevo", "sku": "nue-001", "cat": "Camillas", "desc": "Descripción", "cost": 5, "price": 9.5, "stock": 3, "min": 1}
        data.update(changes)
        return data


class ProductTests(ApiBaseTest):
    def test_admin_creates_edits_and_deletes_products(self):
        self.client.force_login(self.admin)
        created = self.send("post", "/api/products/create/", self.payload())
        self.assertEqual(created.status_code, 201)
        pid = created.json()["product"]["id"]
        self.assertTrue(Category.objects.filter(name="Camillas").exists())
        self.assertEqual(self.send("put", f"/api/products/{pid}/", self.payload(name="Editado")).status_code, 200)
        self.assertEqual(self.send("delete", f"/api/products/{pid}/delete/").status_code, 200)

    def test_description_is_required(self):
        self.client.force_login(self.admin)
        self.assertEqual(self.send("post", "/api/products/create/", self.payload(desc="   ")).status_code, 400)
        self.assertFalse(Product.objects.filter(sku="NUE-001").exists())

    def test_service_needs_no_stock_or_cost(self):
        self.client.force_login(self.supervisor)
        r = self.send("post", "/api/products/create/", {"kind": "service", "name": "S", "sku": "s-9", "cat": "Auditorías", "desc": "x", "price": 100})
        self.assertEqual(r.status_code, 201)
        self.assertIsNone(r.json()["product"]["cost"])

    def test_only_admin_and_supervisor_change_catalog(self):
        for user in (self.asesor, self.cliente, self.superadmin):
            self.client.force_login(user)
            self.assertEqual(self.send("post", "/api/products/create/", self.payload()).status_code, 403)
            self.assertEqual(self.send("delete", f"/api/products/{self.product.id}/delete/").status_code, 403)

    def test_client_does_not_receive_cost(self):
        self.client.force_login(self.cliente)
        rows = self.client.get("/api/products/").json()["products"]
        self.assertTrue(all(p["cost"] is None for p in rows))
        self.client.force_login(self.admin)
        mine = [p for p in self.client.get("/api/products/").json()["products"] if p["sku"] == "TEST-001"][0]
        self.assertEqual(mine["cost"], 10000)

    def test_product_with_sales_cannot_be_deleted(self):
        self.client.force_login(self.asesor)
        self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 1}]})
        self.client.force_login(self.admin)
        self.assertEqual(self.send("delete", f"/api/products/{self.product.id}/delete/").status_code, 409)


class SaleTests(ApiBaseTest):
    def test_advisor_sale_updates_stock_and_has_19_percent_iva(self):
        Client.objects.create(name="Público general", document="—")
        self.client.force_login(self.asesor)
        r = self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 2}, {"id": self.service.id, "quantity": 1}], "payment": "Tarjeta"})
        self.assertEqual(r.status_code, 201)
        sale = r.json()["sale"]
        self.assertEqual(sale["status"], "Entregado")
        self.assertEqual(sale["subtotal"], 540000)
        self.assertEqual(sale["iva"], 102600)
        self.assertEqual(sale["advisor"]["role"], "Asesor de ventas")
        self.assertEqual(sale["items"][0]["name"] in ("Extintor", "Auditoría"), True)
        self.product.refresh_from_db(); self.service.refresh_from_db()
        self.assertEqual(self.product.stock, 3)
        self.assertEqual(self.service.stock, 0)

    def test_client_order_is_pending_and_visible_to_advisor(self):
        self.client.force_login(self.cliente)
        r = self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 1}]})
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.json()["sale"]["status"], "Pendiente")
        self.assertEqual(r.json()["sale"]["advisor"]["role"], "Autoservicio")
        self.client.force_login(self.asesor)
        folios = [s["folio"] for s in self.client.get("/api/sales/").json()["sales"]]
        self.assertIn(r.json()["sale"]["folio"], folios)

    def test_client_only_sees_own_sales(self):
        otro = crear_usuario("otro@example.com", R.ROLE_CLIENT)
        self.client.force_login(otro)
        self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 1}]})
        self.client.force_login(self.cliente)
        self.assertEqual(self.client.get("/api/sales/").json()["sales"], [])

    def test_cancel_pending_order_restores_stock(self):
        self.client.force_login(self.cliente)
        folio = self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 2}]}).json()["sale"]["folio"]
        self.product.refresh_from_db(); self.assertEqual(self.product.stock, 3)
        # el cliente no puede marcar como entregado, solo cancelar su propio pedido
        self.assertEqual(self.send("post", f"/api/sales/{folio}/status/", {"action": "deliver"}).status_code, 403)
        self.client.force_login(self.asesor)
        self.assertEqual(self.send("post", f"/api/sales/{folio}/status/", {"action": "cancel"}).status_code, 200)
        self.product.refresh_from_db(); self.assertEqual(self.product.stock, 5)
        self.assertEqual(Sale.objects.get(folio=folio).attended_by, "asesor")

    def test_client_can_cancel_only_own_pending_order(self):
        self.client.force_login(self.cliente)
        folio = self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 2}]}).json()["sale"]["folio"]
        otro = crear_usuario("otro2@example.com", R.ROLE_CLIENT)
        self.client.force_login(otro)
        self.assertEqual(self.send("post", f"/api/sales/{folio}/status/", {"action": "cancel"}).status_code, 404)
        self.client.force_login(self.cliente)
        r = self.send("post", f"/api/sales/{folio}/status/", {"action": "cancel"})
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json()["sale"]["status"], "Anulada")
        self.assertEqual(r.json()["sale"]["attendedBy"], "")
        self.product.refresh_from_db(); self.assertEqual(self.product.stock, 5)
        self.assertEqual(self.send("post", f"/api/sales/{folio}/status/", {"action": "cancel"}).status_code, 409)

    def test_online_order_saves_delivery_notes_and_customer_data(self):
        self.client.force_login(self.cliente)
        r = self.send("post", "/api/sales/create/", {
            "items": [{"id": self.product.id, "quantity": 1}], "payment": "Nequi / Daviplata",
            "delivery": {"method": "ship", "city": "Neiva", "address": "Cra 7 # 12-34"},
            "notes": "Entregar en la tarde",
            "customer": {"name": "Mi Empresa S.A.S", "doc": "900123456-1", "phone": "310 456 7821"},
        })
        self.assertEqual(r.status_code, 201)
        sale = r.json()["sale"]
        self.assertEqual(sale["delivery"], {"method": "ship", "city": "Neiva", "address": "Cra 7 # 12-34"})
        self.assertEqual(sale["notes"], "Entregar en la tarde")
        self.assertEqual(sale["client"]["name"], "Mi Empresa S.A.S")
        self.assertEqual(Client.objects.get(user=self.cliente).document, "900123456-1")

    def test_online_order_rejects_document_of_another_client(self):
        crear_usuario("otro3@example.com", R.ROLE_CLIENT)
        Client.objects.filter(user__email="otro3@example.com").update(document="99887766")
        self.client.force_login(self.cliente)
        r = self.send("post", "/api/sales/create/", {
            "items": [{"id": self.product.id, "quantity": 1}],
            "customer": {"name": "Cliente", "doc": "99887766", "phone": "310 456 7821"},
        })
        self.assertEqual(r.status_code, 400)
        self.product.refresh_from_db(); self.assertEqual(self.product.stock, 5)

    def test_deliver_order_and_not_twice(self):
        self.client.force_login(self.cliente)
        folio = self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 1}]}).json()["sale"]["folio"]
        self.client.force_login(self.supervisor)
        self.assertEqual(self.send("post", f"/api/sales/{folio}/status/", {"action": "deliver"}).status_code, 200)
        self.assertEqual(self.send("post", f"/api/sales/{folio}/status/", {"action": "deliver"}).status_code, 409)

    def test_insufficient_stock_is_rejected(self):
        self.client.force_login(self.cliente)
        self.assertEqual(self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 99}]}).status_code, 400)

    def test_superadmin_cannot_sell(self):
        self.client.force_login(self.superadmin)
        self.assertEqual(self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 1}]}).status_code, 403)


class AuthTests(ApiBaseTest):
    def test_register_client_creates_client_record(self):
        r = self.send("post", "/api/auth/register/", {"role": "Cliente", "name": "Persona Nueva", "email": "nueva@example.com", "password": "Password123", "doc": "98765432", "phone": "3101234567"})
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.json()["user"]["role"], "Cliente")
        self.assertTrue(Client.objects.filter(user__email="nueva@example.com", document="98765432").exists())

    def test_public_register_cannot_create_privileged_roles(self):
        """El registro público siempre crea un Cliente, aunque el JSON pida otro rol y traiga un código."""
        r = self.send("post", "/api/auth/register/", {"role": "Administrador", "code": "ADM-2026", "name": "X Admin", "email": "x@example.com", "password": "Password123", "doc": "55544433"})
        self.assertEqual(r.status_code, 201)
        self.assertEqual(User.objects.get(email="x@example.com").company_profile.role, "Cliente")
        self.assertEqual(r.json()["user"]["role"], "Cliente")

    def test_duplicate_document_is_rejected(self):
        r = self.send("post", "/api/auth/register/", {"role": "Cliente", "name": "Otra", "email": "o@example.com", "password": "Password123", "doc": "12345678"})
        self.assertEqual(r.status_code, 409)

    def test_login_returns_role_and_dual(self):
        self.admin.company_profile.dual = True
        self.admin.company_profile.save()
        r = self.send("post", "/api/auth/login/", {"email": "admin@example.com", "password": "Password123"})
        self.assertEqual(r.json()["user"]["role"], "Administrador")
        self.assertTrue(r.json()["user"]["dual"])

    def test_password_is_stored_hashed_in_database(self):
        r = self.send("post", "/api/auth/register/", {"name": "Cliente Nuevo", "email": "an@example.com", "password": "Password123", "doc": "44433322"})
        self.assertEqual(r.status_code, 201)
        user = User.objects.get(email="an@example.com")
        self.assertNotEqual(user.password, "Password123")
        self.assertTrue(user.check_password("Password123"))


class UserManagementTests(ApiBaseTest):
    def test_admin_creates_user_without_company(self):
        self.client.force_login(self.admin)
        r = self.send("post", "/api/users/create/", {"name": "Nueva Asesora", "email": "na@example.com", "role": "Asesor de ventas", "password": "Password123"})
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.json()["user"]["grantedBy"], "admin@example.com")

    def test_admin_can_give_dual_access(self):
        self.client.force_login(self.admin)
        r = self.send("post", "/api/users/create/", {"name": "Otro Admin", "email": "oa@example.com", "role": "Administrador", "password": "Password123", "dual": True})
        self.assertTrue(r.json()["user"]["dual"])

    def test_superadmin_cannot_create_users(self):
        self.client.force_login(self.superadmin)
        self.assertEqual(self.send("post", "/api/users/create/", {"name": "N", "email": "n@example.com", "role": "Cliente", "password": "Password123", "doc": "11111111"}).status_code, 403)

    def test_nobody_can_touch_the_superadmin(self):
        self.client.force_login(self.admin)
        self.assertEqual(self.send("put", f"/api/users/{self.superadmin.id}/", {"role": "Cliente"}).status_code, 403)
        self.assertEqual(self.send("delete", f"/api/users/{self.superadmin.id}/delete/").status_code, 403)
        otro = crear_usuario("super2@example.com", R.ROLE_SUPER)
        self.client.force_login(otro)
        self.assertEqual(self.send("put", f"/api/users/{self.superadmin.id}/", {"role": "Cliente"}).status_code, 403)
        self.assertEqual(self.superadmin.company_profile.role, R.ROLE_SUPER)

    def test_admin_cannot_assign_superadmin(self):
        self.client.force_login(self.admin)
        self.assertEqual(self.send("put", f"/api/users/{self.asesor.id}/", {"role": "Superadministrador"}).status_code, 400)

    def test_promoted_admin_cannot_remove_the_admin_who_promoted_them(self):
        self.client.force_login(self.admin)
        self.assertEqual(self.send("put", f"/api/users/{self.asesor.id}/", {"role": "Administrador"}).status_code, 200)
        self.client.force_login(self.asesor)
        self.assertEqual(self.send("put", f"/api/users/{self.admin.id}/", {"role": "Cliente"}).status_code, 403)
        self.assertEqual(self.send("delete", f"/api/users/{self.admin.id}/delete/").status_code, 403)
        self.admin.company_profile.refresh_from_db()
        self.assertEqual(self.admin.company_profile.role, R.ROLE_ADMIN)
        # pero el que dio el rol sí puede modificarlo
        self.client.force_login(self.admin)
        self.assertEqual(self.send("put", f"/api/users/{self.asesor.id}/", {"role": "Supervisor"}).status_code, 200)

    def test_superadmin_can_change_admin_role(self):
        self.client.force_login(self.superadmin)
        r = self.send("put", f"/api/users/{self.admin.id}/", {"role": "Supervisor"})
        self.assertEqual(r.status_code, 200)

    def test_cannot_modify_or_delete_yourself(self):
        self.client.force_login(self.admin)
        self.assertEqual(self.send("put", f"/api/users/{self.admin.id}/", {"role": "Cliente"}).status_code, 403)
        self.assertEqual(self.send("delete", f"/api/users/{self.admin.id}/delete/").status_code, 400)

    def test_deleting_a_user_keeps_their_sales(self):
        self.client.force_login(self.cliente)
        self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 1}]})
        self.client.force_login(self.admin)
        self.assertEqual(self.send("delete", f"/api/users/{self.cliente.id}/delete/").status_code, 200)
        self.assertEqual(Sale.objects.count(), 1)

    def test_non_admin_cannot_manage_users(self):
        for user in (self.supervisor, self.asesor, self.cliente):
            self.client.force_login(user)
            self.assertEqual(self.client.get("/api/users/").status_code, 403)


class ClientCategoryTests(ApiBaseTest):
    def test_advisor_creates_client_and_duplicates_are_rejected(self):
        self.client.force_login(self.asesor)
        ok = self.send("post", "/api/clients/create/", {"name": "Empresa X", "doc": "900111222-1", "phone": "3105551234"})
        self.assertEqual(ok.status_code, 201)
        dup = self.send("post", "/api/clients/create/", {"name": "Otra", "doc": "900111222-1"})
        self.assertEqual(dup.status_code, 409)

    def test_client_role_cannot_list_clients(self):
        self.client.force_login(self.cliente)
        self.assertEqual(self.client.get("/api/clients/").status_code, 403)

    def test_supervisor_creates_category(self):
        self.client.force_login(self.supervisor)
        self.assertEqual(self.send("post", "/api/categories/create/", {"name": "Señalización"}).status_code, 201)
        self.assertEqual(self.send("post", "/api/categories/create/", {"name": "señalización"}).status_code, 409)
        self.assertIn("Señalización", self.client.get("/api/categories/").json()["categories"])


class PurchasesPerUserTests(ApiBaseTest):
    """Cada compra queda asociada al usuario que la hizo (columna productos_sale.owner_id) y a su cliente."""

    def test_each_client_purchase_is_linked_to_the_user_who_made_it(self):
        otro = crear_usuario("otro@example.com", R.ROLE_CLIENT)
        self.client.force_login(self.cliente)
        a = self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 1}]})
        self.client.force_login(otro)
        b = self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 2}]})
        self.assertEqual((a.status_code, b.status_code), (201, 201))
        sale_a = Sale.objects.get(folio=a.json()["sale"]["folio"])
        sale_b = Sale.objects.get(folio=b.json()["sale"]["folio"])
        self.assertEqual(sale_a.owner_id, self.cliente.id)
        self.assertEqual(sale_a.client.user_id, self.cliente.id)
        self.assertEqual(sale_b.owner_id, otro.id)
        self.assertEqual(sale_b.client.user_id, otro.id)
        self.product.refresh_from_db()
        self.assertEqual(self.product.stock, 2)  # 5 - 1 - 2
        # Cada cliente solo ve lo suyo.
        self.client.force_login(self.cliente)
        self.assertEqual([x["folio"] for x in self.client.get("/api/sales/").json()["sales"]], [sale_a.folio])

    def test_client_cannot_choose_another_owner_in_the_request(self):
        otro = crear_usuario("otro@example.com", R.ROLE_CLIENT)
        otro_cliente = Client.objects.get(user=otro)
        self.client.force_login(self.cliente)
        r = self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 1}], "client_id": otro_cliente.id, "owner": otro.id})
        self.assertEqual(r.status_code, 201)
        sale = Sale.objects.get(folio=r.json()["sale"]["folio"])
        self.assertEqual(sale.owner_id, self.cliente.id)
        self.assertEqual(sale.client.user_id, self.cliente.id)

    def test_anonymous_cannot_buy(self):
        r = self.send("post", "/api/sales/create/", {"items": [{"id": self.product.id, "quantity": 1}]})
        self.assertEqual(r.status_code, 401)
        self.assertEqual(Sale.objects.count(), 0)

    def test_sale_rejects_absurd_quantities_and_malformed_items(self):
        self.client.force_login(self.cliente)
        for items in ([{"id": self.service.id, "quantity": 1001}], "no-es-una-lista", [{"id": "abc", "quantity": 1}], [{"quantity": 1}]):
            r = self.send("post", "/api/sales/create/", {"items": items})
            self.assertEqual(r.status_code, 400, items)
        self.assertEqual(Sale.objects.count(), 0)


class SecurityTests(ApiBaseTest):
    def setUp(self):
        super().setUp()
        cache.clear()

    def tearDown(self):
        cache.clear()

    def test_login_is_blocked_after_too_many_failures(self):
        for _ in range(LOGIN_MAX_FAILS):
            r = self.send("post", "/api/auth/login/", {"email": "admin@example.com", "password": "incorrecta"})
            self.assertEqual(r.status_code, 401)
        r = self.send("post", "/api/auth/login/", {"email": "admin@example.com", "password": "Password123"})
        self.assertEqual(r.status_code, 429)

    def test_product_image_must_be_a_real_image(self):
        self.client.force_login(self.admin)
        for bad in ('x" onerror="alert(1)', "javascript:alert(1)", "https://sitio.malo/x.png"):
            self.assertEqual(self.send("post", "/api/products/create/", self.payload(image=bad)).status_code, 400, bad)
        ok = self.send("post", "/api/products/create/", self.payload(image="data:image/jpeg;base64,AAAA"))
        self.assertEqual(ok.status_code, 201)


class NgrokTests(ApiBaseTest):
    """Simula las peticiones que llegan por ngrok: dominio público, HTTPS y origen distinto de localhost."""
    host = settings.NGROK_DOMAIN or "demo.ngrok-free.app"

    def test_page_and_api_are_served_from_the_ngrok_host(self):
        page = self.client.get("/", HTTP_HOST=self.host, secure=True)
        self.assertEqual(page.status_code, 200)
        self.assertIn(b"app.js", b"".join(page.streaming_content))
        api = self.client.get("/api/", HTTP_HOST=self.host, secure=True)
        self.assertEqual(api.status_code, 200)
        self.assertIn("API de Nexo activa.", api.json()["message"])

    def test_unknown_host_is_rejected(self):
        self.assertEqual(self.client.get("/api/", HTTP_HOST="sitio-malo.example.com").status_code, 400)

    def test_login_needs_csrf_token_and_works_with_it_from_ngrok_origin(self):
        creds = json.dumps({"email": "admin@example.com", "password": "Password123"})
        sin_token = HttpTestClient(enforce_csrf_checks=True)
        r = sin_token.post("/api/auth/login/", data=creds, content_type="application/json", HTTP_HOST=self.host, HTTP_ORIGIN=f"https://{self.host}", secure=True)
        self.assertEqual(r.status_code, 403)
        con_token = HttpTestClient(enforce_csrf_checks=True)
        token = con_token.get("/api/auth/csrf/", HTTP_HOST=self.host, secure=True).json()["csrfToken"]
        r = con_token.post("/api/auth/login/", data=creds, content_type="application/json", HTTP_HOST=self.host, HTTP_ORIGIN=f"https://{self.host}", HTTP_X_CSRFTOKEN=token, secure=True)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json()["user"]["email"], "admin@example.com")
