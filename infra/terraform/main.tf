terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "mi-bucket-terraform-ecommerce-project"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecommerce-vpc"
  }
}

# Subnet Pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "ecommerce-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ecommerce-igw"
  }
}

# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "ecommerce-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group para EC2
resource "aws_security_group" "ec2" {
  name        = "ecommerce-ec2-sg"
  description = "Security group para EC2 de ecommerce"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir SSH desde cualquier lugar
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-ec2-sg"
  }
}

# EC2 Instance
resource "aws_instance" "app" {
  ami                      = data.aws_ami.ubuntu.id
  instance_type            = var.ec2_instance_type
  subnet_id                = aws_subnet.public.id
  vpc_security_group_ids   = [aws_security_group.ec2.id]
  key_name                 = data.aws_key_pair.existing.key_name

  root_block_device {
    volume_size             = 30
    volume_type             = "gp3"
    delete_on_termination   = true
  }

  # --- Bloque USER DATA CORREGIDO: Inyecta el .env ---
  user_data = base64encode(
    # PASAMOS UNA SOLA CADENA MULTILÍNEA A base64encode
    # Esta única cadena contiene la inyección del script user_data.sh y la inyección del .env
    <<-EOF
    #!/bin/bash
    set -e
    
    # 1. EJECUTA EL SCRIPT DE INSTALACIÓN BASE
    # El archivo user_data.sh ya no debe tener un shebang #!/bin/bash
    ${file("${path.module}/user_data.sh")}
    
    # 2. INYECCIÓN DE VARIABLES SECRETAS (Crea el archivo /home/ubuntu/app/.env)
    echo "Inyectando secretos en /home/ubuntu/app/.env..."
    
    echo '${templatefile("${path.module}/.env.tpl", {
      db_password       = var.db_password,
      django_secret_key = var.django_secret_key,
      image_tag         = "${var.dockerhub_username}/ms-usuario:latest" 
    })}' > /home/ubuntu/app/.env
    
    chown ubuntu:ubuntu /home/ubuntu/app/.env
    echo "✅ Archivo .env creado."
    # --- Fin de la inyección ---
    EOF
  )
  # --------------------------------------------------

  tags = {
    Name = "ecommerce-usuario-service"
  }
}

# Elastic IP para EC2
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "ecommerce-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# Usa un data source para referenciar el existente
data "aws_key_pair" "existing" {
  key_name = "clavesecreta12345"  # ← Tu key pair existente
}

# S3 Bucket para archivos estáticos
data "aws_s3_bucket" "existing_bucket" {
  bucket = "mi-bucket-terraform-ecommerce-project"  # ← El nombre EXACTO de tu bucket
}

# Outputs
output "ec2_public_ip" {
  value       = aws_eip.app.public_ip
  description = "Public IP de la instancia EC2"
}

output "ec2_instance_id" {
  value       = aws_instance.app.id
  description = "ID de la instancia EC2"
}

output "s3_bucket_name" {
  value       = data.aws_s3_bucket.existing_bucket.id
  description = "Nombre del bucket S3"
}