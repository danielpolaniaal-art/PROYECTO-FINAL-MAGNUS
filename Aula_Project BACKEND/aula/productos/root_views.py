from django.http import JsonResponse


def api_root(request):
    return JsonResponse({
        "message": "API de Nexo activa.",
        "endpoints": {
            "csrf": "/api/auth/csrf/",
            "login": "/api/auth/login/",
            "products": "/api/products/",
            "sales": "/api/sales/",
        },
    })
