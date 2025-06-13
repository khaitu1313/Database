# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models
from django.contrib.auth.models import User

# Setting managed = false
class Employee(models.Model):
    id = models.IntegerField(db_column='ID', primary_key=True)
    ssn = models.CharField(db_column='SSN', unique=True, max_length=255)
    name = models.CharField(db_column='Name', max_length=255)  # Field name made lowercase.

    class Meta:
        managed = False
        db_table = 'employee'

    def __str__(self):
        return f"{self.id} - {self.name}"

class StoreManager(models.Model):
    id = models.OneToOneField(Employee, models.DO_NOTHING, db_column='ID', primary_key=True)  # Field name made lowercase.

    class Meta:
        managed = False
        db_table = 'store_manager'

class Warehouse(models.Model):
    address = models.CharField(db_column='Address', primary_key=True, max_length=255)  # Field name made lowercase.
    name = models.CharField(db_column='Name', max_length=255, blank=True, null=True)  # Field name made lowercase.
    area = models.DecimalField(db_column='Area', max_digits=10, decimal_places=2, blank=True,
                               null=True)  # Field name made lowercase.
    wm = models.ForeignKey('WarehouseManager', models.DO_NOTHING, db_column='WM_ID')  # Field name made lowercase.

    class Meta:
        managed = False
        db_table = 'warehouse'

    def __str__(self):
        return self.name


class WarehouseManager(models.Model):
    id = models.OneToOneField(Employee, models.DO_NOTHING, db_column='ID',
                              primary_key=True)  # Field name made lowercase.

    class Meta:
        managed = False
        db_table = 'warehouse_manager'


class Applies(models.Model):
    p = models.ForeignKey('Product', models.DO_NOTHING, db_column='P_ID', primary_key=True, related_name="applies")
    d = models.ForeignKey('DiscountProgram', models.DO_NOTHING, db_column='D_ID')
    saving = models.IntegerField(db_column='Saving')

    class Meta:
        managed = False
        db_table = 'applies'
        unique_together = (('p', 'd'),)


class Brand(models.Model):
    name = models.CharField(db_column='Name', primary_key=True, max_length=255)

    class Meta:
        managed = False
        db_table = 'brand'

    def __str__(self):
        return self.name


class Customer(models.Model):
    id = models.IntegerField(db_column='ID', primary_key=True)
    ssn = models.CharField(db_column='SSN', unique=True, max_length=255)
    name = models.CharField(db_column='Name', max_length=255)
    address = models.CharField(db_column='Address', max_length=255)
    phone = models.CharField(db_column='Phone', max_length=255)

    class Meta:
        managed = False
        db_table = 'customer'

    def __str__(self):
        return f"{self.id} - {self.name}"


class DiscountProgram(models.Model):
    id = models.IntegerField(db_column='ID', primary_key=True)
    name = models.CharField(db_column='Name', max_length=255)
    description = models.CharField(db_column='Description', max_length=255, blank=True, null=True)
    fromdate = models.DateField(db_column='FromDate')
    todate = models.DateField(db_column='ToDate')
    percent = models.DecimalField(db_column='Percent', max_digits=10, decimal_places=2)

    class Meta:
        managed = False
        db_table = 'discount_program'

class Product(models.Model):
    id = models.IntegerField(db_column='ID', primary_key=True)
    image = models.CharField(db_column='Image', max_length=255)
    name = models.CharField(db_column='Name', max_length=255)
    price = models.IntegerField(db_column='Price')
    m_date = models.DateField(db_column='M_Date', verbose_name="Manufacture Date")
    e_date = models.DateField(db_column='E_Date', verbose_name="Expiry Date")

    status = models.CharField(db_column='Status', max_length=255)
    b_name = models.ForeignKey(Brand, models.DO_NOTHING, db_column='B_Name', related_name='products')
    w_addr = models.ForeignKey('Warehouse', models.DO_NOTHING, db_column='W_Addr')

    c = models.ForeignKey(Customer, models.DO_NOTHING, db_column='C_ID', blank=True, null=True)
    t = models.ForeignKey('Transaction', models.DO_NOTHING, db_column='T_ID', blank=True, null=True)
    

    class Meta:
        managed = False
        db_table = 'product'

    def __str__(self):
        return f"{self.id}"


    def mark_as_sold(self):
        if self.status == 'Sold':
            raise ValueError("Product is already sold.")
        self.status = 'Sold'
        self.save()

    def mark_as_pending(self):
        if self.status == 'Pending':
            raise ValueError("Product is already in cart.")
        # self.status = 'Pending'

        if self.status == 'New':
            self.status = 'New_Ordering'

        elif self.status == '2nd':
            self.status = '2nd_Ordering'

        self.save()


    def mark_as_2nd(self):
        if self.status == '2nd':
            raise ValueError("Product is already 2nd.")
        self.status = '2nd'
        self.save()


    def mark_as_new(self):
        if self.status == 'New':
            raise ValueError("Product is New.")
        self.status = 'New'
        self.save()
    
    def get_discount_programs(self):
        discount_names = self.applies.all().values_list('d__name', flat=True)
        return ", ".join(discount_names)
        


