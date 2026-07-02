#!/bin/bash
# =====================================================================
# 03 - Auto Scaling Group (min 1 / desired 4 / max 8) en subredes privadas
# =====================================================================
set -euo pipefail
source .env-ids

ASG_NAME="${PROJECT}-asg"

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name "$ASG_NAME" \
  --launch-template "LaunchTemplateId=$LT_ID,Version=\$Latest" \
  --min-size 1 --desired-capacity 4 --max-size 8 \
  --vpc-zone-identifier "${PRIV1},${PRIV2}" \
  --target-group-arns "$TG_ARN" \
  --health-check-type ELB --health-check-grace-period 120 \
  --region "$REGION"

echo "Auto Scaling Group '$ASG_NAME' creado (min 1 / desired 4 / max 8)."

# Política de escalado por seguimiento de objetivo (CPU 60%)
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name "$ASG_NAME" \
  --policy-name "${PROJECT}-cpu-target-tracking" \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "PredefinedMetricSpecification": {"PredefinedMetricType": "ASGAverageCPUUtilization"},
    "TargetValue": 60.0
  }' \
  --region "$REGION"

echo "ASG_NAME=$ASG_NAME" >> .env-ids
echo "Política de escalado (target tracking CPU 60%) aplicada."
