import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ebooks_page.dart';
import 'score_page.dart';

// ─── Veredicto IA ─────────────────────────────────────────────────────────────
class _Veredicto {
  final String emoji, texto;
  final Color cor;
  const _Veredicto(this.emoji, this.texto, this.cor);
}

_Veredicto _iaVeredicto(double preco, double saldo, double ganhos) {
  if (saldo < 0) return const _Veredicto('❌', 'Saldo negativo — evite compras agora', Colors.redAccent);
  if (preco > saldo) return const _Veredicto('❌', 'Preço supera seu saldo disponível', Colors.redAccent);
  if (ganhos > 0) {
    final pct = preco / ganhos * 100;
    if (pct > 30) return _Veredicto('⚠️', '${pct.toStringAsFixed(0)}% da renda — impacto alto', Colors.orange);
    if (pct > 10) return _Veredicto('⚠️', '${pct.toStringAsFixed(0)}% da renda — avalie se é necessário', Colors.amber);
    return _Veredicto('✅', '${pct.toStringAsFixed(0)}% da renda — dentro do orçamento', Colors.greenAccent);
  }
  return const _Veredicto('⚠️', 'Registre sua renda para análise completa', Colors.orange);
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class OfertasPage extends StatefulWidget {
  const OfertasPage({super.key});
  @override
  State<OfertasPage> createState() => _OfertasPageState();
}

class _OfertasPageState extends State<OfertasPage> {
  late final String _uid;
  late final Stream<QuerySnapshot> _ganhosStream;
  late final Stream<QuerySnapshot> _gastosStream;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _ganhosStream = FirebaseFirestore.instance.collection('ganhos').where('userId', isEqualTo: _uid).snapshots();
    _gastosStream = FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: _uid).snapshots();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    final url = 'https://www.google.com/search?q=${Uri.encodeComponent(q)}&tbm=shop';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _limparBusca() {
    _searchCtrl.clear();
    setState(() {});
  }

  void _abrirLink(String url) async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
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
          Text('Ofertas Inteligentes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ganhosStream,
        builder: (ctx, gSnap) => StreamBuilder<QuerySnapshot>(
          stream: _gastosStream,
          builder: (ctx, eSnap) {
            double ganhos = 0, gastos = 0;
            if (gSnap.hasData) ganhos = gSnap.data!.docs.fold(0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
            if (eSnap.hasData) gastos = eSnap.data!.docs.fold(0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
            final saldo = ganhos - gastos;
            final score = ScorePage.calcScore(ganhos, gastos);

            return Column(children: [
              // ── Barra de busca ──
              Container(
                color: const Color(0xFF0A1628),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _buscar(),
                      decoration: InputDecoration(
                        hintText: 'Buscar produto no Google Shopping...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.orange, size: 24),
                        suffixIcon: null,
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 0.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _searchCtrl.text.isNotEmpty ? _limparBusca : _buscar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFE65100)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Icon(
                        _searchCtrl.text.isNotEmpty ? Icons.close : Icons.search,
                        color: Colors.white, size: 26,
                      ),
                    ),
                  ),
                ]),
              ),

              // ── Conteúdo ──
              Expanded(
                child: _OfertasFirestore(
                  saldo: saldo,
                  score: score,
                  ganhos: ganhos,
                  gastos: gastos,
                  onAbrir: _abrirLink,
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

// ─── Ofertas do Firestore (padrão) ───────────────────────────────────────────
class _OfertasFirestore extends StatelessWidget {
  final double saldo, ganhos, gastos;
  final int score;
  final void Function(String) onAbrir;
  const _OfertasFirestore({required this.saldo, required this.ganhos, required this.gastos, required this.score, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ofertas').where('ativo', isEqualTo: true).snapshots(),
      builder: (ctx, ofSnap) {
        if (ofSnap.hasError) return const Center(child: Text('Não foi possível carregar as ofertas.'));
        if (!ofSnap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orange));

        final todos = List.of(ofSnap.data!.docs);
        final ebooks = todos.where((d) => (d.data() as Map)['plataforma'] == 'hotmart' || (d.data() as Map)['categoria'] == 'ebooks').toList();
        final produtos = todos.where((d) => (d.data() as Map)['plataforma'] != 'hotmart' && (d.data() as Map)['categoria'] != 'ebooks').toList()
          ..sort((a, b) {
            final ad = (a.data() as Map);
            final bd = (b.data() as Map);
            final aP = (ad['preco'] as num?)?.toDouble() ?? 0;
            final aO = (ad['preco_original'] as num?)?.toDouble() ?? 1;
            final bP = (bd['preco'] as num?)?.toDouble() ?? 0;
            final bO = (bd['preco_original'] as num?)?.toDouble() ?? 1;
            return ((bO - bP) / bO).compareTo((aO - aP) / aO);
          });

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _FinancialSnapshot(saldo: saldo, score: score, ganhos: ganhos, gastos: gastos),
            const SizedBox(height: 14),
            _IaConselhoCard(saldo: saldo, ganhos: ganhos, score: score),
            const SizedBox(height: 18),

            // ── Kits & eBooks Kiwify ──────────────────────────
            const _SecaoHeader(
              titulo: '📚 eBooks & Kits — IA Financeiro',
              subtitulo: 'Aprenda e ganhe mais com inteligência artificial',
            ),
            const SizedBox(height: 12),
            _KiwifyKitsSection(onAbrir: onAbrir),
            const SizedBox(height: 18),

            // ── 12 eBooks individuais ─────────────────────────
            const _SecaoHeader(titulo: '📘 12 eBooks Individuais', subtitulo: 'Escolha o que mais combina com você'),
            const SizedBox(height: 10),
            _EbooksIndividuaisSection(onAbrir: onAbrir),
            const SizedBox(height: 18),
            if (produtos.isNotEmpty) ...[
              const _SecaoHeader(titulo: '🏆 Ranking de Promoções', subtitulo: 'IA avalia se vale a pena pra você'),
              const SizedBox(height: 10),
              ...produtos.asMap().entries.map((e) => _CardOfertaInteligente(
                doc: e.value, ranking: e.key + 1, saldo: saldo, ganhos: ganhos, score: score, onAbrir: onAbrir)),
            ] else ...[
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
                child: const Column(children: [
                  Icon(Icons.search, color: Colors.white24, size: 40),
                  SizedBox(height: 10),
                  Text('Use a busca acima para encontrar produtos', style: TextStyle(color: Colors.white54)),
                  SizedBox(height: 4),
                  Text('A busca abre o Google Shopping\ncom os melhores preços disponíveis.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                ]),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Widgets de suporte ───────────────────────────────────────────────────────
class _FinancialSnapshot extends StatelessWidget {
  final double saldo, ganhos, gastos;
  final int score;
  const _FinancialSnapshot({required this.saldo, required this.score, required this.ganhos, required this.gastos});

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final cor = ScorePage.corNivel(score);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SEU SALDO', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
          Text(_fmt(saldo), style: TextStyle(color: saldo >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        ])),
        Container(width: 1, height: 36, color: Colors.white12),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SCORE', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
          Row(children: [
            Text('$score/100', style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text(ScorePage.emoji(score), style: const TextStyle(fontSize: 16)),
          ]),
        ])),
      ]),
    );
  }
}

class _IaConselhoCard extends StatelessWidget {
  final double saldo, ganhos;
  final int score;
  const _IaConselhoCard({required this.saldo, required this.ganhos, required this.score});

  String _conselho() {
    if (saldo < 0) return 'Seu saldo está negativo. A FinanceIA recomenda adiar compras até equilibrar o orçamento.';
    if (score >= 80) return 'Parabéns! Com score $score você está em ótima forma. Avalie bem antes de comprar — mesmo assim.';
    if (score >= 65) return 'Você está bem financeiramente. Compras abaixo de 10% da renda são seguras agora.';
    if (ganhos == 0) return 'Registre seus ganhos para que a FinanceIA avalie se as ofertas são adequadas para você.';
    return 'Momento de atenção. Priorize o essencial e foque em economizar antes de comprar.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.orange.withOpacity(0.3))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.psychology, color: Colors.orange, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('FinanceIA diz:', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(_conselho(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ])),
      ]),
    );
  }
}

class _SecaoHeader extends StatelessWidget {
  final String titulo, subtitulo;
  const _SecaoHeader({required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    Text(subtitulo, style: const TextStyle(color: Colors.white38, fontSize: 12)),
  ]);
}

// ─── Seção Kiwify Kits ────────────────────────────────────────────────────────
class _KiwifyKitsSection extends StatelessWidget {
  final void Function(String) onAbrir;
  const _KiwifyKitsSection({required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // 3 kits
      ...EbooksPage.kitsJornada.map((kit) {
        final cor = kit['cor'] as Color;
        return GestureDetector(
          onTap: () => onAbrir(kit['url'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cor.withOpacity(0.45)),
            ),
            child: Row(children: [
              Container(
                width: 50,
                height: 50,
                decoration:
                    BoxDecoration(color: cor, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_stories, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(kit['titulo'] as String,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(kit['badge'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text(kit['subtitulo'] as String,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(kit['de'] as String,
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white38)),
                    const SizedBox(width: 8),
                    Text(kit['preco'] as String,
                        style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('Comprar',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ]),
          ),
        );
      }),
      // Botão ver todos
      GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EbooksPage())),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, color: Colors.white54, size: 18),
              SizedBox(width: 8),
              Text('Ver todos os 12 eBooks individuais',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
            ],
          ),
        ),
      ),
    ]);
  }
}

// ─── Seção 12 eBooks Individuais (hardcoded) ─────────────────────────────────
class _EbooksIndividuaisSection extends StatelessWidget {
  final void Function(String) onAbrir;
  const _EbooksIndividuaisSection({required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: EbooksPage.ebooks.map((ebook) {
        final cor = ebook['cor'] as Color;
        return GestureDetector(
          onTap: () => onAbrir(ebook['url'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cor.withOpacity(0.35)),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(ebook['emoji'] as String, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ebook['titulo'] as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(ebook['desc'] as String,
                    style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(ebook['preco'] as String,
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Comprar', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ]),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Card eBook (usa link_afiliado direto) ────────────────────────────────────
class _EbookCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final void Function(String) onAbrir;
  const _EbookCard({required this.doc, required this.onAbrir});

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final titulo = data['titulo'] as String? ?? '';
    final descricao = data['descricao'] as String? ?? '';
    final preco = (data['preco'] as num?)?.toDouble() ?? 0;
    final precoOrig = (data['preco_original'] as num?)?.toDouble() ?? 0;
    final imagem = data['imagem'] as String? ?? data['imagem_url'] as String? ?? '';
    final link = data['link_afiliado'] as String? ?? data['link_redirect'] as String? ?? '';
    final desc = precoOrig > preco ? ((precoOrig - preco) / precoOrig * 100).toInt() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF4A148C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        if (imagem.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(imagem, width: double.infinity, height: 160, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 60)),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: const Text('📘 CONTEÚDO PREMIUM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              if (desc > 0) ...[
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: Text('-$desc%', style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold))),
              ],
            ]),
            const SizedBox(height: 10),
            Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            if (descricao.isNotEmpty && descricao != titulo) ...[
              const SizedBox(height: 4),
              Text(descricao, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmt(preco), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              if (precoOrig > preco) ...[
                const SizedBox(width: 8),
                Text(_fmt(precoOrig), style: const TextStyle(color: Colors.white38, fontSize: 14, decoration: TextDecoration.lineThrough, decorationColor: Colors.white38)),
                const SizedBox(width: 6),
                Text('Economize ${_fmt(precoOrig - preco)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
              ],
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onAbrir(link),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A237E), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Quero o eBook — Garantir Agora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Card produto ML (usa link_afiliado direto) ───────────────────────────────
class _CardOfertaInteligente extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final int ranking;
  final double saldo, ganhos;
  final int score;
  final void Function(String) onAbrir;

  const _CardOfertaInteligente({required this.doc, required this.ranking, required this.saldo, required this.ganhos, required this.score, required this.onAbrir});

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final titulo = data['titulo'] as String? ?? '';
    final preco = (data['preco'] as num?)?.toDouble() ?? 0;
    final precoOrig = (data['preco_original'] as num?)?.toDouble() ?? 0;
    final imagem = data['imagem'] as String? ?? data['imagem_url'] as String? ?? '';
    final freteGratis = data['frete_gratis'] as bool? ?? false;
    final link = data['link_afiliado'] as String? ?? data['link_redirect'] as String? ?? '';
    final verd = _iaVeredicto(preco, saldo, ganhos);
    final descPct = precoOrig > preco ? ((precoOrig - preco) / precoOrig * 100).toInt() : 0;
    final rankCor = ranking == 1 ? const Color(0xFFFFD700) : ranking == 2 ? const Color(0xFFC0C0C0) : ranking == 3 ? const Color(0xFFCD7F32) : Colors.white24;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1A2A3A), borderRadius: BorderRadius.circular(16), border: Border.all(color: verd.cor == Colors.greenAccent ? Colors.green.withOpacity(0.2) : Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          if (imagem.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(imagem, width: double.infinity, height: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 60, color: Colors.white10, child: const Icon(Icons.image_outlined, color: Colors.white24))),
            ),
          Positioned(top: 10, left: 10, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.emoji_events, color: rankCor, size: 14),
              const SizedBox(width: 4),
              Text('#$ranking', style: TextStyle(color: rankCor, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          )),
          if (descPct > 0) Positioned(top: 10, right: 10, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
            child: Text('-$descPct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          )),
        ]),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmt(preco), style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
              if (precoOrig > preco) ...[
                const SizedBox(width: 8),
                Text(_fmt(precoOrig), style: const TextStyle(color: Colors.white38, fontSize: 13, decoration: TextDecoration.lineThrough, decorationColor: Colors.white38)),
              ],
            ]),
            if (freteGratis) ...[
              const SizedBox(height: 6),
              const Text('🚚 Frete grátis', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: verd.cor.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: verd.cor.withOpacity(0.25))),
              child: Row(children: [
                Text(verd.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                const Text('FinanceIA: ', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                Expanded(child: Text(verd.texto, style: TextStyle(color: verd.cor, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onAbrir(link),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Ver Oferta', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
