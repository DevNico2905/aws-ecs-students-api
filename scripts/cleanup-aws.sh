#!/usr/bin/env bash
# Elimina los recursos creados para no consumir créditos del Learner Lab.
set -uo pipefail
REGION="${AWS_REGION:-us-east-1}"
export AWS_DEFAULT_REGION="$REGION"

aws ecs update-service --cluster students-cluster --service students-api-service --desired-count 0 >/dev/null
aws ecs delete-service --cluster students-cluster --service students-api-service --force >/dev/null
aws ecs wait services-inactive --cluster students-cluster --services students-api-service
aws ecs delete-cluster --cluster students-cluster >/dev/null
aws ecr delete-repository --repository-name students-api --force >/dev/null
SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=students-api-sg --query 'SecurityGroups[0].GroupId' --output text)
[ "$SG_ID" != "None" ] && aws ec2 delete-security-group --group-id "$SG_ID"
echo "Recursos eliminados."
