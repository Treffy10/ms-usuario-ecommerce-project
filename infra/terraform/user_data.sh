#!/bin/bash
set -e

# Actualizar sistema
apt-get update
apt-get upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Instalar Git y otras herramientas
apt-get install -y git nginx supervisor python3.11 python3.11-venv

# Crear directorio de la aplicación
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app

# Clonar repositorio
git clone https://github.com/Treffy10/ms-usuario-ecommerce-project.git .

# Crear carpeta para datos de PostgreSQL
mkdir -p /home/ubuntu/app/postgres_data
chown -R ubuntu:ubuntu /home/ubuntu/app

# Crear docker-compose.yml
cat > /home/ubuntu/app/docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: ecommerce-postgres
    environment:
      POSTGRES_DB: ecommerce_db
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
    build:
      context: ./servicio_usuario
      dockerfile: Dockerfile
    container_name: ecommerce-django
    command: >
      sh -c "python manage.py migrate &&
             gunicorn --workers 4 --bind 0.0.0.0:8000 --timeout 120 servicio_usuario.wsgi"
    environment:
      DEBUG: "False"
      SECRET_KEY: ${SECRET_KEY}
      DATABASE_URL: postgresql://ecommerce_admin:${DB_PASSWORD}@postgres:5432/ecommerce_db
      ALLOWED_HOSTS: "*"
    volumes:
      - /home/ubuntu/app/servicio_usuario:/app
      - /home/ubuntu/app/static_files:/app/static
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
    restart: always
EOF

# Crear Dockerfile para Django
mkdir -p /home/ubuntu/app/servicio_usuario
cat > /home/ubuntu/app/servicio_usuario/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000
EOF

# Actualizar requirements.txt
cat > /home/ubuntu/app/servicio_usuario/requirements.txt << 'EOF'
Django==5.2.8
djangorestframework==3.16.1
django-cors-headers==4.9.0
djangorestframework-simplejwt==5.5.1
psycopg2-binary==2.9.11
python-decouple==3.8
gunicorn==22.0.0
EOF

# Cambiar permisos
chown -R ubuntu:ubuntu /home/ubuntu/app

# Configurar Nginx
cat > /etc/nginx/sites-available/ecommerce << 'NGINX'
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

# Iniciar Docker Compose
cd /home/ubuntu/app
export DB_PASSWORD="${DB_PASSWORD}"
export SECRET_KEY="${SECRET_KEY}"
/usr/local/bin/docker-compose up -d

# Log
echo "Aplicación desplegada con Docker Compose" > /var/log/deployment.log