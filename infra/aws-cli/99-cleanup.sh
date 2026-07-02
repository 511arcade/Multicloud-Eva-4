#!/bin/bash
# =====================================================================
# 99 - Limpieza de recursos (ejecutar al finalizar la demo)
# =====================================================================
set -uo pipefail
source .env-ids

echo "Eliminando alarmas CloudWatch..."
aws cloudwatch delete-alarms --alarm-names "${PROJECT}-cpu-high" "${PROJECT}-cpu-low" --region "$REGION" || true

echo "Eliminando Auto Scaling Group (forzado)..."
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "$ASG_NAME" --force-delete --region "$REGION" || true
sleep 30

echo "Eliminando listener, ALB y target group..."
aws elbv2 delete-listener --listener-arn "${LISTENER_ARN:-}" --region "$REGION" || true
aws elbv2 delete-load-balancer --load-balancer-arn "${ALB_ARN:-}" --region "$REGION" || true
sleep 20
aws elbv2 delete-target-group --target-group-arn "${TG_ARN:-}" --region "$REGION" || true

echo "Eliminando Launch Template..."
aws ec2 delete-launch-template --launch-template-id "${LT_ID:-}" --region "$REGION" || true

echo "NOTA: elimina manualmente NAT Gateway, EIP, subredes, SGs y VPC si es necesario,"
echo "o usa Terraform destroy si desplegaste con Terraform."
