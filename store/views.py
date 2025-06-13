from django.shortcuts import render, redirect
from django.http import JsonResponse, HttpResponse
from django.db import transaction as db_transaction
import json
from datetime import datetime
from django.contrib.auth.models import User
from django.contrib.auth import login, authenticate
from .models import *
from .utils import *
from django.db.models import Min
from .filters import *

# Create your views here.


def store(request):
    data = cartData(request)
    cartItems = data["cartItems"]
    order = data["order"]
    items = data["items"]

    laptops = (
        Laptop.objects.select_related("id").filter(id__status="New").order_by("?")[:3]
    )
    keyboards = (
        Keyboard.objects.select_related("id").filter(id__status="New").order_by("?")[:3]
    )
    mice = Mouse.objects.select_related("id").filter(id__status="New").order_by("?")[:3]
    earphones = (
        Headphone.objects.select_related("id")
        .filter(id__status="New")
        .order_by("?")[:3]
    )

    context = {
        "laptops": laptops,
        "keyboards": keyboards,
        "mice": mice,
        "earphones": earphones,
        "cartItems": cartItems,
    }
    return render(request, "store/store.html", context)


def laptop_page(request):
    data = cartData(request)
    cartItems = data["cartItems"]
    order = data["order"]
    items = data["items"]

    laptops = (
        Laptop.objects.select_related(
            "id"
        )  # Include related Product data for efficiency
        .filter(id__status__in=["New", "2nd"])  # Filter by status: 'New' or '2nd'
        .order_by("id")  # Order by ID
    )

    laptop_filter = LaptopFilter(request.GET, queryset=laptops)

    context = {
        "form": laptop_filter.form,
        "laptops": laptop_filter.qs,
        "cartItems": cartItems,
    }

    return render(request, "store/laptop.html", context)


def keyboard_page(request):
    data = cartData(request)
    cartItems = data["cartItems"]
    order = data["order"]
    items = data["items"]

    keyboards = (
        Keyboard.objects.select_related(
            "id"
        )  # Include related Product data for efficiency
        .filter(id__status__in=["New", "2nd"])  # Filter by status: 'New' or '2nd'
        .order_by("id")  # Order by ID
    )

    keyboard_filter = KeyboardFilter(request.GET, queryset=keyboards)

    context = {
        "form": keyboard_filter.form,
        "keyboards": keyboard_filter.qs,
        "cartItems": cartItems,
    }

    return render(request, "store/keyboard.html", context)


def mouse_page(request):
    data = cartData(request)
    cartItems = data["cartItems"]
    order = data["order"]
    items = data["items"]

    mice = (
        Mouse.objects.select_related(
            "id"
        )  # Include related Product data for efficiency
        .filter(id__status__in=["New", "2nd"])  # Filter by status: 'New' or '2nd'
        .order_by("id")  # Order by ID
    )

    mouse_filter = MouseFilter(request.GET, queryset=mice)

    context = {
        "form": mouse_filter.form,
        "mice": mouse_filter.qs,
        "cartItems": cartItems,
    }

    return render(request, "store/mouse.html", context)


def headset_page(request):
    data = cartData(request)
    cartItems = data["cartItems"]
    order = data["order"]
    items = data["items"]

    earphones = (
        Headphone.objects.select_related(
            "id"
        )  # Include related Product data for efficiency
        .filter(id__status__in=["New", "2nd"])  # Filter by status: 'New' or '2nd'
        .order_by("id")  # Order by ID
    )

    earphone_filter = HeadphoneFilter(request.GET, queryset=earphones)

    context = {
        "form": earphone_filter.form,
        "earphones": earphone_filter.qs,
        "cartItems": cartItems,
    }

    return render(request, "store/headset.html", context)


# Adjust cart function
def cart(request):
    data = cartData(request)

    cartItems = data["cartItems"]
    order = data["order"]
    items = data["items"]

    context = {"items": items, "order": order, "cartItems": cartItems}
    return render(request, "store/order.html", context)


