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


def frontend_index(request):
    """Entrega index.html del frontend (misma página, sin cambios)."""
    if not (settings.FRONTEND_DIR / 'index.html').is_file():
        return HttpResponse(
            f'No se encontró el frontend en: {settings.FRONTEND_DIR}. '
            'Revisa la ruta o define la variable NEXO_FRONTEND_DIR.',
            status=500, content_type='text/plain; charset=utf-8',
        )
    return serve(request, 'index.html', document_root=settings.FRONTEND_DIR)


urlpatterns = [
    path('', include('productos.urls')),                 # /api/auth/..., /api/products/..., /api/sales/..., etc.
    path('api/', api_root, name='api_root'),             # comprobación rápida: debe mostrar "API de Nexo activa."
    path('', frontend_index, name='frontend'),           # la página (index.html)
    # app.js, styles.css e img/ del frontend. Esta ruta va al final: solo atiende lo que no es API.
    re_path(r'^(?P<path>.+)$', serve, {'document_root': settings.FRONTEND_DIR}),
]
