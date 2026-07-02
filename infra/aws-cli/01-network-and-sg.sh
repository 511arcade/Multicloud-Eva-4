#!/bin/bash
# =====================================================================
# 01 - Red (VPC, subredes públicas/privadas, IGW, NAT) + Security Groups
# =====================================================================
set -euo pipefail

PROJECT="cruz-azul-erp"
REGION="${AWS_REGION:-us-east-1}"
VPC_CIDR="10.0.0.0/16"
IDS_FILE=".env-ids"

echo "Región: $REGION"

# VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block "$VPC_CIDR" --region "$REGION" \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT}-vpc}]" \
  --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames --region "$REGION"
echo "VPC: $VPC_ID"

# AZs
AZ1=$(aws ec2 describe-availability-zones --region "$REGION" --query 'AvailabilityZones[0].ZoneName' --output text)
AZ2=$(aws ec2 describe-availability-zones --region "$REGION" --query 'AvailabilityZones[1].ZoneName' --output text)

# Subredes públicas
PUB1=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "10.0.0.0/24" --availability-zone "$AZ1" \
  --region "$REGION" --query 'Subnet.SubnetId' --output text)
PUB2=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "10.0.1.0/24" --availability-zone "$AZ2" \
  --region "$REGION" --query 'Subnet.SubnetId' --output text)
aws ec2 modify-subnet-attribute --subnet-id "$PUB1" --map-public-ip-on-launch --region "$REGION"
aws ec2 modify-subnet-attribute --subnet-id "$PUB2" --map-public-ip-on-launch --region "$REGION"

# Subredes privadas
PRIV1=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "10.0.10.0/24" --availability-zone "$AZ1" \
  --region "$REGION" --query 'Subnet.SubnetId' --output text)
PRIV2=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "10.0.11.0/24" --availability-zone "$AZ2" \
  --region "$REGION" --query 'Subnet.SubnetId' --output text)
echo "Subredes públicas: $PUB1 $PUB2 | privadas: $PRIV1 $PRIV2"

# Internet Gateway
IGW=$(aws ec2 create-internet-gateway --region "$REGION" --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC_ID" --region "$REGION"

# NAT Gateway (para salida de subredes privadas)
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --region "$REGION" --query 'AllocationId' --output text)
NAT=$(aws ec2 create-nat-gateway --subnet-id "$PUB1" --allocation-id "$EIP_ALLOC" --region "$REGION" \
  --query 'NatGateway.NatGatewayId' --output text)
echo "Esperando a que el NAT Gateway esté disponible..."
aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT" --region "$REGION"

# Route table pública
RT_PUB=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --region "$REGION" --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id "$RT_PUB" --destination-cidr-block "0.0.0.0/0" --gateway-id "$IGW" --region "$REGION"
aws ec2 associate-route-table --route-table-id "$RT_PUB" --subnet-id "$PUB1" --region "$REGION"
aws ec2 associate-route-table --route-table-id "$RT_PUB" --subnet-id "$PUB2" --region "$REGION"

# Route table privada
RT_PRIV=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --region "$REGION" --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id "$RT_PRIV" --destination-cidr-block "0.0.0.0/0" --nat-gateway-id "$NAT" --region "$REGION"
aws ec2 associate-route-table --route-table-id "$RT_PRIV" --subnet-id "$PRIV1" --region "$REGION"
aws ec2 associate-route-table --route-table-id "$RT_PRIV" --subnet-id "$PRIV2" --region "$REGION"

# Security Groups
SG_ALB=$(aws ec2 create-security-group --group-name "${PROJECT}-sg-alb" --description "ALB" \
  --vpc-id "$VPC_ID" --region "$REGION" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG_ALB" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$REGION"
aws ec2 authorize-security-group-ingress --group-id "$SG_ALB" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "$REGION"

SG_WEB=$(aws ec2 create-security-group --group-name "${PROJECT}-sg-web" --description "Web ERP" \
  --vpc-id "$VPC_ID" --region "$REGION" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG_WEB" --protocol tcp --port 3000 \
  --source-group "$SG_ALB" --region "$REGION"

SG_DB=$(aws ec2 create-security-group --group-name "${PROJECT}-sg-db" --description "PostgreSQL" \
  --vpc-id "$VPC_ID" --region "$REGION" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG_DB" --protocol tcp --port 5432 \
  --source-group "$SG_WEB" --region "$REGION"

# Guardar IDs
cat > "$IDS_FILE" <<EOF
REGION=$REGION
PROJECT=$PROJECT
VPC_ID=$VPC_ID
PUB1=$PUB1
PUB2=$PUB2
PRIV1=$PRIV1
PRIV2=$PRIV2
SG_ALB=$SG_ALB
SG_WEB=$SG_WEB
SG_DB=$SG_DB
EOF

echo "Red y Security Groups creados. IDs guardados en $IDS_FILE"
