import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adicionar_ganhos_page.dart';
import 'gastos_page.dart';
import 'extrato_page.dart';
import 'ofertas_page.dart';
import 'assistente_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Stream<Map<String, double>> _totaisStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('ganhos')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .asyncMap((ganhos) async {
      final gastos = await FirebaseFirestore.instance
          .collection('gastos')
          .where('userId', isEqualTo: uid)
          .get();
      double totalGanhos = ganhos.docs.fold(0, (s, d) => s + (d['valor'] as num).toDouble());
      double totalGastos = gastos.docs.fold(0, (s, d) => s + (d['valor'] as num).toDouble());
      return {
        'ganhos': totalGanhos,
        'gastos': totalGastos,
        'saldo': totalGanhos - totalGastos,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Olá, ${user?.displayName ?? 'Usuário'}!',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text('Gerencie suas finanças de forma inteligente.',
                          style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white54),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              StreamBuilder<Map<String, double>>(
                stream: _totaisStream(),
                builder: (context, snapshot) {
                  final ganhos = snapshot.data?['ganhos'] ?? 0;
                  final gastos = snapshot.data?['gastos'] ?? 0;
                  final saldo = snapshot.data?['saldo'] ?? 0;
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
              ),
              const SizedBox(height: 24),
              const Text('Ações rápidas', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _BotaoNav(
                    label: 'Ganhos', icone: Icons.add_circle_outline, cor: Colors.green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdicionarGanhosPage())),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _BotaoNav(
                    label: 'Gastos', icone: Icons.remove_circle_outline, cor: Colors.red,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GastosPage())),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              _BotaoNavLargo(
                label: 'IA Financeira', icone: Icons.psychology, cor: const Color(0xFF1A237E),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistentePage())),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _BotaoNav(
                    label: 'Ofertas', icone: Icons.local_offer_outlined, cor: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfertasPage())),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _BotaoNav(
                    label: 'Extrato', icone: Icons.receipt_long_outlined, cor: Colors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExtratoPage())),
                  )),
                ],
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
  const _CardValor({required this.titulo, required this.valor, required this.cor, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600)),
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
          Text('SALDO ATUAL', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Text('R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const Text('Disponível para investimentos', style: TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    );
  }
}

class _BotaoNav extends StatelessWidget {
  final String label;
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;
  const _BotaoNav({required this.label, required this.icone, required this.cor, required this.onTap});

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
  const _BotaoNavLargo({required this.label, required this.icone, required this.cor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF7B1FA2)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icone, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ),
    );
  }
}
