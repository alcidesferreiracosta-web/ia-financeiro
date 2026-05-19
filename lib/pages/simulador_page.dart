import 'dart:math';
import 'package:flutter/material.dart';

class SimuladorPage extends StatefulWidget {
  const SimuladorPage({super.key});
  @override
  State<SimuladorPage> createState() => _SimuladorPageState();
}

class _SimuladorPageState extends State<SimuladorPage> {
  final _ctrl = TextEditingController(text: '100');
  int _anos = 5;

  double _fv(double pmt, double rAnual, int anos) {
    if (pmt <= 0 || rAnual <= 0) return pmt * anos * 12;
    final r = pow(1.0 + rAnual, 1.0 / 12.0).toDouble() - 1.0;
    final n = anos * 12;
    return pmt * (pow(1.0 + r, n).toDouble() - 1.0) / r;
  }

  String _fmt(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pmt = double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 100;
    final totalInvestido = pmt * _anos * 12;
    final cdb = _fv(pmt, 0.105, _anos);
    final selic = _fv(pmt, 0.1075, _anos);
    final colchao = totalInvestido;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Quanto eu teria se...',
            style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A2A3A),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('Se eu separasse todo mês...',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('R\$ ',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '100',
                          hintStyle: TextStyle(color: Colors.white24)),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Text('por quantos anos?',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1, 2, 5, 10, 20].map((a) {
                      final sel = _anos == a;
                      return GestureDetector(
                        onTap: () => setState(() => _anos = a),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? Colors.orange : Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${a}a',
                              style: TextStyle(
                                  color: sel ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList()),
              ]),
            ),

            const SizedBox(height: 24),

            Text('Em $_anos ano${_anos > 1 ? 's' : ''}, eu teria:',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(
                'Total investido: ${_fmt(totalInvestido)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),

            const SizedBox(height: 14),

            _Cenario(
              label: 'Investido em CDB',
              sublabel: '10,5% ao ano',
              valor: cdb,
              ganho: cdb - totalInvestido,
              cor: Colors.greenAccent,
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 10),
            _Cenario(
              label: 'Tesouro Selic',
              sublabel: '10,75% ao ano',
              valor: selic,
              ganho: selic - totalInvestido,
              cor: Colors.blueAccent,
              icon: Icons.account_balance,
            ),
            const SizedBox(height: 10),
            _Cenario(
              label: 'Guardado no colchão',
              sublabel: 'Sem rendimento',
              valor: colchao,
              ganho: 0,
              cor: Colors.orange,
              icon: Icons.bedroom_parent_outlined,
            ),
            const SizedBox(height: 10),
            _Cenario(
              label: 'Gasto em delivery/lazer',
              sublabel: 'Sem acúmulo',
              valor: 0,
              ganho: -(totalInvestido),
              cor: Colors.redAccent,
              icon: Icons.fastfood_outlined,
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.lightbulb, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Investindo no CDB vs gastando, você teria ${_fmt(cdb)} a mais em $_anos anos!',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cenario extends StatelessWidget {
  final String label, sublabel;
  final double valor, ganho;
  final Color cor;
  final IconData icon;

  const _Cenario({
    required this.label,
    required this.sublabel,
    required this.valor,
    required this.ganho,
    required this.cor,
    required this.icon,
  });

  String _fmt(double v) =>
      'R\$ ${v.abs().toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: cor.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: cor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(sublabel,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(valor > 0 ? _fmt(valor) : 'R\$ 0,00',
              style: TextStyle(
                  color: cor, fontSize: 16, fontWeight: FontWeight.bold)),
          if (ganho != 0)
            Text(
              ganho > 0 ? '+${_fmt(ganho)} rendido' : '-${_fmt(ganho)} perdido',
              style: TextStyle(
                  color: ganho > 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 10),
            ),
        ]),
      ]),
    );
  }
}
