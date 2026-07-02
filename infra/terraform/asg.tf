# AMI por defecto: Amazon Linux 2023 (si no se entrega una AMI personalizada)
data "aws_ami" "al2023" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  effective_ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023[0].id
}

# Launch Template (configuración de lanzamiento) del Web ERP
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = local.effective_ami_id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [aws_security_group.web.id]

  # Bootstrap del Web ERP (si se usa AMI base). Con AMI personalizada
  # el servicio ya viene instalado y este user-data solo lo arranca.
  user_data = base64encode(file("${path.module}/../../scripts/userdata-web.sh"))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-web" }
  }
}

# Auto Scaling Group: instancias en SUBREDES PRIVADAS, expuestas vía ALB
resource "aws_autoscaling_group" "web" {
  name                      = "${var.project_name}-asg"
  min_size                  = var.asg_min
  desired_capacity          = var.asg_desired
  max_size                  = var.asg_max
  vpc_zone_identifier       = aws_subnet.private[*].id
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Política de escalado por seguimiento de objetivo (Target Tracking) sobre CPU.
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.project_name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_high_threshold
  }
}
