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
import 'afiliados_page.dart';

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
                        const SizedBox(width: 10),
                        Expanded(
                            child: _NavBtn(
                                label: 'Afiliados',
                                icon: Icons.storefront_outlined,
                                cor: const Color(0xFF7B1FA2),
                                onTap: () => _ir(const AfiliadosPage()))),
                      ]),
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
