import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'score_page.dart';

const _redirectBase =
    'https://us-central1-i-a-financeiro-hq2c4c.cloudfunctions.net/redirectAfiliado';

// ─── Dados do veredicto da IA ────────────────────────────────────────────────
class _Veredicto {
  final String emoji, texto;
  final Color cor;
  const _Veredicto(this.emoji, this.texto, this.cor);
}

_Veredicto _iaVeredicto(double preco, double saldo, double ganhos) {
  if (saldo < 0) {
    return const _Veredicto('❌', 'Saldo negativo — evite compras agora', Colors.redAccent);
  }
  if (preco > saldo) {
    return const _Veredicto('❌', 'Preço supera seu saldo disponível', Colors.redAccent);
  }
  if (ganhos > 0) {
    final pct = preco / ganhos * 100;
    if (pct > 30) {
      return _Veredicto('⚠️',
          '${pct.toStringAsFixed(0)}% da renda mensal — impacto alto', Colors.orange);
    }
    if (pct > 10) {
      return _Veredicto('⚠️',
          '${pct.toStringAsFixed(0)}% da renda — avalie se é necessário', Colors.amber);
    }
    return _Veredicto('✅',
        '${pct.toStringAsFixed(0)}% da renda — dentro do orçamento', Colors.greenAccent);
  }
  return const _Veredicto(
      '⚠️', 'Registre sua renda para análise completa', Colors.orange);
}

// ─── Page ────────────────────────────────────────────────────────────────────
class OfertasPage extends StatefulWidget {
  const OfertasPage({super.key});
  @override
  State<OfertasPage> createState() => _OfertasPageState();
}

