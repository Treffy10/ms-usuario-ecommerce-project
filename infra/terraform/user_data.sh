#!/bin/bash
set -e

# --- 1. Preparación del Sistema ---
echo "Actualizando sistema e instalando herramientas base..."
apt-get update
apt-get upgrade -y
apt-get install -y git nginx

# --- 2. Instalación de Docker y Docker Compose ---
echo "Instalando Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

echo "Instalando Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# --- 3. Configuración de la Aplicación y Variables ---
echo "Creando estructura de la app..."
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app

# Importante: Este archivo .env debe ser llenado por Terraform!
# Lo creamos vacío para evitar fallos de docker-compose
touch /home/ubuntu/app/.env 

# Crear carpetas de datos
mkdir -p /home/ubuntu/app/postgres_data
mkdir -p /home/ubuntu/app/static_files
chown -R ubuntu:ubuntu /home/ubuntu/app

# --- 4. Crear docker-compose.yml (Usando la imagen de Docker Hub) ---
echo "Creando docker-compose.yml..."
cat > /home/ubuntu/app/docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: ecommerce-postgres
    # Las variables vienen del archivo .env que se llena con Terraform
    environment:
      POSTGRES_DB: usuario_db_ecomerce
      POSTGRES_USER: ecommerce_admin
      POSTGRES_PASSWORD: ${DB_PASSWORD} 
    volumes:
      - /home/ubuntu/app/postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ecommerce_admin"]
      interval: 10s
      timeout: 5s
      retries: 5

  django-app:
    container_name: ecommerce-django
    # 💡 Comando SIMPLIFICADO. El entrypoint.sh dentro de la imagen hará las migraciones.
    command: ["gunicorn", "servicio_usuario.wsgi:application", "--workers", "4", "--bind", "0.0.0.0:8000", "--timeout", "120"]
    environment:
      DEBUG: "False"
      SECRET_KEY: ${SECRET_KEY}
      DATABASE_URL: postgresql://ecommerce_admin:${DB_PASSWORD}@postgres:5432/usuario_db_ecomerce
      ALLOWED_HOSTS: "*"
    volumes:
      # Montamos solo los estáticos para Nginx
      - /home/ubuntu/app/static_files:/app/static 
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
    restart: always
EOF

# --- 5. Configuración de Nginx ---
echo "Configurando Nginx..."
cat > /etc/nginx/sites-available/ecommerce << 'NGINX'
# ... (Nginx se mantiene igual, ya que es una configuración estándar)
upstream django {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name _;
    client_max_body_size 10M;

    location / {
        proxy_pass http://django;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    location /static/ {
        alias /home/ubuntu/app/static_files/;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/ecommerce /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx
systemctl start nginx

# --- 6. Primera ejecución (solo para levantar la DB y dejar todo listo) ---
echo "Iniciando Docker Compose por primera vez (Postgres/Django-App)..."
cd /home/ubuntu/app
# No usamos -d, lo hacemos en segundo plano para que el user_data termine
/usr/local/bin/docker-compose pull
/usr/local/bin/docker-compose up -d

# Log
echo "✅ Instalación inicial completada." > /var/log/deployment.log