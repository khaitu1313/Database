import pandas as pd
from django.core.management.base import BaseCommand
from store.models import *

class Command(BaseCommand):
    help = "Command is working as intended"

    def handle(self, *args, **options):
        file_path = r'C:\Users\Daryn Bang\Desktop\database_data\keyboard_data.xlsx'
        df = pd.read_excel(file_path, sheet_name="Sheet1")

        # Iterate over each row and create a keyboard instance
        for _, row in df.iterrows():
            try:
                # Retrieve or create the keyboardBrand instance
                brand_instance, created = KeyboardBrand.objects.get_or_create(keyboard_brand=row['Brand'])
                led_instance, created = KEYBOARD_LED.objects.get_or_create(led=row['LED'])
                switch_instance, created = Switch.objects.get_or_create(switch_type=row['Switch'])
                connection_instance, created = Connection.objects.get_or_create(connection=row['Connection'])
                layout_instance, created = Layout.objects.get_or_create(layout=row['Layout'])

                # Create the Keyboard instance using the brand instance
                keyboard = Keyboard(
                    name=row['Title'],
                    price=row['Price'],
                    status=True,
                    brand=brand_instance,  # Use the instance instead of the string
                    led=led_instance,
                    switch_type=switch_instance,
                    connection=connection_instance,
                    layout=layout_instance,
                    image_link=row['image_link']
                )
                keyboard.save()
                self.stdout.write(self.style.SUCCESS(f"Keyboard '{keyboard}' created successfully."))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Error creating keyboard: {e}"))

        self.stdout.write(self.style.SUCCESS("All keyboards imported successfully."))

