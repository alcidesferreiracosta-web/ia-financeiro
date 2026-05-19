import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adicionar_ganhos_page.dart';
import 'gastos_page.dart';
import 'extrato_page.dart';
import 'ofertas_page.dart';
import 'assistente_page.dart';
import 'dicas_ia_page.dart';
import 'investimentos_page.dart';
import 'planejamento_page.dart';

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
        if (nome != null && nome.isNotEmpty) {
          if (mounted) setState(() => _nome = nome.split(' ').first);
          return;
        }
      }
    } catch (_) {}
    final displayName = FirebaseAuth.instance.currentUser?.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      if (mounted) setState(() => _nome = displayName.split(' ').first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nome.isEmpty ? 'Olá!' : 'Olá, $_nome!',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const Text('Gerencie suas finanças de forma inteligente.',
                            style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white54),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Totais em tempo real — ambos os streams com snapshots()
              StreamBuilder<QuerySnapshot>(
                stream: _ganhosStream,
                builder: (ctx, ganhosSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _gastosStream,
                    builder: (ctx, gastosSnap) {
                      double ganhos = 0, gastos = 0;
                      if (ganhosSnap.hasData) {
                        ganhos = ganhosSnap.data!.docs.fold(
                            0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
                      }
                      if (gastosSnap.hasData) {
                        gastos = gastosSnap.data!.docs.fold(
                            0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
                      }
                      final saldo = ganhos - gastos;

                      return Column(
                        children: [
                          _CardValor(
                            titulo: 'GANHOS DO MÊS',
                            valor: ganhos,
                            cor: Colors.green,
                            icone: Icons.trending_up,
                          ),
                          const SizedBox(height: 12),
                          _CardValor(
                            titulo: 'GASTOS DO MÊS',
                            valor: gastos,
                            cor: Colors.red,
                            icone: Icons.trending_down,
                          ),
                          const SizedBox(height: 12),
                          _CardSaldo(saldo: saldo),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              const Text('Ações rápidas', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _BotaoNav(
                    label: 'Ganhos', icone: Icons.add_circle_outline, cor: Colors.green,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdicionarGanhosPage())),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _BotaoNav(
                    label: 'Gastos', icone: Icons.remove_circle_outline, cor: Colors.red,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const GastosPage())),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              _BotaoNavLargo(
                label: 'IA Financeira', icone: Icons.psychology,
                cor: const Color(0xFF1A237E),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AssistentePage())),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _BotaoNav(
                    label: 'Ofertas', icone: Icons.local_offer_outlined, cor: Colors.orange,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const OfertasPage())),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _BotaoNav(
                    label: 'Extrato', icone: Icons.receipt_long_outlined, cor: Colors.teal,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ExtratoPage())),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _BotaoNav(
                    label: 'Dicas IA', icone: Icons.lightbulb_outline, cor: Colors.yellow,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DicasIAPage())),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _BotaoNav(
                    label: 'Investimentos', icone: Icons.trending_up, cor: Colors.green,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const InvestimentosPage())),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              _BotaoNavLargo(
                label: 'Planejamento Mensal', icone: Icons.calendar_month,
                cor: const Color(0xFF00695C),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PlanejamentoPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardValor extends StatelessWidget {
  final String titulo;
  final double valor;
  final Color cor;
  final IconData icone;
  const _CardValor(
      {required this.titulo, required this.valor, required this.cor, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo,
                style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(color: cor, fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
          Icon(icone, color: cor, size: 32),
        ],
      ),
    );
  }
}

class _CardSaldo extends StatelessWidget {
  final double saldo;
  const _CardSaldo({required this.saldo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
          SizedBox(width: 8),
          Text('SALDO ATUAL',
              style: TextStyle(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Text('R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const Text('Disponível para investimentos',
            style: TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    );
  }
}

class _BotaoNav extends StatelessWidget {
  final String label;
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;
  const _BotaoNav(
      {required this.label, required this.icone, required this.cor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: cor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
          color: cor.withOpacity(0.1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icone, color: cor, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _BotaoNavLargo extends StatelessWidget {
  final String label;
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;
  const _BotaoNavLargo(
      {required this.label, required this.icone, required this.cor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [cor, cor.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icone, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ),
    );
  }
}
