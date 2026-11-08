"""
URL configuration for aula project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.conf import settings
from django.http import HttpResponse
from django.urls import include, path, re_path
from django.views.static import serve

from productos.root_views import api_root


def frontend_file(request, path):
    """
    Entrega los archivos del frontend (app.js, styles.css, img/...). Con "no-cache" el navegador pregunta cada vez
    si el archivo cambió: así, cuando se actualiza la página, todos los visitantes reciben la versión nueva
    (si no, podían seguir viendo un app.js viejo guardado en su navegador).
    """
    response = serve(request, path, document_root=settings.FRONTEND_DIR)
    response["Cache-Control"] = "no-cache"
    return response


def frontend_index(request):
    """Entrega index.html del frontend (misma página, sin cambios)."""
    if not (settings.FRONTEND_DIR / 'index.html').is_file():
        return HttpResponse(
            f'No se encontró el frontend en: {settings.FRONTEND_DIR}. '
            'Revisa la ruta o define la variable NEXO_FRONTEND_DIR.',
            status=500, content_type='text/plain; charset=utf-8',
        )
    return frontend_file(request, 'index.html')


urlpatterns = [
    path('', include('productos.urls')),                 # /api/auth/..., /api/products/..., /api/sales/..., etc.
    path('api/', api_root, name='api_root'),             # comprobación rápida: debe mostrar "API de Nexo activa."
    path('', frontend_index, name='frontend'),           # la página (index.html)
    # app.js, styles.css e img/ del frontend. Esta ruta va al final: solo atiende lo que no es API.
    re_path(r'^(?P<path>.+)$', frontend_file),
]
