from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


class Migration(migrations.Migration):
    dependencies = [
        ("productos", "0002_demo_data"),
    ]

    operations = [
        migrations.CreateModel(
            name="TeamMember",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=120)),
                ("email", models.EmailField(max_length=254)),
                ("role", models.CharField(default="Vendedor", max_length=40)),
                ("status", models.CharField(default="Invitación enviada", max_length=30)),
                ("last_activity", models.CharField(default="Pendiente", max_length=80)),
                ("owner", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="team_members", to=settings.AUTH_USER_MODEL)),
            ],
            options={"ordering": ("name",)},
        ),
        migrations.AddConstraint(
            model_name="teammember",
            constraint=models.UniqueConstraint(fields=("owner", "email"), name="unique_team_email_per_owner"),
        ),
    ]
