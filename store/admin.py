from django.contrib import admin
from django.contrib.admin import AdminSite
from .models import *
from django import forms

# class ProductInline(admin.StackedInline):
#     model = Product
#     fields = ('name', 'price', 'image', 'm_date', 'e_date', 'status')
#     readonly_fields = ('id',)  # Make the `id` field read-only to avoid confusion.
#     extra = 0  # No additional blank forms

# class ProductForm(forms.ModelForm):
#     class Meta:
#         model = Product
#         fields = '__all__'

#     def clean_id(self):
#         id = self.cleaned_data.get('id')
#         if Product.objects.filter(id=id).exists():
#             raise forms.ValidationError("A product with this ID already exists.")
#         return id

# class ProductAdmin(admin.ModelAdmin):
#     form = ProductForm
#     list_display = ('id', 'name', 'price', 'm_date', 'e_date', 'status')
#     search_fields = ('name', 'status')
#     list_filter = ('status', 'm_date', 'e_date')


# class LaptopAdmin(admin.ModelAdmin):
#     list_display = ('id', 'ram', 'cpu', 'graphic_card', 'purpose')
#     search_fields = ('ram', 'cpu', 'graphic_card')
#     list_filter = ('purpose',)


# Register your models here.
admin.site.register(Product)
admin.site.register(Customer)
admin.site.register(Laptop)
admin.site.register(Keyboard)
admin.site.register(Employee)
admin.site.register(Mouse)
admin.site.register(Transaction)
admin.site.register(Headphone)
admin.site.register(ElectronicAccessories)
admin.site.register(OrderItem)
admin.site.register(ShippingAddress)


# username: tribang
# password: testuser123
