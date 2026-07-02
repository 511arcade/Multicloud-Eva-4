# SG del ALB: acepta tráfico HTTP/HTTPS desde Internet
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Permite HTTP/HTTPS entrante al ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
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
  tags = { Name = "${var.project_name}-sg-alb" }
}

# SG del Web ERP: solo acepta tráfico en :3000 desde el ALB
resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg-web"
  description = "Web ERP: solo desde el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App desde el ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-sg-web" }
}

# SG de la BD: solo acepta :5432 desde el SG del Web ERP (capa de datos aislada)
resource "aws_security_group" "db" {
  name        = "${var.project_name}-sg-db"
  description = "PostgreSQL: solo desde el Web ERP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL desde Web ERP"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-sg-db" }
}
