from django.db import migrations, models

# Administrador inicial: es el usuario de demostración que ya crea la migración 0002
# (el mismo que aparece escrito en la pantalla de inicio de sesión).
ADMIN_INICIAL = "ana@novacomercial.mx"


def marcar_admin_inicial(apps, schema_editor):
    User = apps.get_model("auth", "User")
    Profile = apps.get_model("productos", "CompanyProfile")
    user = User.objects.filter(username=ADMIN_INICIAL).first()
    if user:
        Profile.objects.filter(user_id=user.id).update(role="Administrador")


class Migration(migrations.Migration):
    dependencies = [("productos", "0003_teammember")]
    operations = [
        migrations.AddField(
            model_name="companyprofile",
            name="role",
            field=models.CharField(
                choices=[("Administrador", "Administrador"), ("Usuario", "Usuario")],
                default="Usuario",
                max_length=20,
            ),
        ),
        migrations.RunPython(marcar_admin_inicial, migrations.RunPython.noop),
    ]
