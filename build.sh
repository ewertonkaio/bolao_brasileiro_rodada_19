// netlify/functions/criar-pagamento.js
// Cria uma cobrança Pix dinâmica no Mercado Pago e devolve o QR + copia-e-cola.
// O Access Token fica SÓ aqui no servidor — nunca chega ao navegador.

exports.handler = async (event) => {
  const cors = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  if (event.httpMethod === 'OPTIONS') return { statusCode: 204, headers: cors, body: '' };
  if (event.httpMethod !== 'POST') return { statusCode: 405, headers: cors, body: 'Method not allowed' };

  const TOKEN = process.env.MP_ACCESS_TOKEN;
  const FEE = parseFloat(process.env.ENTRY_FEE || '10');
  if (!TOKEN) {
    return { statusCode: 500, headers: cors, body: JSON.stringify({ error: 'MP_ACCESS_TOKEN não configurado' }) };
  }

  let body;
  try { body = JSON.parse(event.body || '{}'); }
  catch { return { statusCode: 400, headers: cors, body: JSON.stringify({ error: 'JSON inválido' }) }; }

  const player = (body.player || '').toString().trim().slice(0, 60);
  if (!player) {
    return { statusCode: 400, headers: cors, body: JSON.stringify({ error: 'Informe o nome do jogador' }) };
  }

  // base URL do site, para o webhook receber as notificações
  const siteUrl = process.env.URL || process.env.DEPLOY_PRIME_URL || '';

  const payment = {
    transaction_amount: FEE,
    description: 'Bolão Brasileirão — entrada',
    payment_method_id: 'pix',
    // guardamos o nome do jogador para o webhook saber quem pagou
    external_reference: player,
    metadata: { player },
    payer: { email: 'pagador-bolao@example.com', first_name: player.slice(0, 40) },
    notification_url: siteUrl ? `${siteUrl}/.netlify/functions/webhook-mp` : undefined,
  };

  try {
    const res = await fetch('https://api.mercadopago.com/v1/payments', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${TOKEN}`,
        'Content-Type': 'application/json',
        // chave de idempotência evita cobranças duplicadas em cliques repetidos
        'X-Idempotency-Key': `bolao-${player}-${Date.now()}`,
      },
      body: JSON.stringify(payment),
    });

    const data = await res.json();
    if (!res.ok) {
      return { statusCode: res.status, headers: cors, body: JSON.stringify({ error: data.message || 'Erro no Mercado Pago', detail: data }) };
    }

    const tx = data.point_of_interaction && data.point_of_interaction.transaction_data;
    return {
      statusCode: 200,
      headers: { ...cors, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: data.id,
        status: data.status,
        qr_base64: tx ? tx.qr_code_base64 : null, // imagem PNG do QR (base64)
        qr_code: tx ? tx.qr_code : null,           // texto copia-e-cola
        amount: FEE,
      }),
    };
  } catch (e) {
    return { statusCode: 500, headers: cors, body: JSON.stringify({ error: 'Falha ao falar com o Mercado Pago' }) };
  }
};
