import 'package:flutter/material.dart';

class _Divida {
  String nome;
  double valor;
  double jurosMes;
  _Divida({required this.nome, required this.valor, required this.jurosMes});
}

class SairDividasPage extends StatefulWidget {
  const SairDividasPage({super.key});
  @override
  State<SairDividasPage> createState() => _SairDividasPageState();
}

class _SairDividasPageState extends State<SairDividasPage> {
  final List<_Divida> _dividas = [];
  final _nomeCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _jurosCtrl = TextEditingController();
  final _pagamentoCtrl = TextEditingController(text: '500');

  String _fmt(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  int _mesesParaQuitar(double valor, double jurosMes, double pagamento) {
    if (pagamento <= 0) return 9999;
    double saldo = valor;
    int meses = 0;
    while (saldo > 0 && meses < 600) {
      saldo += saldo * (jurosMes / 100);
      saldo -= pagamento;
      meses++;
    }
    return meses < 600 ? meses : 9999;
  }

  double _totalJuros(double valor, double jurosMes, double pagamento, int meses) {
    if (meses >= 600) return 0;
    return (pagamento * meses) - valor;
  }

  void _adicionarDivida() {
    final nome = _nomeCtrl.text.trim();
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0;
    final juros = double.tryParse(_jurosCtrl.text.replaceAll(',', '.')) ?? 0;
    if (nome.isEmpty || valor <= 0) return;
    setState(() {
      _dividas.add(_Divida(nome: nome, valor: valor, jurosMes: juros));
      _nomeCtrl.clear();
      _valorCtrl.clear();
      _jurosCtrl.clear();
    });
    Navigator.pop(context);
  }

  void _mostrarForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2A3A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Nova Dívida',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _Field(ctrl: _nomeCtrl, label: 'Nome da dívida', icon: Icons.label_outline),
          const SizedBox(height: 12),
          _Field(ctrl: _valorCtrl, label: 'Valor total (R\$)', icon: Icons.attach_money, number: true),
          const SizedBox(height: 12),
          _Field(ctrl: _jurosCtrl, label: 'Juros ao mês (%)', icon: Icons.percent, number: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _adicionarDivida,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Adicionar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _valorCtrl.dispose();
    _jurosCtrl.dispose();
    _pagamentoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagamento = double.tryParse(_pagamentoCtrl.text.replaceAll(',', '.')) ?? 500;

    // Avalanche: ordena por maior juros primeiro
    final ordenadas = List<_Divida>.from(_dividas)
      ..sort((a, b) => b.jurosMes.compareTo(a.jurosMes));

    final totalDivida = _dividas.fold(0.0, (s, d) => s + d.valor);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Sair das Dívidas', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.orange),
            onPressed: _mostrarForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_dividas.isEmpty)
              Center(
                child: Column(children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 72),
                  const SizedBox(height: 16),
                  const Text('Nenhuma dívida cadastrada!',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Toque no + para adicionar uma dívida\ne calcular o plano de saída.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _mostrarForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar dívida'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]),
              )
            else ...[
              // Total card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF880E4F)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.money_off, color: Colors.white70, size: 32),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('TOTAL EM DÍVIDAS', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text(_fmt(totalDivida),
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ),

              const SizedBox(height: 20),

              // Pagamento mensal input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A2A3A),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.payments_outlined, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Text('Pago por mês: R\$ ',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _pagamentoCtrl,
                      style: const TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '500',
                          hintStyle: TextStyle(color: Colors.white24)),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              const Text('Estratégia Avalanche (pague as dívidas de maior juros primeiro)',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('Plano de pagamento',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ...ordenadas.asMap().entries.map((e) {
                final i = e.key;
                final d = e.value;
                final meses = _mesesParaQuitar(d.valor, d.jurosMes, pagamento);
                final juros = _totalJuros(d.valor, d.jurosMes, pagamento, meses);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2A3A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: i == 0 ? Colors.redAccent.withOpacity(0.5) : Colors.white12),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: i == 0 ? Colors.redAccent : Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(d.nome,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(_fmt(d.valor),
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          '${d.jurosMes}% a.m. · '
                          '${meses < 600 ? '$meses meses' : 'pagamento insuficiente'}'
                          '${meses < 600 && juros > 0 ? ' · +${_fmt(juros)} em juros' : ''}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
                      onPressed: () => setState(() => _dividas.remove(d)),
                    ),
                  ]),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool number;
  const _Field(
      {required this.ctrl,
      required this.label,
      required this.icon,
      this.number = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType:
          number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