class _OfertasPageState extends State<OfertasPage> {
  late final String _uid;
  late final Stream<QuerySnapshot> _ganhosStream;
  late final Stream<QuerySnapshot> _gastosStream;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _ganhosStream = FirebaseFirestore.instance
        .collection('ganhos')
        .where('userId', isEqualTo: _uid)
        .snapshots();
    _gastosStream = FirebaseFirestore.instance
        .collection('gastos')
        .where('userId', isEqualTo: _uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Row(children: [
          Icon(Icons.shield_outlined, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Text('Ofertas Inteligentes',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ganhosStream,
        builder: (ctx, gSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: _gastosStream,
            builder: (ctx, eSnap) {
              double ganhos = 0, gastos = 0;
              if (gSnap.hasData) {
                ganhos = gSnap.data!.docs
                    .fold(0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
              }
              if (eSnap.hasData) {
                gastos = eSnap.data!.docs
                    .fold(0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
              }
              final saldo = ganhos - gastos;
              final score = ScorePage.calcScore(ganhos, gastos);

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ofertas')
                    .where('ativo', isEqualTo: true)
                    .snapshots(),
                builder: (ctx, ofSnap) {
                  if (ofSnap.hasError) {
                    return Center(
                        child: Text('Erro: ${ofSnap.error}',
                            style: const TextStyle(color: Colors.redAccent)));
                  }
                  if (!ofSnap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.orange));
                  }

                  final todos = List.of(ofSnap.data!.docs);

                  // Separa eBook de produtos ML
                  final ebooks = todos
                      .where((d) =>
                          (d.data() as Map)['plataforma'] == 'hotmart' ||
                          (d.data() as Map)['categoria'] == 'ebooks')
                      .toList();
                  final produtos = todos
                      .where((d) =>
                          (d.data() as Map)['plataforma'] != 'hotmart' &&
                          (d.data() as Map)['categoria'] != 'ebooks')
                      .toList()
                    ..sort((a, b) {
                      // Ordena por % de desconto
                      final ad = (a.data() as Map);
                      final bd = (b.data() as Map);
                      final aP = (ad['preco'] as num?)?.toDouble() ?? 0;
                      final aO = (ad['preco_original'] as num?)?.toDouble() ?? 1;
                      final bP = (bd['preco'] as num?)?.toDouble() ?? 0;
                      final bO = (bd['preco_original'] as num?)?.toDouble() ?? 1;
                      final aDisc = aO > 0 ? (aO - aP) / aO : 0;
                      final bDisc = bO > 0 ? (bO - bP) / bO : 0;
                      return bDisc.compareTo(aDisc);
                    });

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Snapshot financeiro
                      _FinancialSnapshot(
                          saldo: saldo, score: score, ganhos: ganhos, gastos: gastos),

                      const SizedBox(height: 14),

                      // Conselho da FinanceIA
                      _IaConselhoCard(saldo: saldo, ganhos: ganhos, gastos: gastos, score: score),

                      const SizedBox(height: 18),

                      // eBook seção
                      if (ebooks.isNotEmpty) ...[
                        const _SecaoHeader(
                            titulo: '📘 Aprenda e Ganhe Mais',
                            subtitulo: 'Conteúdo que transforma sua vida financeira'),
                        const SizedBox(height: 10),
                        ...ebooks.map((doc) => _EbookCard(doc: doc)),
                        const SizedBox(height: 18),
                      ],

                      // Ranking de produtos
                      if (produtos.isNotEmpty) ...[
                        const _SecaoHeader(
                            titulo: '🏆 Ranking de Promoções',
                            subtitulo: 'IA avalia se vale a pena pra você'),
                        const SizedBox(height: 10),
                        ...produtos.asMap().entries.map((e) => _CardOfertaInteligente(
                              doc: e.value,
                              ranking: e.key + 1,
                              saldo: saldo,
                              ganhos: ganhos,
                              gastos: gastos,
                              score: score,
                            )),
                      ] else ...[
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(children: [
                            Icon(Icons.search, color: Colors.white24, size: 40),
                            SizedBox(height: 10),
                            Text('Promoções chegando em breve',
                                style: TextStyle(color: Colors.white54)),
                            SizedBox(height: 4),
                            Text(
                                'A IA está selecionando as melhores ofertas\nconsiderant o seu perfil financeiro.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ]),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Snapshot financeiro ──────────────────────────────────────────────────────
class _FinancialSnapshot extends StatelessWidget {
  final double saldo, score, ganhos, gastos;
  const _FinancialSnapshot(
      {required this.saldo,
      required this.score,
      required this.ganhos,
      required this.gastos});

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final cor = ScorePage.corNivel(score.toInt());
    final saldoCor = saldo >= 0 ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('SEU SALDO',
                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
            Text(_fmt(saldo),
                style: TextStyle(
                    color: saldoCor, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
        ),
        Container(width: 1, height: 36, color: Colors.white12),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('SCORE FINANCEIRO',
                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
            Row(children: [
              Text('${score.toInt()}/100',
                  style: TextStyle(
                      color: cor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text(ScorePage.emoji(score.toInt()),
                  style: const TextStyle(fontSize: 16)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─── Conselho da FinanceIA ────────────────────────────────────────────────────
class _IaConselhoCard extends StatelessWidget {
  final double saldo, ganhos, gastos, score;
  const _IaConselhoCard(
      {required this.saldo,
      required this.ganhos,
      required this.gastos,
      required this.score});

  String _conselho() {
    if (saldo < 0) {
      return 'Seu saldo está negativo. A FinanceIA recomenda adiar compras até equilibrar o orçamento.';
    }
    if (score >= 80) {
      return 'Parabéns! Com score ${score.toInt()} você está em ótima forma. Avalie bem antes de comprar — mesmo assim.';
    }
    if (score >= 65) {
      return 'Você está bem financeiramente. Compras abaixo de 10% da renda são seguras agora.';
    }
    if (ganhos == 0) {
      return 'Registre seus ganhos para que a FinanceIA avalie se as ofertas são adequadas para você.';
    }
    return 'Momento de atenção. Priorize o essencial e foque em economizar antes de comprar.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.psychology, color: Colors.orange, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('FinanceIA diz:',
                style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 4),
            Text(_conselho(),
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }
}

// ─── Cabeçalho de seção ───────────────────────────────────────────────────────
class _SecaoHeader extends StatelessWidget {
  final String titulo, subtitulo;
  const _SecaoHeader({required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      Text(subtitulo,
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
    ]);
  }
}

// ─── Card do eBook ────────────────────────────────────────────────────────────
class _EbookCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _EbookCard({required this.doc});

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final titulo = data['titulo'] as String? ?? '';
    final descricao = data['descricao'] as String? ?? '';
    final preco = (data['preco'] as num?)?.toDouble() ?? 0;
    final precoOrig = (data['preco_original'] as num?)?.toDouble() ?? 0;
    final imagem = data['imagem_url'] as String? ?? '';
    final redirectUrl = '$_redirectBase/${doc.id}';
    final desc =
        precoOrig > preco ? ((precoOrig - preco) / precoOrig * 100).toInt() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        if (imagem.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(imagem,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 60)),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('📘 CONTEÚDO PREMIUM',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              if (desc > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('-$desc%',
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            Text(titulo,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            if (descricao.isNotEmpty && descricao != titulo) ...[
              const SizedBox(height: 4),
              Text(descricao,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmt(preco),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              if (precoOrig > preco) ...[
                const SizedBox(width: 8),
                Text(_fmt(precoOrig),
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white38)),
                const SizedBox(width: 6),
                Text('Economize ${_fmt(precoOrig - preco)}',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
              ],
            ]),
            const SizedBox(height: 12),
            const Row(children: [
              Icon(Icons.psychology, color: Colors.white70, size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                    'Aprenda a dominar sua vida financeira com inteligência artificial. '
                    'Ideal para quem quer organizar, economizar e criar renda extra.',
                    style: TextStyle(color: Colors.white60, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await launchUrl(Uri.parse(redirectUrl),
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A237E),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Quero o eBook — Garantir Agora',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Card produto inteligente ─────────────────────────────────────────────────
class _CardOfertaInteligente extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final int ranking;
  final double saldo, ganhos, gastos, score;

  const _CardOfertaInteligente({
    required this.doc,
    required this.ranking,
    required this.saldo,
    required this.ganhos,
    required this.gastos,
    required this.score,
  });

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  void _abrirCheck(BuildContext context, Map<String, dynamic> data,
      double preco, String redirectUrl) {
    final verd = _iaVeredicto(preco, saldo, ganhos);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2A3A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Row(children: [
            Icon(Icons.shield_outlined, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text('Checagem Financeira',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),

          // Produto
          Row(children: [
            const Icon(Icons.shopping_bag_outlined,
                color: Colors.white38, size: 16),
            const SizedBox(width: 6),
            Expanded(
                child: Text(data['titulo'] as String? ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            Text(_fmt(preco),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ]),

          const SizedBox(height: 14),
          const Divider(color: Colors.white12),
          const SizedBox(height: 14),

          // Dados financeiros
          Row(children: [
            Expanded(child: _CheckItem(label: 'Seu saldo', valor: _fmt(saldo),
                cor: saldo >= 0 ? Colors.greenAccent : Colors.redAccent)),
            Expanded(child: _CheckItem(
                label: 'Score', valor: '${score.toInt()}/100',
                cor: ScorePage.corNivel(score.toInt()))),
            if (ganhos > 0)
              Expanded(child: _CheckItem(
                  label: 'Da renda',
                  valor: '${(preco / ganhos * 100).toStringAsFixed(0)}%',
                  cor: preco / ganhos < 0.1 ? Colors.greenAccent : Colors.orange)),
          ]),

          const SizedBox(height: 14),

          // Veredicto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: verd.cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: verd.cor.withOpacity(0.3)),
            ),
            child: Row(children: [
              Text(verd.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('FinanceIA diz:',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  Text(verd.texto,
                      style: TextStyle(
                          color: verd.cor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.white54)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await launchUrl(Uri.parse(redirectUrl),
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Ver Oferta',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final titulo = data['titulo'] as String? ?? '';
    final preco = (data['preco'] as num?)?.toDouble() ?? 0;
    final precoOrig = (data['preco_original'] as num?)?.toDouble() ?? 0;
    final imagem = data['imagem_url'] as String? ?? '';
    final freteGratis = data['frete_gratis'] as bool? ?? false;
    final redirectUrl = '$_redirectBase/${doc.id}';
    final verd = _iaVeredicto(preco, saldo, ganhos);
    final descPct =
        precoOrig > preco ? ((precoOrig - preco) / precoOrig * 100).toInt() : 0;

    // Cor do ranking
    final rankCor = ranking == 1
        ? const Color(0xFFFFD700)
        : ranking == 2
            ? const Color(0xFFC0C0C0)
            : ranking == 3
                ? const Color(0xFFCD7F32)
                : Colors.white24;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: verd.cor == Colors.greenAccent
                ? Colors.green.withOpacity(0.2)
                : Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Imagem + ranking badge
        Stack(children: [
          if (imagem.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(imagem,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      height: 60, color: Colors.white10,
                      child: const Icon(Icons.image_outlined,
                          color: Colors.white24))),
            ),
          // Ranking badge
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.black87, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.emoji_events, color: rankCor, size: 14),
                const SizedBox(width: 4),
                Text('#$ranking',
                    style: TextStyle(
                        color: rankCor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ]),
            ),
          ),
          // Desconto badge
          if (descPct > 0)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('-$descPct%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ),
        ]),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Título
            Text(titulo,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),

            const SizedBox(height: 8),

            // Preço
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmt(preco),
                  style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              if (precoOrig > preco) ...[
                const SizedBox(width: 8),
                Text(_fmt(precoOrig),
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white38)),
              ],
            ]),

            // Badges
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (freteGratis)
                _Badge(label: '🚚 Frete grátis', cor: Colors.green),
              if (precoOrig > preco)
                _Badge(
                    label: '⬇️ Preço mínimo histórico',
                    cor: Colors.blueAccent),
            ]),

            const SizedBox(height: 10),

            // IA veredicto inline
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: verd.cor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: verd.cor.withOpacity(0.25)),
              ),
              child: Row(children: [
                Text(verd.emoji,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                const Text('FinanceIA: ',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                Expanded(
                    child: Text(verd.texto,
                        style: TextStyle(color: verd.cor, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ]),
            ),

            const SizedBox(height: 12),

            // Botões
            Row(children: [
              // Alerta de preço
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔔 Alerta de preço ativado!'),
                        backgroundColor: Color(0xFF1A2A3A),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_outlined, size: 14),
                  label: const Text('Alerta', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Ver oferta com check
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () =>
                      _abrirCheck(context, data, preco, redirectUrl),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Ver Oferta',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color cor;
  const _Badge({required this.label, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: cor, fontSize: 10)),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label, valor;
  final Color cor;
  const _CheckItem(
      {required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 10)),
      const SizedBox(height: 2),
      Text(valor,
          style: TextStyle(
              color: cor, fontSize: 14, fontWeight: FontWeight.bold)),
    ]);
  }
}
