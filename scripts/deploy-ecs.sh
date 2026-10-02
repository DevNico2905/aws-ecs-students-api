#!/usr/bin/env bash
# Alternativa por CLI a los pasos de consola del README: crea cluster, task definition,
# security group y servicio Fargate con 1 tarea e IP pública. Ejecutar después de push-ecr.sh.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
CLUSTER="students-cluster"
SERVICE="students-api-service"
SG_NAME="students-api-sg"
TAG="${TAG:-1.0.0}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_DEFAULT_REGION="$REGION"

echo "==> Cluster ECS"
aws ecs create-cluster --cluster-name "$CLUSTER" >/dev/null

echo "==> Task definition (LabRole como execution role)"
sed -e "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" -e "s/<REGION>/$REGION/g" -e "s/<TAG>/$TAG/g" \
  ecs/task-definition.json > /tmp/students-taskdef.json
aws ecs register-task-definition --cli-input-json file:///tmp/students-taskdef.json >/dev/null

echo "==> Red: VPC por defecto y sus subnets"
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)
SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'Subnets[].SubnetId' --output text | tr '\t' ',')

echo "==> Security group (entrada TCP 8080)"
SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values="$SG_NAME" Name=vpc-id,Values="$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text)
if [ "$SG_ID" = "None" ]; then
  SG_ID=$(aws ec2 create-security-group --group-name "$SG_NAME" \
    --description "Acceso HTTP 8080 a students-api" --vpc-id "$VPC_ID" --query GroupId --output text)
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 8080 --cidr 0.0.0.0/0
fi

echo "==> Servicio Fargate (1 tarea)"
aws ecs create-service \
  --cluster "$CLUSTER" \
  --service-name "$SERVICE" \
  --task-definition students-api \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  >/dev/null

echo "==> Esperando a que el servicio esté estable (2-4 min)..."
aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE"

TASK_ARN=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --query 'taskArns[0]' --output text)
ENI_ID=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" \
  --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text)
PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI_ID" \
  --query 'NetworkInterfaces[0].Association.PublicIp' --output text)

echo "==> API desplegada en: http://$PUBLIC_IP:8080/students"
