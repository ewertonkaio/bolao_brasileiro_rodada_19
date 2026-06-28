#!/usr/bin/env bash
# Gera config.js a partir das variaveis de ambiente definidas no Netlify.
# As chaves NAO ficam no repositorio - sao injetadas no momento do deploy.
set -e

echo "[build] iniciando geracao do config.js"

if [ -z "${SUPABASE_URL}" ]; then
  echo "[build] AVISO: SUPABASE_URL nao definida nas Environment variables do Netlify"
fi
if [ -z "${SUPABASE_ANON_KEY}" ]; then
  echo "[build] AVISO: SUPABASE_ANON_KEY nao definida nas Environment variables do Netlify"
fi

cat > config.js <<CONFIGEOF
window.BOLAO_CONFIG = {
  SUPABASE_URL: "${SUPABASE_URL}",
  SUPABASE_ANON_KEY: "${SUPABASE_ANON_KEY}",
  RESULTS_PASSWORD: "${RESULTS_PASSWORD}",
  ENTRY_FEE: "${ENTRY_FEE:-10}"
};
CONFIGEOF

echo "[build] config.js gerado com sucesso."
