from django.db import migrations


def quitar_productos(apps, schema_editor):
    """Retira de la tienda 'anillo' y 'televisor 4K' para que no vuelvan a aparecer."""
    Product = apps.get_model("productos", "Product")
    SaleItem = apps.get_model("productos", "SaleItem")
    for p in Product.objects.all():
        n = (p.name or "").lower()
        if "anillo" in n or ("televisor" in n and "4k" in n):
            if SaleItem.objects.filter(product_id=p.id).exists():
                p.active = False          # tiene ventas: se conserva el historial pero no se muestra
                p.stock = 0
                p.save(update_fields=["active", "stock"])
            else:
                p.delete()


class Migration(migrations.Migration):
    """Elimina la tabla productos_teammember (no se usa) y los productos que ya no se venden."""

    dependencies = [("productos", "0007_sale_delivery")]
    operations = [
        migrations.RunPython(quitar_productos, migrations.RunPython.noop),
        migrations.DeleteModel(name="TeamMember"),
    ]
