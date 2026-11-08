from django.contrib.auth.models import User
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.db.models import Q

from productos.models import Sale


class Command(BaseCommand):
    help = (
        "Elimina las ventas que un administrador registró en el antiguo «modo usuario» (como asesor) y "
        "devuelve las unidades al inventario. Sin --confirmar solo MUESTRA lo que se eliminaría."
    )

    def add_arguments(self, parser):
        parser.add_argument("--email", default="ana@novacomercial.mx", help="Correo del usuario (por defecto Ana).")
        parser.add_argument("--confirmar", action="store_true", help="Ejecuta la eliminación (sin esto solo se muestra la lista).")

    def handle(self, *args, **options):
        email = options["email"].strip().lower()
        user = User.objects.filter(email__iexact=email).first()
        if not user:
            raise CommandError(f"No existe el usuario {email}.")
        # Solo ventas registradas por esa persona como asesor. Sus compras como cliente (Autoservicio) NO se tocan.
        sales = list(
            Sale.objects.filter(Q(owner=user) | Q(advisor_email__iexact=email))
            .exclude(advisor_role=Sale.ADVISOR_SELF_SERVICE)
            .prefetch_related("items__product")
            .order_by("created_at")
        )
        if not sales:
            self.stdout.write("No hay ventas registradas por ese usuario como asesor. No se cambió nada.")
            return
        self.stdout.write(f"Ventas registradas por {email} como asesor ({len(sales)}):")
        for s in sales:
            self.stdout.write(f"  {s.folio}  {s.created_at:%Y-%m-%d %H:%M}  {s.customer}  ${s.total}  [{s.status}]")
        if not options["confirmar"]:
            self.stdout.write(self.style.WARNING(
                "\nNo se eliminó nada (modo de revisión). Haz una copia de la base de datos y, si la lista es correcta, "
                "ejecuta de nuevo con --confirmar."
            ))
            return
        with transaction.atomic():
            for s in sales:
                if s.status != Sale.STATUS_CANCELED:   # las anuladas ya devolvieron su stock
                    for item in s.items.all():
                        if not item.product.is_service:
                            item.product.stock += item.quantity
                            item.product.save(update_fields=["stock", "updated_at"])
                s.delete()
        self.stdout.write(self.style.SUCCESS(f"Listo: se eliminaron {len(sales)} ventas y se devolvió el stock al inventario."))
