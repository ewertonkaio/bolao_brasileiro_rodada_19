// netlify/functions/webhook-mp.js
// Recebe a notificação do Mercado Pago quando um pagamento muda de status.
// Se foi aprovado, marca o jogador como pago no Supabase.
//
// IMPORTANTE: a notificação só traz o ID do pagamento. Nós consultamos o MP
// de volta (com o token secreto) para confirmar o status de verdade — assim
// ninguém consegue forjar uma confirmação chamando este endpoint.

export const handler = async (event) => {
  // o MP espera um 200 rápido; respondemos ok mesmo em ruído
  if (event.httpMethod !== 'POST') return { statusCode: 200, body: 'ok' };

  const TOKEN = process.env.MP_ACCESS_TOKEN;
  const SB_URL = process.env.SUPABASE_URL;
  const SB_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;
  if (!TOKEN || !SB_URL || !SB_KEY) return { statusCode: 200, body: 'config incompleta' };

  let payload = {};
  try { payload = JSON.parse(event.body || '{}'); } catch { /* segue */ }

  // O MP manda o id de várias formas dependendo do evento
  const params = event.queryStringParameters || {};
  const paymentId =
    (payload.data && payload.data.id) ||
    params['data.id'] ||
    params.id ||
    (payload.resource && String(payload.resource).split('/').pop());

  const topic = payload.type || params.topic || params.type;
  if (topic && topic !== 'payment') return { statusCode: 200, body: 'ignorado' };
  if (!paymentId) return { statusCode: 200, body: 'sem id' };

  try {
    // consulta o pagamento real no MP
    const res = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
      headers: { 'Authorization': `Bearer ${TOKEN}` },
    });
    const pay = await res.json();
    if (!res.ok) return { statusCode: 200, body: 'pagamento não encontrado' };

    const player = pay.external_reference || (pay.metadata && pay.metadata.player);
    if (pay.status === 'approved' && player) {
      // marca como pago no Supabase via REST (upsert)
      await fetch(`${SB_URL}/rest/v1/pagamentos`, {
        method: 'POST',
        headers: {
          'apikey': SB_KEY,
          'Authorization': `Bearer ${SB_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: JSON.stringify({ nome: player, pago: true }),
      });
    }
    return { statusCode: 200, body: 'ok' };
  } catch (e) {
    return { statusCode: 200, body: 'erro tratado' };
  }
};
