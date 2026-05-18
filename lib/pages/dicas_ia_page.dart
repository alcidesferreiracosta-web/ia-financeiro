import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DicasIAPage extends StatefulWidget {
  const DicasIAPage({super.key});
  @override
  State<DicasIAPage> createState() => _DicasIAPageState();
}

class _DicasIAPageState extends State<DicasIAPage> {
  bool _loading = true;
  Map<String, double> _dados = {};
  List<Map<String, dynamic>> _dicas = [];

  @override
  void initState() {
    super.initState();
    _analisar();
  }

  Future<void> _analisar() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ganhos = await FirebaseFirestore.instance.collection('ganhos').where('userId', isEqualTo: uid).get();
    final gastos = await FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: uid).get();
    double totalGanhos = ganhos.docs.fold(0, (s, d) => s + (d['valor'] as num).toDouble());
    double totalGastos = gastos.docs.fold(0, (s, d) => s + (d['valor'] as num).toDouble());
    double saldo = totalGanhos - totalGastos;
    double taxa = totalGanhos > 0 ? totalGastos / totalGanhos * 100 : 0;

    final dicas = <Map<String, dynamic>>[];

    if (taxa > 80) {
      dicas.add({'icone': Icons.warning_amber, 'cor': Colors.red, 'titulo': 'Gastos Elevados',
          'descricao': 'Você está gastando ${taxa.toStringAsFixed(0)}% dos seus ganhos. Revise gastos desnecessários.'});
    } else if (taxa > 50) {
      dicas.add({'icone': Icons.info_outline, 'cor': Colors.orange, 'titulo': 'Controle Moderado',
          'descricao': 'Gastos em ${taxa.toStringAsFixed(0)}% dos ganhos. Há espaço para economizar mais.'});
    } else {
      dicas.add({'icone': Icons.check_circle_outline, 'cor': Colors.green, 'titulo': 'Ótimo Controle!',
          'descricao': 'Você está gastando apenas ${taxa.toStringAsFixed(0)}% dos seus ganhos. Continue assim!'});
    }

    if (saldo > 0) {
      dicas.add({'icone': Icons.savings_outlined, 'cor': Colors.blue, 'titulo': 'Invista o Saldo',
          'descricao': 'Você tem R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')} disponível. Considere o Tesouro Selic ou CDB.'});
    }

    dicas.add({'icone': Icons.lightbulb_outline, 'cor': Colors.yellow, 'titulo': 'Regra 50/30/20',
        'descricao': 'Distribua: 50% para necessidades, 30% para desejos, 20% para poupança e investimentos.'});

    dicas.add({'icone': Icons.calendar_today_outlined, 'cor': Colors.teal, 'titulo': 'Reserva de Emergência',
        'descricao': 'Mantenha 6 meses de despesas guardadas. Meta: R\$ ${(totalGastos * 6).toStringAsFixed(2).replaceAll('.', ',')}.'});

    setState(() { _dados = {'ganhos': totalGanhos, 'gastos': totalGastos, 'saldo': saldo, 'taxa': taxa}; _dicas = dicas; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Dicas IA', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(), SizedBox(height: 16),
              Text('Analisando suas finanças...', style: TextStyle(color: Colors.white54)),
            ]))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF7B1FA2)]),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Análise de Saúde Financeira', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _Stat('Ganhos', 'R\$ ${_dados['ganhos']!.toStringAsFixed(0)}', Colors.green),
                      _Stat('Gastos', 'R\$ ${_dados['gastos']!.toStringAsFixed(0)}', Colors.red),
                      _Stat('Saldo', 'R\$ ${_dados['saldo']!.toStringAsFixed(0)}', Colors.blue),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
                const Text('Dicas Personalizadas', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ..._dicas.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(d['icone'] as IconData, color: d['cor'] as Color, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['titulo'], style: TextStyle(color: d['cor'] as Color, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(d['descricao'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ])),
                  ]),
                )),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  const _Stat(this.label, this.valor, this.cor);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      Text(valor, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }
}
