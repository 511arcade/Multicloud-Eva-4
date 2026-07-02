# Despliegue con Terraform

Crea toda la infraestructura de la maqueta funcional: VPC con subredes públicas/privadas,
Security Groups por capa, **Application Load Balancer**, **Launch Template + Auto Scaling Group**
(min 1 / desired 4 / max 8), **alarmas CloudWatch** y **bucket S3** con ACL.

## Pasos

```bash
cd infra/terraform

# 1) Configura AWS CLI con las credenciales del Lab
aws configure   # o exporta AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN

# 2) Prepara variables
cp terraform.tfvars.example terraform.tfvars
#   Edita terraform.tfvars (región, key_name, ami_id si tienes AMI propia)

# 3) Inicializa y aplica
terraform init
terraform plan
terraform apply

# 4) Obtén el DNS del balanceador
terraform output alb_dns_name
```

Abre en el navegador `http://<alb_dns_name>` para acceder al Web ERP.

## Notas importantes (AWS Academy Learner Lab)

- El Learner Lab **no permite crear roles IAM nuevos**; usa el rol `LabRole` ya existente si el
  Launch Template requiere un instance profile.
- El NAT Gateway tiene costo por hora; si el presupuesto es ajustado, puedes colocar el ASG en
  subredes **públicas** (ajustando `vpc_zone_identifier`) para evitarlo, a costa de menor aislamiento.
- Para usar tu **AMI personalizada** (requerimiento #5), créala desde la consola (ver
  `docs/04-instrucciones-consola-aws.md` §5) y pon su ID en `ami_id`.

## Destruir

```bash
terraform destroy
```
