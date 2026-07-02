variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo de nombres de recursos"
  type        = string
  default     = "cruz-azul-erp"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 para el Web ERP"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nombre del key pair EC2 (opcional, para SSH)"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "AMI personalizada del Web ERP. Vacío = usa Amazon Linux 2023 + user-data."
  type        = string
  default     = ""
}

variable "asg_min" {
  description = "Capacidad mínima del Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_desired" {
  description = "Capacidad deseada del Auto Scaling Group"
  type        = number
  default     = 4
}

variable "asg_max" {
  description = "Capacidad máxima del Auto Scaling Group"
  type        = number
  default     = 8
}

variable "cpu_high_threshold" {
  description = "Umbral de CPU (%) para escalar hacia afuera (scale-out)"
  type        = number
  default     = 60
}

variable "cpu_low_threshold" {
  description = "Umbral de CPU (%) para escalar hacia adentro (scale-in)"
  type        = number
  default     = 20
}
