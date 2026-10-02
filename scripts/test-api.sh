#!/usr/bin/env bash
# Prueba los endpoints de la API con curl.
# Uso:  ./scripts/test-api.sh                       (local, http://localhost:8080)
#       ./scripts/test-api.sh http://<IP-PUBLICA>:8080   (AWS)
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
SUFFIX=$(date +%s)   # correos distintos en cada ejecución (la API rechaza duplicados)

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

step "Esperando a que la API esté lista (máx. 60 s)"
for i in $(seq 1 30); do
  if curl -sf "$BASE_URL/actuator/health" >/dev/null 2>&1; then
    echo "API lista tras ~$((i * 2)) s"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "La API no respondió en $BASE_URL. Revisa: docker logs students-api" >&2
    exit 1
  fi
  sleep 2
done

step "Health check: GET /actuator/health"
curl -sS "$BASE_URL/actuator/health"; echo

step "Crear estudiante: POST /students"
RESPONSE=$(curl -sS -i -X POST "$BASE_URL/students" \
  -H "Content-Type: application/json" \
  -d "{\"nombre\":\"Ana\",\"apellido\":\"Gómez\",\"correo\":\"ana.$SUFFIX@unisalle.edu.co\"}")
echo "$RESPONSE"
ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

step "Crear segundo estudiante: POST /students"
curl -sS -X POST "$BASE_URL/students" \
  -H "Content-Type: application/json" \
  -d "{\"nombre\":\"Luis\",\"apellido\":\"Pérez\",\"correo\":\"luis.$SUFFIX@unisalle.edu.co\"}"; echo

step "Obtener por id: GET /students/$ID"
curl -sS -i "$BASE_URL/students/$ID"; echo

step "Listar todos: GET /students"
curl -sS "$BASE_URL/students"; echo

step "Error 400 - datos inválidos"
curl -sS -i -X POST "$BASE_URL/students" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"","apellido":"Gómez","correo":"no-es-correo"}'; echo

step "Error 404 - id inexistente"
curl -sS -i "$BASE_URL/students/00000000-0000-0000-0000-000000000000"; echo