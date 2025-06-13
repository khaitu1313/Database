import pandas as pd
from django.core.management.base import BaseCommand
from store.models import *

class Command(BaseCommand):
    help = "Command is working as intended"

    def handle(self, *args, **options):
        file_path = r'C:\Users\Daryn Bang\Desktop\database_data\headset_data.xlsx'
        df = pd.read_excel(file_path, sheet_name="Sheet1")

        # Iterate over each row and create a keyboard instance
        for _, row in df.iterrows():
            try:
                # Retrieve or create the keyboardBrand instance
                brand_instance, created = HeadsetBrand.objects.get_or_create(headset_brand=row['Brand'])
                connection_instance, created = Connection.objects.get_or_create(connection=row['Connection'])
                type_instance, created = HeadsetType.objects.get_or_create(type=row['typehp'])

                headset = Headset(
                    name=row['Title'],
                    price=row['Price'],
                    status=True,
                    type_hp=type_instance,
                    brand=brand_instance,  # Use the instance instead of the string
                    connection=connection_instance,
                    image_link=row['image_link']
                )
                headset.save()
                self.stdout.write(self.style.SUCCESS(f"Headset'{headset}' created successfully."))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Error creating mouse: {e}"))

        self.stdout.write(self.style.SUCCESS("All headsets imported successfully."))

