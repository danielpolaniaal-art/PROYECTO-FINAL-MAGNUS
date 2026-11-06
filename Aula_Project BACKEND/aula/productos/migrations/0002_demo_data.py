from django.db import migrations
from django.contrib.auth.hashers import make_password


def create_demo_data(apps, schema_editor):
    User = apps.get_model("auth", "User")
    Profile = apps.get_model("productos", "CompanyProfile")
    Product = apps.get_model("productos", "Product")
    user, created = User.objects.get_or_create(username="ana@novacomercial.mx", defaults={"email": "ana@novacomercial.mx", "first_name": "Ana Martínez"})
    if created:
        user.password = make_password("Nexo2026Demo")
        user.save(update_fields=["password"])
    Profile.objects.get_or_create(user=user, defaults={"company": "Nova Comercial"})
    products = [
        ("Mouse inalámbrico M240", "ELE-001", "Accesorios", 25, 48, 10, "mouse"),
        ("Teclado compacto K380", "ELE-002", "Accesorios", 39, 32, 10, "keyboard"),
        ("Monitor LED 24 pulgadas", "ELE-003", "Pantallas", 79, 6, 10, "monitor"),
        ("Audífonos Bluetooth H600", "ELE-004", "Audio", 59, 0, 10, "headphones"),
        ("Cable USB-C 1 metro", "ELE-005", "Cables", 18, 18, 10, "cable"),
        ("Webcam Full HD C920", "ELE-006", "Accesorios", 45, 24, 10, "webcam"),
    ]
    for name, sku, category, price, stock, minimum, icon in products:
        Product.objects.get_or_create(
            owner=user, sku=sku,
            defaults={"name": name, "category": category, "cost": price * 0.6, "price": price, "stock": stock, "minimum_stock": minimum, "icon": icon},
        )


class Migration(migrations.Migration):
    dependencies = [("productos", "0001_initial")]
    operations = [migrations.RunPython(create_demo_data, migrations.RunPython.noop)]