class Laptop(models.Model):
    id = models.OneToOneField('Product', models.CASCADE, db_column='ID', primary_key=True, related_name='laptop')
    ram = models.CharField(db_column='RAM', max_length=255)
    cpu = models.CharField(db_column='CPU', max_length=255)
    graphic_card = models.CharField(db_column='Graphic_Card', max_length=255)
    purpose = models.CharField(db_column='Purpose', max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'laptop'

    def __str__(self):
        return f"{self.id}"


class ElectronicAccessories(models.Model):
    id = models.IntegerField(db_column='ID', primary_key=True)
    connection = models.CharField(db_column='Connection', max_length=255)

    class Meta:
        managed = False
        db_table = 'electronic_accessories'

    def __str__(self):
        return f'{self.id} - {self.connection}'

class Keyboard(models.Model):
    id = models.OneToOneField('Product', models.CASCADE, db_column='ID', primary_key=True, related_name='keyboard')
    switch_type = models.CharField(db_column='Switch_Type', max_length=255)
    layout = models.CharField(db_column='Layout', max_length=255)

    class Meta:
        managed = False
        db_table = 'keyboard'

    def __str__(self):
        return f'{self.id} - {self.connection}'

    def save(self, *args, **kwargs):
        # Create a corresponding ElectronicAccessories instance if not already exists
        if not ElectronicAccessories.objects.filter(id=self.id.id).exists():
            ElectronicAccessories.objects.create(id=self.id.id, connection="Wired")
        super().save(*args, **kwargs)

    def get_connection(self):
        try:
            return ElectronicAccessories.objects.get(id=self.id.id).connection
        except ElectronicAccessories.DoesNotExist:
            return None


class Mouse(models.Model):
    id = models.OneToOneField('Product', models.CASCADE, db_column='ID', primary_key=True, related_name='mouse')
    led_color = models.CharField(db_column='LED_Color', max_length=255)
    dpi = models.IntegerField(db_column='DPI')

    class Meta:
        managed = False
        db_table = 'mouse'

    def __str__(self):
        return f"{self.id}"

    def save(self, *args, **kwargs):
        # Create a corresponding ElectronicAccessories instance if not already exists
        if not ElectronicAccessories.objects.filter(id=self.id.id).exists():
            ElectronicAccessories.objects.create(id=self.id.id, connection="Wired")
        super().save(*args, **kwargs)

    def get_connection(self):
        try:
            return ElectronicAccessories.objects.get(id=self.id.id).connection
        except ElectronicAccessories.DoesNotExist:
            return None


class Headphone(models.Model):
    id = models.OneToOneField('Product', models.CASCADE, db_column='ID', primary_key=True, related_name='headphone')
    type = models.CharField(db_column='Type', max_length=255)

    class Meta:
        managed = False
        db_table = 'headphone'

    def __str__(self):
        return f"{self.id}"

    def save(self, *args, **kwargs):
        # Create a corresponding ElectronicAccessories instance if not already exists
        if not ElectronicAccessories.objects.filter(id=self.id.id).exists():
            ElectronicAccessories.objects.create(id=self.id.id, connection="Both")
        super().save(*args, **kwargs)

    def get_connection(self):
        try:
            return ElectronicAccessories.objects.get(id=self.id.id).connection
        except ElectronicAccessories.DoesNotExist:
            return None



class Has(models.Model):
    b_name = models.OneToOneField(Brand, models.CASCADE, db_column='B_Name', primary_key=True)  # The composite primary key (B_Name, D_ID) found, that is not supported. The first column is selected.
    d = models.ForeignKey(DiscountProgram, models.DO_NOTHING, db_column='D_ID')

    class Meta:
        managed = False
        db_table = 'has'
        unique_together = (('b_name', 'd'),)


class PaymentMethod(models.Model):
    type = models.CharField(db_column='Type', primary_key=True, max_length=255)
    description = models.CharField(db_column='Description', max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payment_method'


class Transaction(models.Model):
    id = models.IntegerField(db_column='ID', primary_key=True)
    date = models.DateField(db_column='Date', auto_now_add=True)
    time = models.TimeField(db_column='Time', auto_now_add=True)
    status = models.CharField(db_column='Status', max_length=255)
    pm_type = models.ForeignKey(PaymentMethod, models.CASCADE, db_column='PM_Type')
    total = models.IntegerField(db_column='Total')

    class Meta:
        managed = False
        db_table = 'transaction'

    def __str__(self):
        return f"{self.id}"

    def update_cart_total(self):
        orderitems = self.orderitem_set.all()
        self.total = sum([item.get_total for item in orderitems])
        self.save()  # Save the updated total to the database
        return self.total

    @property
    def get_cart_total(self):
        orderitems = self.orderitem_set.all()
        total = sum([item.get_total for item in orderitems])
        self.total = total

        return total

    @property
    def get_cart_items(self):
        orderitems = self.orderitem_set.all()
        total = sum([item.quantity for item in orderitems])

        return total

class Order(models.Model):
    # One-to-many relationship with customer
    customer = models.ForeignKey(Customer, on_delete=models.SET_NULL, blank=True, null=True)
    date_ordered = models.DateTimeField(auto_now_add=True)
    complete = models.BooleanField(default=False, null=True, blank=False)
    transaction_id = models.CharField(max_length=100, null=True)

    def __str__(self):
        return str(self.id)

    @property
    def get_cart_total(self):
        orderitems = self.orderitem_set.all()
        total = sum([item.get_total for item in orderitems])

        return total

    @property
    def get_cart_items(self):
        orderitems = self.orderitem_set.all()
        total = sum([item.quantity for item in orderitems])

        return total


class Request(models.Model):
    no = models.IntegerField(db_column='No', primary_key=True)
    requirement = models.CharField(db_column='Requirement', max_length=255, blank=True, null=True)
    feedback = models.CharField(db_column='Feedback', max_length=255, blank=True, null=True)
    date = models.DateField(db_column='Date')
    c = models.ForeignKey(Customer, models.DO_NOTHING, db_column='C_ID')
    p = models.ForeignKey(Product, models.DO_NOTHING, db_column='P_ID')
    sm = models.ForeignKey('StoreManager', models.DO_NOTHING, db_column='SM_ID')

    class Meta:
        managed = False
        db_table = 'request'


class OrderItem(models.Model):
    product = models.ForeignKey(Product, models.SET_NULL, blank=True, null=True)
    order = models.ForeignKey(Transaction, on_delete=models.SET_NULL, blank=True, null=True)
    quantity = models.IntegerField(default=0, null=True, blank=True)
    date_added = models.DateTimeField(auto_now_add=True)
    previous_status = models.CharField(max_length=255, blank=True, null=True)  # To store the product's previous status

    class Meta:
        managed = True

    @property
    def get_total(self):
        total = self.product.price * self.quantity
        return total

    def restore_status(self):
        # Check if quantity is being reduced to 0
        if self.quantity == 0 and self.product:
            if self.previous_status:  # Restore the product's previous status
                self.product.status = self.previous_status
                self.product.save()


class ShippingAddress(models.Model):
    # One-to-many relationship with customer and order
    customer = models.ForeignKey(Customer, on_delete=models.SET_NULL, blank=True, null=True)
    order = models.ForeignKey(Order, on_delete=models.SET_NULL, blank=True, null=True)
    # Customer address below
    address = models.CharField(max_length=100, null=True)
    street = models.CharField(max_length=100, null=True)
    district = models.CharField(max_length=100, null=True)
    city = models.CharField(max_length=100, null=True)

    date_added = models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return f"{self.address} {self.street} {self.district}, {self.city}"

