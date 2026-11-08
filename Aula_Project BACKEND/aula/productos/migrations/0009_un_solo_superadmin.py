from django.db import migrations

SUPERADMIN = "superadmin@magnussig.com"


def un_solo_superadmin(apps, schema_editor):
    """Solo superadmin@magnussig.com conserva el rol de Superadministrador.

    Cualquier otra cuenta con ese rol pasa a Administrador (el rol más cercano), así no pierde acceso
    ni se borra ningún usuario, venta o dato.
    """
    User = apps.get_model("auth", "User")
    Profile = apps.get_model("productos", "CompanyProfile")
    principal = User.objects.filter(email__iexact=SUPERADMIN).first()
    otros = Profile.objects.filter(role="Superadministrador")
    if principal:
        otros = otros.exclude(user_id=principal.id)
    otros.update(role="Administrador")


class Migration(migrations.Migration):
    dependencies = [("productos", "0008_limpieza")]
    operations = [migrations.RunPython(un_solo_superadmin, migrations.RunPython.noop)]
