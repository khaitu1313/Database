from django.urls import path
from . import views

urlpatterns = [
    path('', views.store, name="store"),  # Home page
    path('home/', views.store, name="store"),  # Home page
    path('laptop/', views.laptop_page, name="laptop"),
    path('keyboard/', views.keyboard_page, name="keyboard"),
    path('mouse/', views.mouse_page, name="mouse"),
    path('headset/', views.headset_page, name="headset"),
    path('order/', views.cart, name="order"),
    path('checkout/', views.checkout, name="checkout"),
    path('update_item/', views.updateItem, name="update_item"),
    path('process_order/', views.processOrder, name="process_order"),
]
