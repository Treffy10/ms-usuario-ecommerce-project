#!/bin/bash
# ==========================================================
# SCRIPT DE APROVISIONAMIENTO PARA MICROSERVICIO USUARIO
# ==========================================================

# 1. LIMPIEZA DE NGINX (Para evitar conflictos en puerto 80)
echo "Limpiando Nginx preinstalado..."
sudo apt-get update
sudo apt-get remove -y nginx nginx-common
sudo apt-get autoremove -y
sudo systemctl stop nginx || true

# 2. INSTALACIÓN DE DOCKER Y DEPENDENCIAS
echo "Instalando Docker..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Iniciar Docker
sudo systemctl start docker
sudo systemctl enable docker

# 3. PREPARAR DIRECTORIO DE LA APP
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app

# 4. CREAR ARCHIVO .ENV (Inyectado por Terraform)
cat > .env <<EOF
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
DB_HOST=db
DB_PORT=5432
DJANGO_SECRET_KEY=${django_secret_key}
DOCKER_IMAGE=${docker_image}
EOF

# 5. CREAR DOCKER-COMPOSE.YML DINÁMICO
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  db:
    image: postgres:15-alpine
    restart: always
    environment:
      POSTGRES_DB: ${db_name}
      POSTGRES_USER: ${db_user}
      POSTGRES_PASSWORD: ${db_password}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${db_user} -d ${db_name}"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    image: ${docker_image}
    restart: always
    depends_on:
      db:
        condition: service_healthy
    env_file:
      - .env
    ports:
      - "80:8000"
    command: >
      sh -c "python manage.py migrate --noinput &&
             gunicorn --bind 0.0.0.0:8000 servicio_usuario.wsgi:application"

volumes:
  postgres_data:
EOF

# 6. LEVANTAR EL MICROSERVICIO
echo "Levantando contenedores..."
sudo docker compose up -d