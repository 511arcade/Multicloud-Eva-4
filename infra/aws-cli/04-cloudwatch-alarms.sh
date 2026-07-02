#!/bin/bash
# =====================================================================
# 04 - Alarmas de Amazon CloudWatch (CPU alta -> out / CPU baja -> in)
# =====================================================================
set -euo pipefail
source .env-ids

# Política scale-out (+1)
OUT_ARN=$(aws autoscaling put-scaling-policy \
  --auto-scaling-group-name "$ASG_NAME" \
  --policy-name "${PROJECT}-scale-out" \
  --scaling-adjustment 1 --adjustment-type ChangeInCapacity --cooldown 120 \
  --region "$REGION" --query 'PolicyARN' --output text)

# Política scale-in (-1)
IN_ARN=$(aws autoscaling put-scaling-policy \
  --auto-scaling-group-name "$ASG_NAME" \
  --policy-name "${PROJECT}-scale-in" \
  --scaling-adjustment -1 --adjustment-type ChangeInCapacity --cooldown 300 \
  --region "$REGION" --query 'PolicyARN' --output text)

# Alarma CPU ALTA
aws cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT}-cpu-high" \
  --alarm-description "CPU alta: escalar hacia afuera" \
  --namespace "AWS/EC2" --metric-name CPUUtilization --statistic Average \
  --period 60 --evaluation-periods 2 --threshold 60 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --dimensions "Name=AutoScalingGroupName,Value=$ASG_NAME" \
  --alarm-actions "$OUT_ARN" --region "$REGION"

# Alarma CPU BAJA
aws cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT}-cpu-low" \
  --alarm-description "CPU baja: escalar hacia adentro (terminacion)" \
  --namespace "AWS/EC2" --metric-name CPUUtilization --statistic Average \
  --period 60 --evaluation-periods 3 --threshold 20 \
  --comparison-operator LessThanOrEqualToThreshold \
  --dimensions "Name=AutoScalingGroupName,Value=$ASG_NAME" \
  --alarm-actions "$IN_ARN" --region "$REGION"

echo "Alarmas CloudWatch creadas: ${PROJECT}-cpu-high y ${PROJECT}-cpu-low"
