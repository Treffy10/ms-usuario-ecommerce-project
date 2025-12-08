variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Región de AWS"
}

variable "terraform_bucket" {
  type        = string
  description = "Nombre del bucket S3 para el estado de Terraform"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block de la VPC"
}

variable "public_subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR block de la subnet pública"
}

variable "private_subnet_cidr" {
  type        = string
  default     = "10.0.2.0/24"
  description = "CIDR block de la subnet privada"
}

variable "ec2_instance_type" {
  type        = string
  default     = "t3.small" # Más recursos para DB + App
  description = "Tipo de instancia EC2"
}

variable "db_password" {
  type        = string
  description = "Contraseña de PostgreSQL"
  sensitive   = true
}

variable "django_secret_key" {
  type        = string
  description = "Django SECRET_KEY"
  sensitive   = true
}

variable "ssh_allowed_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks permitidos para SSH"
}

variable "public_key_content" {
  type        = string
  description = "Contenido de la clave pública SSH"
}