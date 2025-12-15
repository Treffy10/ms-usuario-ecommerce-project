# 1. Usa la imagen base más pequeña y segura
FROM python:3.11-slim

# 2. Establece el directorio de trabajo
WORKDIR /app

# 3. Instalación de dependencias del sistema y limpieza
RUN apt-get update && apt-get install -y \
    postgresql-client \
    # Dependencias para ejecutar Gunicorn/Postgres
    && rm -rf /var/lib/apt/lists/*

# 4. Copia e instalación de dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copia todo el código de la aplicación
COPY . .

# 6. Prepara el script de entrada (entrypoint)
# Este script manejará las migraciones y el inicio de la app.
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# 7. Exposición del puerto
EXPOSE 8000

# 8. Define el ENTRYPOINT para ejecutar el script al iniciar el contenedor
ENTRYPOINT ["entrypoint.sh"]

# 9. Define el CMD: es el comando que ENTRYPOINT ejecutará por defecto
CMD ["gunicorn", "servicio_usuario.wsgi:application", "--bind", "0.0.0.0:8000"]