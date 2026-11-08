#!/usr/bin/env bash
# Prueba rápida de la API (ejecútala en el servidor):  bash deploy/smoke_test.sh [http://localhost]
BASE="${1:-http://localhost}"; JAR="$(mktemp)"; ok=0; bad=0
chk() { if [ "$2" = "$3" ]; then echo "  ✔ $1"; ok=$((ok+1)); else echo "  ✘ $1 (esperado $3, obtuvo $2)"; bad=$((bad+1)); fi; }
TOKEN=$(curl -s -c "$JAR" "$BASE/api/auth/csrf/" | sed -E 's/.*"csrfToken":"([^"]+)".*/\1/')
H=(-b "$JAR" -c "$JAR" -H "Content-Type: application/json" -H "X-CSRFToken: $TOKEN")
code() { curl -s -o /dev/null -w "%{http_code}" "$@"; }
chk "API raíz"                    "$(code "$BASE/api/")" 200
chk "Sin sesión -> 401"           "$(code "${H[@]}" "$BASE/api/products/")" 401
chk "Login incorrecto -> 401"     "$(code "${H[@]}" -X POST -d '{"email":"x@x.com","password":"mal"}' "$BASE/api/auth/login/")" 401
chk "Login correcto"              "$(code "${H[@]}" -X POST -d '{"email":"ana@novacomercial.mx","password":"Nexo2026Demo"}' "$BASE/api/auth/login/")" 200
chk "Sesión activa"               "$(code "${H[@]}" "$BASE/api/auth/session/")" 200
chk "Productos"                   "$(code "${H[@]}" "$BASE/api/products/")" 200
chk "Categorías"                  "$(code "${H[@]}" "$BASE/api/categories/")" 200
chk "Clientes"                    "$(code "${H[@]}" "$BASE/api/clients/")" 200
chk "Ventas"                      "$(code "${H[@]}" "$BASE/api/sales/")" 200
chk "Usuarios (admin)"            "$(code "${H[@]}" "$BASE/api/users/")" 200
chk "POST sin CSRF -> 403"        "$(code -b "$JAR" -H "Content-Type: application/json" -X POST -d '{}' "$BASE/api/auth/logout/")" 403
chk "Logout"                      "$(code "${H[@]}" -X POST "$BASE/api/auth/logout/")" 200
rm -f "$JAR"; echo "Resultado: $ok correctas, $bad con error"; [ "$bad" -eq 0 ]
