terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # O la versión que prefieras
    }
  }
}

provider "aws" {
  region = "us-east-1" # <--- CAMBIA ESTO por tu región favorita de AWS
}

# Esto busca la última imagen de Ubuntu 24.04 automáticamente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (el creador de Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "app_server" {
  # Ahora usamos el ID que Terraform encontró arriba
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"             # La opción gratuita (Free Tier)
  key_name      = "clavesecreta12345"         # El nombre de tu par de llaves en AWS

  # Seguridad: Abrir puertos 22 (SSH) y 80 (HTTP)
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # INYECCIÓN DE VARIABLES AL SCRIPT
  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    db_name           = var.db_name
    db_user           = var.db_user
    db_password       = var.db_password
    django_secret_key = var.django_secret_key
    docker_image      = var.docker_image
  })

  tags = {
    Name = "ServicioUsuario"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "usuario-sg"
  description = "Permitir HTTP y SSH"

  # Puerto 80 para que tu App sea visible en la web
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto 22 para que puedas entrar por SSH si es necesario
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Por seguridad, podrías poner solo tu IP aquí
  }

  # Permitir que el servidor salga a internet (para bajar Docker, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Para que GitHub te diga la IP al terminar
output "server_public_ip" {
  value = aws_instance.app_server.public_ip
}