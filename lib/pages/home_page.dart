import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adicionar_ganhos_page.dart';
import 'gastos_page.dart';
import 'extrato_page.dart';
import 'score_page.dart';
import 'simulador_page.dart';
import 'sair_dividas_page.dart';
import 'dicas_ia_page.dart';
import 'investimentos_page.dart';
import 'planejamento_page.dart';
import 'renda_extra_page.dart';
import 'ebooks_page.dart';
import '../services/gps_economia_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final String _uid;
  late final Stream<QuerySnapshot> _ganhosStream;
  late final Stream<QuerySnapshot> _gastosStream;
  String _nome = '';

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
    _carregarNome();
  }

  Future<void> _carregarNome() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (doc.exists) {
        final nome = doc.data()?['nome'] as String?;
        if (nome != null && nome.isNotEmpty && mounted) {
          setState(() => _nome = nome.split(' ').first);
          return;
        }
      }
    } catch (_) {}
    final displayName = FirebaseAuth.instance.currentUser?.displayName;
    if (displayName != null && displayName.isNotEmpty && mounted) {
      setState(() => _nome = displayName.split(' ').first);
    }
  }

  List<String> _alertas(List<QueryDocumentSnapshot> gastosDocs, double ganhos) {
    final alertas = <String>[];
    if (gastosDocs.isEmpty) return alertas;

    final total =
        gastosDocs.fold(0.0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));

    if (ganhos > 0 && total / ganhos > 0.8) {
      alertas.add(
          'Seus gastos estão em ${((total / ganhos) * 100).toStringAsFixed(0)}% da renda!');
    }

    final cats = <String, int>{};
    for (final d in gastosDocs) {
      final cat = d['categoria'] as String? ?? 'Outros';
      cats[cat] = (cats[cat] ?? 0) + 1;
    }

    if ((cats['Lazer'] ?? 0) >= 5) {
      alertas.add('${cats['Lazer']} gastos em Lazer este mês');
    }

    final pequenos =
        gastosDocs.where((d) => ((d['valor'] as num?)?.toDouble() ?? 0) < 30).length;
    if (pequenos >= 5) {
      alertas.add('$pequenos pequenos gastos abaixo de R\$30 detectados');
    }

    final desnecessarios =
        gastosDocs.where((d) => d['necessario'] == false).length;
    if (desnecessarios >= 3) {
      alertas.add('$desnecessarios gastos marcados como desnecessários');
    }

    return alertas;
  }

  String _fmt(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  void _ir(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _ganhosStream,
          builder: (ctx, gSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: _gastosStream,
              builder: (ctx, eSnap) {
                double ganhos = 0, gastos = 0;
                if (gSnap.hasData) {
                  ganhos = gSnap.data!.docs.fold(
                      0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
                }
                if (eSnap.hasData) {
                  gastos = eSnap.data!.docs.fold(
                      0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
                }
                final saldo = ganhos - gastos;
                final score = ScorePage.calcScore(ganhos, gastos);
                final nv = ScorePage.nivel(score);
                final em = ScorePage.emoji(score);
                final cor = ScorePage.corNivel(score);
                final gastosDocs = eSnap.data?.docs ?? [];
                final alertas = _alertas(gastosDocs, ganhos);
                final taxa = ganhos > 0
                    ? ((ganhos - gastos) / ganhos * 100).clamp(0.0, 100.0)
                    : 0.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              _nome.isEmpty ? 'Olá!' : 'Olá, $_nome!',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text('Sua saúde financeira hoje',
                                style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ]),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: cor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: cor.withOpacity(0.4)),
                              ),
                              child: Text('$em $nv',
                                  style: TextStyle(
                                      color: cor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout,
                                  color: Colors.white24, size: 20),
                              onPressed: () => FirebaseAuth.instance.signOut(),
                            ),
                          ]),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Saldo card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: saldo >= 0
                                ? const [Color(0xFF1A237E), Color(0xFF283593)]
                                : const [Color(0xFF6A1B9A), Color(0xFF880E4F)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SALDO ATUAL',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1)),
                            const SizedBox(height: 6),
                            Text(_fmt(saldo),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 14),
                            Row(children: [
                              _MiniInfo(
                                  label: 'Ganhos',
                                  texto: _fmt(ganhos),
                                  cor: Colors.greenAccent),
                              const SizedBox(width: 18),
                              _MiniInfo(
                                  label: 'Gastos',
                                  texto: _fmt(gastos),
                                  cor: Colors.redAccent),
                              if (ganhos > 0) ...[
                                const SizedBox(width: 18),
                                _MiniInfo(
                                    label: 'Economia',
                                    texto:
                                        '${taxa.toStringAsFixed(0)}%',
                                    cor: Colors.orangeAccent),
                              ],
                            ]),
                          ],
                        ),
                      ),

                      // Alertas "Dinheiro indo embora"
                      if (alertas.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.redAccent, size: 16),
                                  SizedBox(width: 6),
                                  Text('Dinheiro indo embora',
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ]),
                                const SizedBox(height: 8),
                                ...alertas.map((a) => Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Row(children: [
                                        const Icon(Icons.chevron_right,
                                            color: Colors.redAccent, size: 14),
                                        Expanded(
                                            child: Text(a,
                                                style: const TextStyle(
                                                    color: Colors.white60,
                                                    fontSize: 12))),
                                      ]),
                                    )),
                              ]),
                        ),
                      ],

                      const SizedBox(height: 12),
                      _PerfilFinanceiroCard(ganhos: ganhos, gastos: gastos),

                      const SizedBox(height: 12),

                      // Score mini-card
                      GestureDetector(
                        onTap: () => _ir(const ScorePage()),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cor.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            SizedBox(
                              width: 46,
                              height: 46,
                              child: Stack(alignment: Alignment.center, children: [
                                CircularProgressIndicator(
                                  value: score / 100,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation(cor),
                                  strokeWidth: 4,
                                ),
                                Text('$score',
                                    style: TextStyle(
                                        color: cor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Score Financeiro',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text('$em $nv — toque para detalhes',
                                        style: TextStyle(
                                            color: cor, fontSize: 11)),
                                  ]),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 10),
                      _AlertasInteligentesCard(
                          gastosDocs: gastosDocs, ganhos: ganhos),

                      const SizedBox(height: 16),

                      // Ações rápidas
                      Row(children: [
                        Expanded(
                            child: _AcaoBtn(
                                label: '+ Ganho',
                                icon: Icons.add_circle_outline,
                                cor: Colors.green,
                                onTap: () => _ir(const AdicionarGanhosPage()))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _AcaoBtn(
                                label: '+ Gasto',
                                icon: Icons.remove_circle_outline,
                                cor: Colors.red,
                                onTap: () => _ir(const GastosPage()))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _AcaoBtn(
                                label: 'Extrato',
                                icon: Icons.receipt_long_outlined,
                                cor: Colors.teal,
                                onTap: () => _ir(const ExtratoPage()))),
                      ]),

                      const SizedBox(height: 12),

                      // Viral button
                      _NavBtn(
                        label: 'Quanto eu teria se...',
                        icon: Icons.calculate_outlined,
                        cor: Colors.orange,
                        largo: true,
                        onTap: () => _ir(const SimuladorPage()),
                      ),

                      const SizedBox(height: 10),

                      Row(children: [
                        Expanded(
                            child: _NavBtn(
                                label: 'Sair das Dívidas',
                                icon: Icons.money_off,
                                cor: Colors.purple,
                                onTap: () => _ir(const SairDividasPage()))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _NavBtn(
                                label: 'Planejamento',
                                icon: Icons.calendar_month,
                                cor: const Color(0xFF00695C),
                                onTap: () => _ir(const PlanejamentoPage()))),
                      ]),

                      const SizedBox(height: 10),

                      Row(children: [
                        Expanded(
                            child: _NavBtn(
                                label: 'Investimentos',
                                icon: Icons.trending_up,
                                cor: Colors.green,
                                onTap: () => _ir(const InvestimentosPage()))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _NavBtn(
                                label: 'Dicas IA',
                                icon: Icons.lightbulb_outline,
                                cor: Colors.amber,
                                onTap: () => _ir(const DicasIAPage()))),
                      ]),

                      const SizedBox(height: 10),

                      _NavBtn(
                        label: 'Renda Extra — 20 oportunidades',
                        icon: Icons.rocket_launch_outlined,
                        cor: Colors.green,
                        largo: true,
                        onTap: () => _ir(const RendaExtraPage()),
                      ),

                      const SizedBox(height: 10),

                      _NavBtn(
                        label: '📚 eBooks IA Financeiro — 12 títulos',
                        icon: Icons.menu_book,
                        cor: Colors.orange,
                        largo: true,
                        onTap: () => _ir(const EbooksPage()),
                      ),

                      const SizedBox(height: 12),

                      const _MissoesDiariasCard(),

                      const SizedBox(height: 12),

                      const _EconomiaGeradaCard(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label, texto;
  final Color cor;
  const _MiniInfo({required this.label, required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      Text(texto, style: TextStyle(color: cor, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _AcaoBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color cor;
  final VoidCallback onTap;
  const _AcaoBtn(
      {required this.label,
      required this.icon,
      required this.cor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          border: Border.all(color: cor.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: cor, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Missões Diárias ───────────────────────────────────────────────────────────

class _MissoesDiariasCard extends StatefulWidget {
  const _MissoesDiariasCard();

  @override
  State<_MissoesDiariasCard> createState() => _MissoesDiariasCardState();
}

class _MissoesDiariasCardState extends State<_MissoesDiariasCard> {
  List<Map<String, dynamic>> _missoes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    GpsEconomiaService.instance
        .getMissoesDiarias()
        .then((m) { if (mounted) setState(() { _missoes = m; _carregando = false; }); });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const SizedBox.shrink();
    final concluidas = _missoes.where((m) => m['concluida'] == true).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('⚡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Missões Diárias',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$concluidas/${_missoes.length}',
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        ..._missoes.map((m) {
          final atual = (m['atual'] as int?) ?? 0;
          final meta = (m['meta'] as int?) ?? 1;
          final concluida = m['concluida'] == true;
          final progresso = (atual / meta).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Text(m['icone'] as String? ?? '🎯',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(m['label'] as String? ?? '',
                              style: TextStyle(
                                  color: concluida
                                      ? const Color(0xFF4CAF50)
                                      : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: concluida
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                        Text('$atual/$meta',
                            style: TextStyle(
                                color: concluida
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white38,
                                fontSize: 11)),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progresso,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(
                              concluida
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFFD700)),
                          minHeight: 5,
                        ),
                      ),
                    ]),
              ),
              if (concluida) ...[
                const SizedBox(width: 8),
                const Text('+20 pts',
                    style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ]),
          );
        }),
      ]),
    );
  }
}

// ── Economia Gerada pelo GPS ──────────────────────────────────────────────────

class _EconomiaGeradaCard extends StatefulWidget {
  const _EconomiaGeradaCard();

  @override
  State<_EconomiaGeradaCard> createState() => _EconomiaGeradaCardState();
}

class _EconomiaGeradaCardState extends State<_EconomiaGeradaCard> {
  Map<String, dynamic> _economia = {};
  bool _carregando = true;
  int _pontos = 0;
  String _rankTier = '';
  double _econMes = 0;
  double _econAno = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final results = await Future.wait([
      GpsEconomiaService.instance.getEconomiaTotal(),
      GpsEconomiaService.instance.getMeusDados(),
      GpsEconomiaService.instance.getEconomiaMetrics(),
    ]);
    if (mounted) {
      final econ = results[0] as Map<String, dynamic>;
      final dados = results[1] as Map<String, dynamic>?;
      final metrics = results[2] as EconomiaMetrics;
      setState(() {
        _economia = econ;
        _pontos = (dados?['pontos'] as num?)?.toInt() ?? 0;
        _rankTier = (dados?['rank'] as String?) ?? '';
        _econMes = metrics.mes;
        _econAno = metrics.ano;
        _carregando = false;
      });
    }
  }

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  Color _rankColor() {
    switch (_rankTier) {
      case 'rei':          return const Color(0xFFFFD700);
      case 'lenda':        return const Color(0xFF9C27B0);
      case 'mestre':       return const Color(0xFFFF9800);
      case 'especialista': return const Color(0xFFB0BEC5);
      case 'cacador':      return const Color(0xFFCD7F32);
      default:             return const Color(0xFF4CAF50);
    }
  }

  String _rankLabel() {
    switch (_rankTier) {
      case 'rei':          return '👑 Rei da Economia';
      case 'lenda':        return '💎 Lenda da Economia';
      case 'mestre':       return '🥇 Mestre da Economia';
      case 'especialista': return '🥈 Especialista';
      case 'cacador':      return '🥉 Caçador de Ofertas';
      default:             return _rankTier.isEmpty ? '' : '🥉 Caçador de Ofertas';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const SizedBox.shrink();
    final total = _economia.values
        .fold(0.0, (s, v) => s + ((v as num?)?.toDouble() ?? 0));
    if (total == 0 && _pontos == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header com rank
        Row(children: [
          const Icon(Icons.savings, color: Color(0xFF4CAF50), size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Economia via GPS da Economia',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          if (_rankLabel().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _rankColor().withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _rankColor().withOpacity(0.5)),
              ),
              child: Text(_rankLabel(),
                  style: TextStyle(
                      color: _rankColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ]),

        // Total destaque
        if (total > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Text('🏆', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Você economizou este mês',
                    style: TextStyle(color: Colors.white60, fontSize: 11)),
                Text(_fmt(total),
                    style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),
        ],

        if (_econMes > 0 || _econAno > 0) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _MetricaEco(label: 'Este mês',   valor: _econMes)),
            const SizedBox(width: 8),
            Expanded(child: _MetricaEco(label: 'Este ano',   valor: _econAno)),
            const SizedBox(width: 8),
            Expanded(child: _MetricaEco(label: 'Total geral',
                valor: _economia.values.fold(0.0, (s, v) => s + ((v as num?)?.toDouble() ?? 0)))),
          ]),
        ],

        if (_pontos > 0) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.stars, color: Color(0xFFFFD700), size: 14),
            const SizedBox(width: 4),
            Text('$_pontos pontos acumulados no ranking',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ],

        if (_economia.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Divider(color: Colors.white12),
          const SizedBox(height: 4),
          ..._economia.entries.map((e) {
            final val = (e.value as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Expanded(
                  child: Text('em ${e.key}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ),
                Text(_fmt(val),
                    style: const TextStyle(
                        color: Color(0xFF66BB6A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

// ── Métrica de economia mini ──────────────────────────────────────────────────

class _MetricaEco extends StatelessWidget {
  final String label;
  final double valor;
  const _MetricaEco({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    final txt = 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
            textAlign: TextAlign.center),
        const SizedBox(height: 3),
        Text(txt,
            style: const TextStyle(
                color: Color(0xFF66BB6A),
                fontSize: 11,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ── Perfil Financeiro ─────────────────────────────────────────────────────────

class _PerfilFinanceiroCard extends StatelessWidget {
  final double ganhos;
  final double gastos;
  const _PerfilFinanceiroCard({required this.ganhos, required this.gastos});

  @override
  Widget build(BuildContext context) {
    if (ganhos <= 0) return const SizedBox.shrink();
    final ratio = (gastos / ganhos).clamp(0.0, 1.5);
    final String perfil;
    final String emoji;
    final Color cor;
    final String desc;
    if (ratio < 0.5) {
      perfil = 'Econômico';
      emoji = '🌿';
      cor = const Color(0xFF4CAF50);
      desc = 'Você gasta menos de 50% da renda. Parabéns!';
    } else if (ratio <= 0.8) {
      perfil = 'Equilibrado';
      emoji = '⚖️';
      cor = const Color(0xFFFF9800);
      desc = 'No caminho certo. Tente aumentar sua margem de economia.';
    } else {
      perfil = 'Gastador';
      emoji = '🔥';
      cor = const Color(0xFFF44336);
      desc = 'Gastos acima de 80% da renda. Revise o orçamento!';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withOpacity(0.25)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Perfil: ',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text(perfil,
                  style: TextStyle(
                      color: cor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 3),
            Text(desc,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11, height: 1.3)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(cor),
                minHeight: 4,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Text('${(ratio * 100).round()}%',
            style: TextStyle(
                color: cor, fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ── Alertas Inteligentes ──────────────────────────────────────────────────────

class _AlertasInteligentesCard extends StatefulWidget {
  final List<QueryDocumentSnapshot> gastosDocs;
  final double ganhos;
  const _AlertasInteligentesCard(
      {required this.gastosDocs, required this.ganhos});

  @override
  State<_AlertasInteligentesCard> createState() =>
      _AlertasInteligentesCardState();
}

class _AlertasInteligentesCardState extends State<_AlertasInteligentesCard> {
  Map<String, dynamic> _economia = {};

  @override
  void initState() {
    super.initState();
    GpsEconomiaService.instance
        .getEconomiaTotal()
        .then((d) { if (mounted) setState(() => _economia = d); });
  }

  String _fmt(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  List<String> _gerarAlertas() {
    final lista = <String>[];
    final docs = widget.gastosDocs;

    final cats = <String, double>{};
    for (final d in docs) {
      final cat = d['categoria'] as String? ?? 'Outros';
      cats[cat] = (cats[cat] ?? 0) + ((d['valor'] as num?)?.toDouble() ?? 0);
    }
    if (cats.isNotEmpty) {
      final top = cats.entries.reduce((a, b) => a.value > b.value ? a : b);
      lista.add(
          'Você gastou ${_fmt(top.value)} em ${top.key} este mês — veja promoções no GPS da Economia!');
    }

    if (_economia.isNotEmpty) {
      final total = _economia.values
          .fold(0.0, (s, v) => s + ((v as num?)?.toDouble() ?? 0));
      if (total > 0) {
        lista.add('Você já economizou ${_fmt(total)} usando o GPS da Economia este mês. Continue assim!');
      }
    }

    int finsDeSemana = 0;
    for (final d in docs) {
      try {
        final ts = d['data'];
        if (ts is Timestamp) {
          final dt = ts.toDate();
          if (dt.weekday >= 6) finsDeSemana++;
        }
      } catch (_) {}
    }
    if (finsDeSemana >= 4) {
      lista.add('Você tem $finsDeSemana gastos nos fins de semana. Planeje antes de sair para economizar mais!');
    }

    return lista.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final alertas = _gerarAlertas();
    if (alertas.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome, color: Color(0xFF64B5F6), size: 15),
          SizedBox(width: 6),
          Text('Alertas Inteligentes',
              style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ...alertas.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(a,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4))),
                  ]),
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color cor;
  final VoidCallback onTap;
  final bool largo;
  const _NavBtn(
      {required this.label,
      required this.icon,
      required this.cor,
      required this.onTap,
      this.largo = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: largo ? double.infinity : null,
        padding: EdgeInsets.symmetric(
            vertical: largo ? 14 : 12, horizontal: largo ? 0 : 8),
        decoration: BoxDecoration(
          gradient: largo
              ? LinearGradient(
                  colors: [cor, cor.withOpacity(0.7)])
              : null,
          color: largo ? null : cor.withOpacity(0.1),
          border: largo ? null : Border.all(color: cor.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              color: largo ? Colors.white : cor,
              size: largo ? 22 : 20),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: largo ? Colors.white : cor,
                  fontWeight: FontWeight.bold,
                  fontSize: largo ? 15 : 11)),
        ]),
      ),
    );
  }
}
