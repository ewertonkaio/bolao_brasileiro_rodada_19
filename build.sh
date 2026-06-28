#!/usr/bin/env bash
# Gera config.js a partir das variáveis de ambiente definidas no Netlify.
# As chaves NÃO ficam no repositório — só são injetadas no momento do deploy.
set -e

cat > config.js <<EOF
window.BOLAO_CONFIG = {
  SUPABASE_URL: "${SUPABASE_URL}",
  SUPABASE_ANON_KEY: "${SUPABASE_ANON_KEY}",
  RESULTS_PASSWORD: "${RESULTS_PASSWORD}",
  ENTRY_FEE: "${ENTRY_FEE:-10}"
};
EOF

echo "config.js gerado com sucesso."
