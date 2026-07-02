# Despliegue paso a paso con AWS CLI (AWS Academy Lab)

Alternativa manual a Terraform, pensada para el **AWS Academy Learner Lab**. Ejecuta los scripts
en orden. Cada script guarda IDs en `infra/aws-cli/.env-ids` para que el siguiente los reutilice.

```bash
cd infra/aws-cli

# 0) Configura credenciales del Lab (Access Key + Session Token)
aws configure
# Pega también aws_session_token con: aws configure set aws_session_token <TOKEN>

# 1) Red, subredes, IGW, NAT y Security Groups
bash 01-network-and-sg.sh

# 2) Launch Template + Target Group + ALB
bash 02-alb-and-launch-template.sh

# 3) Auto Scaling Group (min 1 / desired 4 / max 8) + políticas
bash 03-autoscaling.sh

# 4) Alarmas CloudWatch (CPU alta/baja)
bash 04-cloudwatch-alarms.sh
```

Al terminar, obtén el DNS del ALB:

```bash
source .env-ids
aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" \
  --query 'LoadBalancers[0].DNSName' --output text
```

> Tareas que **deben** hacerse en la consola (crear AMI desde instancias en ejecución, capturas de
> evidencia, seguimiento visual del balanceo): ver `docs/04-instrucciones-consola-aws.md`.

Para eliminar recursos al final:

```bash
bash 99-cleanup.sh
```
