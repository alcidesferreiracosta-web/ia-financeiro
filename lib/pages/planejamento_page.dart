import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PlanejamentoPage extends StatelessWidget {
  const PlanejamentoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final mesAtual = DateFormat('MMMM yyyy', 'pt_BR').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Planejamento Mensal', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder(
        future: Future.wait([
          FirebaseFirestore.instance.collection('ganhos').where('userId', isEqualTo: uid).get(),
          FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: uid).get(),
        ]),
        builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          double ganhos = snapshot.data![0].docs.fold(0, (s, d) => s + (d['valor'] as num).toDouble());
          double gastos = snapshot.data![1].docs.fold(0, (s, d) => s + (d['valor'] as num).toDouble());
          double saldo = ganhos - gastos;
          double pct = ganhos > 0 ? (gastos / ganhos * 100).clamp(0, 100) : 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Resumo de $mesAtual', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _ResumoItem('Receitas', ganhos, Colors.green, Icons.arrow_upward),
              const SizedBox(height: 8),
              _ResumoItem('Despesas', gastos, Colors.red, Icons.arrow_downward),
              const SizedBox(height: 8),
              _ResumoItem('Saldo', saldo, saldo >= 0 ? Colors.teal : Colors.red, Icons.account_balance),
              const SizedBox(height: 24),
              const Text('Comprometimento da Renda', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(pct > 80 ? Colors.red : pct > 60 ? Colors.orange : Colors.green),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text('${pct.toStringAsFixed(1)}% da renda comprometida com gastos',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 24),
              const Text('Metas Sugeridas', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _Meta('Poupança (20%)', ganhos * 0.2, Colors.blue),
              const SizedBox(height: 8),
              _Meta('Reserva emergência (6 meses)', gastos * 6, Colors.orange),
            ],
          );
        },
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String label;
  final double valor;
  final Color cor;
  final IconData icone;
  const _ResumoItem(this.label, this.valor, this.cor, this.icone);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icone, color: cor, size: 22),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        Text('R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final double valor;
  final Color cor;
  const _Meta(this.label, this.valor, this.cor);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: cor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: cor.withOpacity(0.05),
      ),
      child: Row(children: [
        Icon(Icons.flag_outlined, color: cor, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        Text('R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}
