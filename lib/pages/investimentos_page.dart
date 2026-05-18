import 'package:flutter/material.dart';

class InvestimentosPage extends StatelessWidget {
  const InvestimentosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final investimentos = [
      {'nome': 'Tesouro Selic', 'tipo': 'Renda Fixa', 'risco': 'Baixo', 'retorno': '~12% a.a.',
       'descricao': 'Título do governo federal. Liquidez diária. Ideal para reserva de emergência.', 'score': 95, 'cor': Colors.green},
      {'nome': 'CDB 100% CDI', 'tipo': 'Renda Fixa', 'risco': 'Baixo', 'retorno': '~12% a.a.',
       'descricao': 'Certificado de Depósito Bancário. Garantido pelo FGC até R\$ 250 mil.', 'score': 88, 'cor': Colors.teal},
      {'nome': 'LCI / LCA', 'tipo': 'Renda Fixa', 'risco': 'Baixo', 'retorno': '~11% a.a.',
       'descricao': 'Isentos de IR para pessoa física. Ótima opção para quem está na faixa alta de IR.', 'score': 82, 'cor': Colors.blue},
      {'nome': 'Fundos Imobiliários', 'tipo': 'Renda Variável', 'risco': 'Médio', 'retorno': '~8-14% a.a.',
       'descricao': 'FIIs pagam dividendos mensais isentos de IR. Diversificação em imóveis.', 'score': 75, 'cor': Colors.orange},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Investimentos', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.psychology, color: Colors.white70), SizedBox(width: 8),
                  Text('Recomendações IA', style: TextStyle(color: Colors.white70, fontSize: 13))]),
              SizedBox(height: 8),
              Text('Baseado no seu perfil, selecionei os melhores investimentos para você.',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
            ]),
          ),
          const SizedBox(height: 20),
          ...investimentos.map((inv) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(inv['nome'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (inv['cor'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Score: ${inv['score']}', style: TextStyle(color: inv['cor'] as Color, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 8),
              Text(inv['descricao'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              Row(children: [
                _Tag(inv['tipo'] as String, Colors.blue),
                const SizedBox(width: 8),
                _Tag('Risco: ${inv['risco']}', inv['risco'] == 'Baixo' ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                _Tag(inv['retorno'] as String, Colors.teal),
              ]),
            ]),
          )),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color cor;
  const _Tag(this.label, this.cor);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: cor, fontSize: 11)),
    );
  }
}
