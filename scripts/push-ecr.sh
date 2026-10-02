#!/usr/bin/env bash
# Construye la imagen para linux/amd64 y la sube a Amazon ECR.
# Requisito: credenciales del Learner Lab configuradas (aws sts get-caller-identity debe funcionar).
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
REPO="${ECR_REPO:-students-api}"
TAG="${TAG:-1.0.0}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
IMAGE="$REGISTRY/$REPO:$TAG"

echo "==> Cuenta: $ACCOUNT_ID | Región: $REGION | Imagen: $IMAGE"

echo "==> Creando repositorio ECR (si no existe)"
aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "$REPO" --region "$REGION" \
       --image-scanning-configuration scanOnPush=true >/dev/null

echo "==> Login de Docker en ECR"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

echo "==> Build (linux/amd64, la arquitectura de Fargate por defecto)"
docker build --platform linux/amd64 -t "$REPO:$TAG" .

echo "==> Tag y push"
docker tag "$REPO:$TAG" "$IMAGE"
docker push "$IMAGE"

echo "==> Listo. URI para la task definition:"
echo "$IMAGE"
