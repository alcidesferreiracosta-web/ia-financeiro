/**
 * Ativa testadores DIRETAMENTE em usuarios/{uid} via Firebase Admin.
 *
 * Como rodar:
 *   1. Tenha Node.js instalado
 *   2. npm install  (na raiz do projeto)
 *   3. Exporte as credenciais:
 *        set GOOGLE_APPLICATION_CREDENTIALS=C:\caminho\para\serviceAccount.json
 *      ou faça login com:
 *        firebase login
 *        node -e "require('firebase-admin').initializeApp()"
 *   4. node ativar_direto.js
 *
 * Como obter o serviceAccount.json:
 *   Firebase Console > Configurações do projeto > Contas de serviço > Gerar nova chave privada
 */

const admin = require('firebase-admin');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

// ── Credenciais ─────────────────────────────────────────────────────────────
// Se GOOGLE_APPLICATION_CREDENTIALS não estiver definida, tente a chave local
try {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    admin.initializeApp();
  } else {
    // Tenta carregar automaticamente do Firebase Tools (firebase login)
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: 'i-a-financeiro-hq2c4c',
    });
  }
} catch (e) {
  console.error('❌ Erro ao inicializar Firebase Admin:', e.message);
  console.log('\nPrecisa de credenciais. Opções:');
  console.log('  1. Baixe o serviceAccount.json no Firebase Console > Configurações > Contas de serviço');
  console.log('  2. Defina: set GOOGLE_APPLICATION_CREDENTIALS=C:\\caminho\\serviceAccount.json');
  console.log('  3. Execute: npx firebase-tools login e npx firebase-tools open');
  process.exit(1);
}

const auth = getAuth();
const db = getFirestore();

// ── Lista de emails a ativar ─────────────────────────────────────────────────
const emails = [
  'ivancouto555@gmail.com',
  'rosangelaestevescouto@gmail.com',
  'pedro.couto.ferreiraa@gmail.com',
  'estevisdany@gmail.com',
  'alcidesferreira.costa21@gmail.com',
  'soepestore@gmail.com',
  'sheyla.sophia.pedro@gmail.com',
  'edmilson777queiroz@gmail.com',
  'alcidesferreira.costa@hotmail.com',
];

const DIAS = 30;

async function ativarEmail(email) {
  try {
    // Busca o UID pelo email
    const user = await auth.getUserByEmail(email);
    const uid = user.uid;

    const premiumUntil = new Date();
    premiumUntil.setDate(premiumUntil.getDate() + DIAS);

    // Escreve direto em usuarios/{uid}
    await db.collection('usuarios').doc(uid).set({
      premium: true,
      premium_until: Timestamp.fromDate(premiumUntil),
      hotmart_email: email,
      testador: true,
      updated_at: Timestamp.now(),
    }, { merge: true });

    // Remove entrada pendente se existir
    await db.collection('pending_activations').doc(email).delete().catch(() => {});

    console.log(`✅ ${email} (uid: ${uid}) — premium até ${premiumUntil.toLocaleDateString('pt-BR')}`);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      console.log(`⚠️  ${email} — ainda não criou conta no app`);
      // Cria pending para quando criar a conta
      const premiumUntil = new Date();
      premiumUntil.setDate(premiumUntil.getDate() + DIAS);
      await db.collection('pending_activations').doc(email).set({
        premium: true,
        premium_until: Timestamp.fromDate(premiumUntil),
        created_at: Timestamp.now(),
      });
      console.log(`   → Pending criada. Será ativado automaticamente no 1º login.`);
    } else {
      console.error(`❌ ${email} — ${e.message}`);
    }
  }
}

async function main() {
  console.log(`\n🚀 Ativando ${emails.length} testadores por ${DIAS} dias...\n`);
  for (const email of emails) {
    await ativarEmail(email);
  }
  console.log('\n✨ Concluído!');
  process.exit(0);
}

main().catch(e => {
  console.error('Erro fatal:', e);
  process.exit(1);
});
