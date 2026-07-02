#!/bin/bash
# =====================================================================
# 02 - Launch Template + Target Group + Application Load Balancer
# =====================================================================
set -euo pipefail
source .env-ids

# AMI base: Amazon Linux 2023 (o reemplaza por tu AMI personalizada)
AMI_ID="${AMI_ID:-$(aws ssm get-parameters --names \
  /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --region "$REGION" --query 'Parameters[0].Value' --output text)}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"

echo "AMI: $AMI_ID  Tipo: $INSTANCE_TYPE"

# user-data en base64
USER_DATA_B64=$(base64 -w0 ../../scripts/userdata-web.sh 2>/dev/null || base64 ../../scripts/userdata-web.sh)

# Launch Template
LT_ID=$(aws ec2 create-launch-template \
  --launch-template-name "${PROJECT}-lt" \
  --region "$REGION" \
  --launch-template-data "{
    \"ImageId\":\"$AMI_ID\",
    \"InstanceType\":\"$INSTANCE_TYPE\",
    \"SecurityGroupIds\":[\"$SG_WEB\"],
    \"UserData\":\"$USER_DATA_B64\",
    \"TagSpecifications\":[{\"ResourceType\":\"instance\",\"Tags\":[{\"Key\":\"Name\",\"Value\":\"${PROJECT}-web\"}]}]
  }" \
  --query 'LaunchTemplate.LaunchTemplateId' --output text)
echo "Launch Template: $LT_ID"

# Target Group (health check /health)
TG_ARN=$(aws elbv2 create-target-group \
  --name "${PROJECT}-tg" --protocol HTTP --port 3000 --vpc-id "$VPC_ID" \
  --target-type instance --health-check-path "/health" --health-check-protocol HTTP \
  --matcher HttpCode=200 --region "$REGION" \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
echo "Target Group: $TG_ARN"

# ALB en subredes públicas
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name "${PROJECT}-alb" --type application --scheme internet-facing \
  --subnets "$PUB1" "$PUB2" --security-groups "$SG_ALB" --region "$REGION" \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
echo "ALB: $ALB_ARN"

aws elbv2 wait load-balancer-available --load-balancer-arns "$ALB_ARN" --region "$REGION"

# Listener :80 -> Target Group
LISTENER_ARN=$(aws elbv2 create-listener --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG_ARN" \
  --region "$REGION" --query 'Listeners[0].ListenerArn' --output text)

cat >> .env-ids <<EOF
AMI_ID=$AMI_ID
LT_ID=$LT_ID
TG_ARN=$TG_ARN
ALB_ARN=$ALB_ARN
LISTENER_ARN=$LISTENER_ARN
EOF

DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" \
  --region "$REGION" --query 'LoadBalancers[0].DNSName' --output text)
echo "ALB, Target Group y Launch Template creados."
echo "DNS del balanceador: http://$DNS"
