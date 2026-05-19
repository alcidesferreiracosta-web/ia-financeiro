import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanejamentoPage extends StatefulWidget {
  const PlanejamentoPage({super.key});
  @override
  State<PlanejamentoPage> createState() => _PlanejamentoPageState();
}

class _PlanejamentoPageState extends State<PlanejamentoPage> {
  final _metaController = TextEditingController();
  double _metaValor = 0;
  bool _mostrarSimulador = false;

  static const _meses = [
    '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  String get _mesAtual {
    final now = DateTime.now();
    return '${_meses[now.month]} ${now.year}';
  }

  String _tempo(double meses) {
    int m = meses.ceil().clamp(1, 9999);
    int anos = m ~/ 12;
    int resto = m % 12;
    if (anos == 0) return '$m ${m == 1 ? 'mês' : 'meses'}';
    if (resto == 0) return '$anos ${anos == 1 ? 'ano' : 'anos'}';
    return '$anos ${anos == 1 ? 'ano' : 'anos'} e $resto meses';
  }

  // n = log(1 + FV*r/PMT) / log(1+r) onde r = taxa mensal
  double _calcularMeses(double meta, double pmt, double taxaAnual) {
    if (pmt <= 0 || meta <= 0) return 9999;
    if (taxaAnual == 0) return meta / pmt;
    double r = pow(1 + taxaAnual, 1 / 12).toDouble() - 1;
    double numerador = log(1 + meta * r / pmt);
    double denominador = log(1 + r);
    if (denominador <= 0) return meta / pmt;
    return numerador / denominador;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(child: Text('Faça login para ver o planejamento.',
            style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Planejamento Mensal', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder(
        future: Future.wait([
          FirebaseFirestore.instance.collection('ganhos').where('userId', isEqualTo: user.uid).get(),
          FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: user.uid).get(),
        ]),
        builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7)));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Erro ao carregar dados:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
            ));
          }

          double ganhos = 0, gastos = 0;
          if (snapshot.hasData) {
            ganhos = snapshot.data![0].docs.fold(0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
            gastos = snapshot.data![1].docs.fold(0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
          }
          double saldo = ganhos - gastos;
          double pct = ganhos > 0 ? (gastos / ganhos * 100).clamp(0.0, 100.0) : 0;
          double poupancaSugerida = ganhos * 0.2;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Resumo de $_mesAtual',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _ResumoItem('Receitas', ganhos, Colors.green, Icons.arrow_upward),
              const SizedBox(height: 8),
              _ResumoItem('Despesas', gastos, Colors.red, Icons.arrow_downward),
              const SizedBox(height: 8),
              _ResumoItem('Saldo disponível', saldo,
                  saldo >= 0 ? const Color(0xFF4FC3F7) : Colors.red, Icons.account_balance_wallet),
              const SizedBox(height: 24),

              const Text('Comprometimento da Renda',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(
                      pct > 80 ? Colors.red : pct > 60 ? Colors.orange : Colors.green),
                  minHeight: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ganhos > 0
                    ? '${pct.toStringAsFixed(1)}% comprometido${pct > 80 ? ' ⚠️ Muito alto!' : pct > 60 ? ' — Atenção' : ' ✅ Bom controle!'}'
                    : 'Adicione ganhos para ver o comprometimento',
                style: TextStyle(
                    color: pct > 80 ? Colors.redAccent : Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),

              const Text('Distribuição Ideal — Regra 50-30-20',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              if (ganhos > 0) ...[
                _DistItem('🏠 Necessidades (50%)', ganhos * 0.5, Colors.blue,
                    'Aluguel, alimentação, transporte, saúde'),
                const SizedBox(height: 8),
                _DistItem('🎮 Desejos (30%)', ganhos * 0.3, Colors.purple,
                    'Lazer, roupas, restaurante'),
                const SizedBox(height: 8),
                _DistItem('💰 Poupança (20%)', poupancaSugerida, Colors.green,
                    'Investimentos + reserva de emergência'),
              ] else
                _InfoBox('Adicione seus ganhos mensais para ver como distribuir sua renda.'),

              const SizedBox(height: 24),
              const Text('Metas Sugeridas',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _Meta('🛡️ Reserva de emergência (6 meses)',
                  gastos > 0 ? gastos * 6 : ganhos * 3, Colors.orange),
              const SizedBox(height: 8),
              _Meta('💰 Poupança mensal ideal (20%)', poupancaSugerida, Colors.green),
              const SizedBox(height: 24),

              // Simulador de meta
              GestureDetector(
                onTap: () => setState(() => _mostrarSimulador = !_mostrarSimulador),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF283593)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calculate_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Simular meta financeira',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Icon(_mostrarSimulador ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white),
                  ]),
                ),
              ),

              if (_mostrarSimulador) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Qual o valor da sua meta?',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _metaController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Ex: 50000',
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixIcon: const Icon(Icons.attach_money, color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        onChanged: (v) {
                          final val = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                          setState(() => _metaValor = val);
                        },
                      ),
                      if (_metaValor > 0 && poupancaSugerida > 0) ...[
                        const SizedBox(height: 16),
                        Text('Guardando R\$ ${poupancaSugerida.toStringAsFixed(2).replaceAll('.', ',')} por mês (20% da renda):',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        _LinhaCalculo('❌ Sem investir',
                            _calcularMeses(_metaValor, poupancaSugerida, 0), _tempo),
                        const SizedBox(height: 6),
                        _LinhaCalculo('🟡 Tesouro Selic 10,75% a.a.',
                            _calcularMeses(_metaValor, poupancaSugerida, 0.1075), _tempo),
                        const SizedBox(height: 6),
                        _LinhaCalculo('🟢 LCI/LCA 10% a.a. (sem IR)',
                            _calcularMeses(_metaValor, poupancaSugerida, 0.10), _tempo),
                        const SizedBox(height: 6),
                        _LinhaCalculo('🔵 CDB 12% a.a.',
                            _calcularMeses(_metaValor, poupancaSugerida, 0.12), _tempo,
                            destaque: true),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(0.3))),
                          child: const Text(
                            '💡 Use CDB 12% a.a. em bancos digitais\n(Nubank, Inter, PicPay) para chegar mais rápido!',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                          ),
                        ),
                      ] else if (_metaValor > 0 && ganhos == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text('Adicione seus ganhos para ver o cálculo.',
                              style: TextStyle(color: Colors.white54)),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icone, color: cor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        Text('R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    );
  }
}

class _DistItem extends StatelessWidget {
  final String label;
  final double valor;
  final Color cor;
  final String descricao;
  const _DistItem(this.label, this.valor, this.cor, this.descricao);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          border: Border.all(color: cor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: cor.withOpacity(0.05)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label,
              style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 13))),
          Text('R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text(descricao, style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
          color: cor.withOpacity(0.05)),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        Text('R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String texto;
  const _InfoBox(this.texto);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Text(texto,
          style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
    );
  }
}

class _LinhaCalculo extends StatelessWidget {
  final String label;
  final double meses;
  final String Function(double) tempo;
  final bool destaque;
  const _LinhaCalculo(this.label, this.meses, this.tempo, {this.destaque = false});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(label, style: TextStyle(
          color: destaque ? const Color(0xFF4FC3F7) : Colors.white54, fontSize: 13))),
      Text(tempo(meses), style: TextStyle(
          color: destaque ? const Color(0xFF4FC3F7) : Colors.white,
          fontWeight: destaque ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
    ]);
  }
}
