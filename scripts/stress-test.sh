#!/bin/bash
# =====================================================================
# Benchmarking / prueba de estrés para EVIDENCIAR el Auto Scaling.
# Genera carga de CPU en las instancias detrás del ALB hasta superar
# el umbral definido en la política de escalado (ej. CPU > 60%).
#
# Uso:
#   ./stress-test.sh http://<DNS-DEL-ALB> [concurrencia] [segundos]
# Ejemplo:
#   ./stress-test.sh http://cruz-azul-erp-alb-123.elb.amazonaws.com 50 300
# =====================================================================
set -euo pipefail

ALB_URL="${1:-http://localhost:3000}"
CONCURRENCY="${2:-50}"
DURATION="${3:-300}"   # segundos
EMAIL="${EMAIL:-admin@cruzazul.cl}"
PASSWORD="${PASSWORD:-Admin123!}"

echo "Objetivo:      $ALB_URL"
echo "Concurrencia:  $CONCURRENCY peticiones simultáneas"
echo "Duración:      $DURATION s"

# Autenticarse para obtener un token (el endpoint que quema CPU está protegido).
echo "Autenticando como $EMAIL para obtener token..."
TOKEN=$(curl -s -c - -o /dev/null -X POST "$ALB_URL/login" \
  --data-urlencode "email=$EMAIL" --data-urlencode "password=$PASSWORD" \
  | awk '/token/ {print $NF}' | tail -n1)

if [ -n "$TOKEN" ]; then
  echo "Token obtenido. Se golpeará /erp/api/cpu-load (carga real de CPU)."
else
  echo "No se pudo obtener token; se golpeará solo tráfico HTTP básico."
fi

END=$(( $(date +%s) + DURATION ))

worker() {
  while [ "$(date +%s)" -lt "$END" ]; do
    if [ -n "$TOKEN" ]; then
      # Endpoint que consume CPU intensamente para disparar el scale-out
      curl -s -o /dev/null -H "Authorization: Bearer $TOKEN" \
        "$ALB_URL/erp/api/cpu-load?ms=8000" || true
    fi
    curl -s -o /dev/null "$ALB_URL/health" || true
    curl -s -o /dev/null "$ALB_URL/" || true
  done
}

# Alternativa recomendada si tienes 'ab' (apache-bench) o 'hey' instalado:
#   ab -n 100000 -c "$CONCURRENCY" "$ALB_URL/health"
#   hey -z "${DURATION}s" -c "$CONCURRENCY" "$ALB_URL/health"

for i in $(seq 1 "$CONCURRENCY"); do
  worker &
done
wait

echo "Prueba de estrés finalizada. Revisa CloudWatch para ver el escalado (scale-out)."
echo "Cuando la carga baje, el ASG debe realizar scale-in (terminación de recursos)."
