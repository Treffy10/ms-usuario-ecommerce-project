# .env.tpl
# Archivo de variables de entorno para Docker Compose en la EC2.

DB_PASSWORD=${db_password}
SECRET_KEY=${django_secret_key}
IMAGE_TAG=${image_tag}
DEBUG=False
ALLOWED_HOSTS=*