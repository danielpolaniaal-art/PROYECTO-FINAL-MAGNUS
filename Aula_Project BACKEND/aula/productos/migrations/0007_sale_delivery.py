from django.db import migrations, models


class Migration(migrations.Migration):
    """Guarda en la venta los datos de entrega y las notas del pedido en línea."""

    dependencies = [
        ('productos', '0006_datos_magnus'),
    ]

    operations = [
        migrations.AddField(
            model_name='sale',
            name='delivery_method',
            field=models.CharField(blank=True, default='', max_length=20),
        ),
        migrations.AddField(
            model_name='sale',
            name='delivery_city',
            field=models.CharField(blank=True, default='', max_length=80),
        ),
        migrations.AddField(
            model_name='sale',
            name='delivery_address',
            field=models.CharField(blank=True, default='', max_length=200),
        ),
        migrations.AddField(
            model_name='sale',
            name='notes',
            field=models.CharField(blank=True, default='', max_length=300),
        ),
    ]
