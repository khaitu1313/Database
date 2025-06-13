import json
from .models import *
from django.core.exceptions import ObjectDoesNotExist

def get_customer_from_user(user):
    try:
        # Assuming the user's username is "user_<customer_id>"
        customer_id = int(user.username.split("_")[1])
        return Customer.objects.get(id=customer_id)
    except (IndexError, ValueError, ObjectDoesNotExist):
        return None

def cookieCart(request):
    # Create empty cart for now for non-logged in user
    try:
        cart = json.loads(request.COOKIES["cart"])
    except:
        cart = {}
        print("CART:", cart)
    print("carrrt:", cart)

    items = []
    order = {"get_cart_total": 0, "get_cart_items": 0, "shipping": False}
    cartItems = order["get_cart_items"]

    for i in cart:
        # We use try block to prevent items in cart that may have been removed from causing error
        try:
            if cart[i]["quantity"] > 0:  # items with negative quantity = lot of freebies
                cartItems += cart[i]["quantity"]

                print(i)
                product = Product.objects.get(id=i)

                total = product.price * cart[i]["quantity"]

                order["get_cart_total"] += total
                order["get_cart_items"] += cart[i]["quantity"]

                item = {
                    "id": product.id,
                    "product": {
                        "id": product.id,
                        "name": product.name,
                        "price": product.price,
                        "image_link": product.image,
                    },
                    "quantity": cart[i]["quantity"],
                    # "digital": product.digital,
                    "get_total": total,
                }
                items.append(item)

        except:
            pass

    return {"cartItems": cartItems, "order": order, "items": items}


def cartData(request):
    if request.user.is_authenticated:
        customer_id = get_customer_from_user(request.user).id
        # order, created = Order.objects.get_or_create(customer=customer, complete=False)
        transaction, created = Transaction.objects.get_or_create(id=customer_id,
                                                                 status="Pending",
                                                                 defaults={"total": 0})

        items = transaction.orderitem_set.all()
        cartItems = transaction.get_cart_items

    else:
        cookieData = cookieCart(request)
        cartItems = cookieData["cartItems"]
        transaction = cookieData["order"]
        items = cookieData["items"]

    return {"cartItems": cartItems, "order": transaction, "items": items}


def guestOrder(request, data):
    name = data["form"]["name"]

    cookieData = cookieCart(request)
    items = cookieData["items"]

    customer, created = Customer.objects.get_or_create(name=name)
    customer.save()

    order = Transaction.objects.create(
        customer=customer,
        status='Pending',
        total=0
    )

    for item in items:
        product = Product.objects.get(id=item["id"])
        orderItem = OrderItem.objects.create(
            product=product,
            order=order,
            quantity=(
                item["quantity"] if item["quantity"] > 0 else -1 * item["quantity"]
            ),  # negative quantity = freebies
        )
    return customer, order
