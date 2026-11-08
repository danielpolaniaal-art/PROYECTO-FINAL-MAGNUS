from django.urls import path

from . import views

urlpatterns = [
    path("api/auth/csrf/", views.csrf_api, name="api_csrf"),
    path("api/auth/login/", views.login_api, name="api_login"),
    path("api/auth/register/", views.register_api, name="api_register"),
    path("api/auth/session/", views.session_api, name="api_session"),
    path("api/auth/logout/", views.logout_api, name="api_logout"),
    path("api/products/", views.products_api, name="api_products"),
    path("api/products/create/", views.product_create_api, name="api_product_create"),
    path("api/products/<int:product_id>/", views.product_update_api, name="api_product_update"),
    path("api/products/<int:product_id>/delete/", views.product_delete_api, name="api_product_delete"),
    path("api/sales/", views.sales_api, name="api_sales"),
    path("api/sales/create/", views.sale_create_api, name="api_sale_create"),
    path("api/sales/export/", views.sales_export_api, name="api_sales_export"),
    path("api/categories/", views.categories_api, name="api_categories"),
    path("api/categories/create/", views.category_create_api, name="api_category_create"),
    path("api/clients/", views.clients_api, name="api_clients"),
    path("api/clients/create/", views.client_create_api, name="api_client_create"),
    path("api/sales/<str:folio>/status/", views.sale_status_api, name="api_sale_status"),

    path("api/users/", views.users_api, name="api_users"),
    path("api/users/create/", views.user_create_api, name="api_user_create"),
    path("api/users/<int:user_id>/", views.user_update_api, name="api_user_update"),
    path("api/users/<int:user_id>/delete/", views.user_delete_api, name="api_user_delete"),
]
