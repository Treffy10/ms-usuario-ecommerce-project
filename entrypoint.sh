#!/bin/bash
# entrypoint.sh

# Ejecuta las migraciones
echo "Ejecutando migraciones..."
python manage.py migrate --noinput

# Recopila los archivos estáticos
echo "Recopilando archivos estáticos..."
python manage.py collectstatic --noinput

# Finalmente, ejecuta el comando principal (Gunicorn)
exec "$@"