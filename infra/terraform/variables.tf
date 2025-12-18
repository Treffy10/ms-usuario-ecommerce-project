variable "db_name" {
  type        = string
  description = "Nombre de la base de datos PostgreSQL"
}
variable "db_user" {
  type        = string
  description = "Usuario de la base de datos PostgreSQL"
}
variable "db_password" {
  type        = string
  description = "Contraseña de la base de datos PostgreSQL"
  sensitive   = true
}
variable "django_secret_key" {
  type        = string
  description = "Django SECRET_KEY"
    sensitive   = true
}
variable "docker_image" {
  type        = string
  description = "Imagen de Docker para desplegar la aplicación"
}