def checkout(request):
    data = cartData(request)

    cartItems = data["cartItems"]
    order = data["order"]
    items = data["items"]
    payment_methods = PaymentMethod.objects.all()

    context = {
        "items": items,
        "order": order,
        "cartItems": cartItems,
        "payment_methods": payment_methods,
    }
    return render(request, "store/checkout.html", context)


def updateItem(request):
    data = json.loads(request.body)
    productId = data["productId"]
    action = data["action"]

    print("Action: ", action)
    print("productId: ", productId)

    # customer_id = request.user.id
    customer = get_customer_from_user(request.user)
    customer_id = customer.id
    product = Product.objects.get(id=productId)
    order, created = Transaction.objects.get_or_create(
        id=customer_id, status="Pending", defaults={"total": 0}
    )

    orderItem, created = OrderItem.objects.get_or_create(
        order=order, product=product, defaults={"previous_status": product.status}
    )

    if action == "add":
        if orderItem.quantity < 1:  # Only add if the quantity is less than 1
            orderItem.quantity += 1
            product.mark_as_pending()  # Update product status to pending
            product.c = customer
            product.t = order
            product.save()

    elif action == "remove":
        if orderItem.quantity > 0:  # Only remove if there's something to remove
            orderItem.quantity -= 1
            if orderItem.quantity == 0:  # If quantity becomes 0, restore product status
                product.status = orderItem.previous_status
                product.c = None
                product.t = None
                product.save()

    if orderItem.quantity > 0:
        orderItem.save()
    else:
        orderItem.delete()

    # Update the Transaction's total
    order.update_cart_total()

    return JsonResponse("Item added", safe=False)


def processOrder(request):
    data = json.loads(request.body)

    # if request.user.is_authenticated:
    #     customer = request.user.customer
    # order, created = Order.objects.get_or_create(customer=customer, complete=False)
    # else:
    #     customer, order = guestOrder(request, data)

    total = float(data["form"]["total"])
    # order.transaction_id = transaction_id

    # if total == order.get_cart_total:
    #     order.complete = True
    # order.save()

    # ShippingAddress.objects.create(
    #     customer=customer,
    #     order=order,
    #     address=data["shipping"]["address"],
    #     district=data["shipping"]["district"],
    #     street=data["shipping"]["street"],
    #     city=data["shipping"]["ward"],
    # )

    # Create a new Transaction instance with the selected payment type
    customer = get_customer_from_user(request.user)
    customer_id = customer.id
    transaction = Transaction.objects.update_or_create(
        id=customer_id,
        defaults={
            "pm_type": PaymentMethod.objects.get(type=data["payment_type"]),
            "total": total,
            "status": "Finished",
        },
    )

    # Associate the transaction with the order
    # order.transaction = transaction
    # order.save()

    return JsonResponse("Payment submitted..", safe=False)


def customer_registration(request):
    if request.method == "POST":
        name = request.POST.get("name")
        ssn = request.POST.get("ssn")
        address = request.POST.get("address")
        phone = request.POST.get("phone")

        # Validate inputs (e.g., SSN uniqueness, non-empty fields)
        if not name or not ssn or not address or not phone:
            return HttpResponse("All fields are required!", status=400)

        if Customer.objects.filter(ssn=ssn).exists():
            return HttpResponse("Customer with this SSN already exists!", status=400)

        # Retrieve the current max ID and increment it
        max_id = Customer.objects.aggregate(max_id=models.Max("id"))["max_id"]
        new_id = (max_id or 0) + 1  # Start from 1 if no customers exist

        # Create Customer in a single atomic operation
        with db_transaction.atomic():
            customer = Customer.objects.create(
                id=new_id,  # Explicitly set the ID
                ssn=ssn,
                name=name,
                address=address,
                phone=phone,
            )

            username = f"user_{new_id}"
            user = User.objects.create_user(
                username=username,
                password=ssn,  # Use SSN as the temporary password (you may want to enforce a change later)
                first_name=name.split()[0],
                last_name=" ".join(name.split()[1:]),
            )

            customer.user = user
            customer.save()

            user.is_staff = True
            user.is_superuser = True
            user.save()

            # Authenticate and log the user in
            user = authenticate(username=username, password=ssn)
            if user:
                login(request, user)

        return redirect("store")

    return render(request, "store/customer_registration.html")
