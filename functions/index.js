const { onRequest, onCall } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ region: 'us-central1' });

const GROQ_API_KEY = process.env.GROQ_API_KEY;
const GROQ_MODEL = 'llama-3.3-70b-versatile';

async function chamarGroq(messages, maxTokens = 900) {
  const resp = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${GROQ_API_KEY}`,
    },
    body: JSON.stringify({ model: GROQ_MODEL, messages, max_tokens: maxTokens, temperature: 0.7 }),
  });
  if (!resp.ok) throw new Error(`Groq ${resp.status}: ${await resp.text()}`);
  const data = await resp.json();
  return data.choices[0].message.content;
}

async function getDadosUsuario(uid) {
  const db = admin.firestore();
  const [ganhosSnap, gastosSnap] = await Promise.all([
    db.collection('ganhos').where('userId', '==', uid).get(),
    db.collection('gastos').where('userId', '==', uid).get(),
  ]);
  const ganhos = ganhosSnap.docs.map(d => d.data());
  const gastos = gastosSnap.docs.map(d => d.data());
  const totalGanhos = ganhos.reduce((s, g) => s + (Number(g.valor) || 0), 0);
  const totalGastos = gastos.reduce((s, g) => s + (Number(g.valor) || 0), 0);
  const categorias = {};
  for (const g of gastos) {
    const cat = g.categoria || 'Outros';
    categorias[cat] = (categorias[cat] || 0) + (Number(g.valor) || 0);
  }
  return { totalGanhos, totalGastos, saldo: totalGanhos - totalGastos, categorias };
}

exports.chatFinanceiro = onCall({ region: 'us-central1' }, async (request) => {
  const { pergunta, uid } = request.data;
  if (!pergunta || !uid) throw new Error('Parâmetros inválidos');

  const dados = await getDadosUsuario(uid);
  const cats = Object.entries(dados.categorias)
    .map(([k, v]) => `${k}: R$ ${v.toFixed(2)}`).join(', ') || 'Nenhum gasto registrado';

  const sistema = `Você é a FinanceIA, assistente financeira pessoal e inteligente.
Dados financeiros do usuário:
- Ganhos totais: R$ ${dados.totalGanhos.toFixed(2)}
- Gastos totais: R$ ${dados.totalGastos.toFixed(2)}
- Saldo atual: R$ ${dados.saldo.toFixed(2)}
- Gastos por categoria: ${cats}

Responda em português brasileiro de forma direta e prática. Máximo 3 parágrafos curtos.`;

  const resposta = await chamarGroq([
    { role: 'system', content: sistema },
    { role: 'user', content: pergunta },
  ]);

  return { resposta };
});

exports.dicasFinanceiras = onCall({ region: 'us-central1' }, async (request) => {
  const { uid } = request.data;
  if (!uid) throw new Error('UID não informado');

  const dados = await getDadosUsuario(uid);
  const cats = Object.entries(dados.categorias)
    .map(([k, v]) => `${k}: R$ ${v.toFixed(2)}`).join(', ') || 'Sem gastos registrados';

  const prompt = `Analise os dados financeiros e gere 4 dicas personalizadas em JSON.

Dados:
- Ganhos: R$ ${dados.totalGanhos.toFixed(2)}
- Gastos: R$ ${dados.totalGastos.toFixed(2)}
- Saldo: R$ ${dados.saldo.toFixed(2)}
- Categorias: ${cats}

Retorne APENAS JSON válido neste formato, sem texto adicional:
{"resumo":"frase curta sobre a situação","dicas":[{"titulo":"título curto","descricao":"1-2 frases práticas","tipo":"dica|alerta|conquista|meta","prioridade":"alta|media|baixa"}]}`;

  const raw = await chamarGroq([{ role: 'user', content: prompt }], 1000);

  let parsed;
  try {
    const match = raw.match(/\{[\s\S]*\}/);
    parsed = JSON.parse(match ? match[0] : raw);
  } catch {
    parsed = {
      resumo: 'Adicione seus ganhos e gastos para uma análise personalizada.',
      dicas: [
        { titulo: 'Registre seus ganhos', descricao: 'Adicione sua renda mensal para ter um panorama completo.', tipo: 'dica', prioridade: 'alta' },
        { titulo: 'Registre seus gastos', descricao: 'Categorize seus gastos para entender para onde vai seu dinheiro.', tipo: 'dica', prioridade: 'alta' },
      ],
    };
  }

  return {
    ganhos: dados.totalGanhos,
    gastos: dados.totalGastos,
    saldo: dados.saldo,
    resumo: parsed.resumo || '',
    dicas: (parsed.dicas || []).slice(0, 6),
  };
});

const ACTIVATE_EVENTS = new Set([
  'PURCHASE_APPROVED',
  'PURCHASE_COMPLETE',
  'SUBSCRIPTION_REACTIVATED',
]);

const DEACTIVATE_EVENTS = new Set([
  'PURCHASE_REFUNDED',
  'SUBSCRIPTION_CANCELLATION',
  'PURCHASE_EXPIRED',
  'PURCHASE_CANCELED',
  'PURCHASE_CHARGEBACK',
]);

// Roda a cada 30 minutos — desativa promoções expiradas
exports.expirarPromocoes = onSchedule('every 30 minutes', async () => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const snap = await db.collection('promocoes')
    .where('ativa', '==', true)
    .where('expiracao', '<=', now)
    .limit(200)
    .get();

  if (snap.empty) return;

  const batch = db.batch();
  snap.docs.forEach((doc) => {
    batch.update(doc.ref, { ativa: false });
  });
  await batch.commit();
  console.log(`Expiradas ${snap.size} promoções`);
});

// Webhook chamado pelo Hotmart ao confirmar/cancelar pagamento
exports.hotmartWebhook = onRequest({ cors: false }, async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  const body = req.body;
  const event = body?.event;
  const buyerEmail = body?.data?.buyer?.email?.toLowerCase()?.trim();

  if (!event || !buyerEmail) {
    return res.status(400).json({ error: 'Missing event or buyer email' });
  }

  const db = admin.firestore();

  try {
    let uid = null;
    try {
      const userRecord = await admin.auth().getUserByEmail(buyerEmail);
      uid = userRecord.uid;
    } catch (authErr) {
      if (authErr.code !== 'auth/user-not-found') throw authErr;
    }

    if (uid) {
      const userRef = db.collection('usuarios').doc(uid);

      if (ACTIVATE_EVENTS.has(event)) {
        const premiumUntil = new Date();
        premiumUntil.setDate(premiumUntil.getDate() + 35);
        await userRef.set({
          premium: true,
          premium_until: admin.firestore.Timestamp.fromDate(premiumUntil),
          hotmart_email: buyerEmail,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      } else if (DEACTIVATE_EVENTS.has(event)) {
        await userRef.set({
          premium: false,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    } else {
      // Usuário pagou mas ainda não criou conta — salva para ativar no primeiro login
      if (ACTIVATE_EVENTS.has(event) || DEACTIVATE_EVENTS.has(event)) {
        await db.collection('pending_activations').doc(buyerEmail).set({
          email: buyerEmail,
          event,
          premium: ACTIVATE_EVENTS.has(event),
          created_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    return res.status(200).json({ success: true, event, email: buyerEmail });
  } catch (err) {
    console.error('hotmartWebhook error:', err);
    return res.status(500).json({ error: err.message });
  }
});
