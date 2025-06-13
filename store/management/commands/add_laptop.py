import pandas as pd
from django.core.management.base import BaseCommand
from store.models import *

class Command(BaseCommand):
    help = "Command is working as intended"

    def handle(self, *args, **options):
        file_path = r'C:\Users\Daryn Bang\Desktop\database_data\laptop_data.xlsx'
        df = pd.read_excel(file_path, sheet_name="Sheet1")

        # Iterate over each row and create a Laptop instance
        for _, row in df.iterrows():
            try:
                # Retrieve or create the LaptopBrand instance
                brand_instance, created = LaptopBrand.objects.get_or_create(laptop_brand=row['Brand'])
                cpu_instance, created = CPU.objects.get_or_create(cpu=row['CPU'])
                gpu_instance, created = GPU.objects.get_or_create(series=row['Card Series'])
                ram_instance, created = RAM.objects.get_or_create(size=row['RAM'])
                purpose_instance, created = Purpose.objects.get_or_create(purpose=row['Purpose'])

                # Create the Laptop instance using the brand instance
                laptop = Laptop(
                    name=row['Title'],
                    price=row['Price'],
                    status=True,
                    brand=brand_instance,  # Use the instance instead of the string
                    ram=ram_instance,
                    cpu=cpu_instance,
                    gpu_series=gpu_instance,
                    gpu_details=row['Graphics Card'],
                    purpose=purpose_instance,
                    image_link=row['image_link']
                )
                laptop.save()
                self.stdout.write(self.style.SUCCESS(f"Laptop '{laptop}' created successfully."))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Error creating laptop: {e}"))

        self.stdout.write(self.style.SUCCESS("All laptops imported successfully."))

