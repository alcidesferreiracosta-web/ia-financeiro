import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssistentePage extends StatefulWidget {
  const AssistentePage({super.key});
  @override
  State<AssistentePage> createState() => _AssistentePageState();
}

class _AssistentePageState extends State<AssistentePage> {
  final _mensagemController = TextEditingController();
  final List<Map<String, String>> _mensagens = [];
  bool _loading = false;

  Future<Map<String, double>> _buscarDados() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ganhos = await FirebaseFirestore.instance.collection('ganhos').where('userId', isEqualTo: uid).get();
    final gastos = await FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: uid).get();
    double totalGanhos = ganhos.docs.fold(0, (s, d) => s + (d['valor'] as num).toDouble());
    double totalGastos = gastos.docs.fold(0, (s, d) => s + (d['valor'] as num).toDouble());
    return {'ganhos': totalGanhos, 'gastos': totalGastos, 'saldo': totalGanhos - totalGastos};
  }

  Future<void> _enviar() async {
    if (_mensagemController.text.trim().isEmpty) return;
    final pergunta = _mensagemController.text.trim();
    setState(() {
      _mensagens.add({'role': 'user', 'content': pergunta});
      _mensagemController.clear();
      _loading = true;
    });

    final dados = await _buscarDados();
    await Future.delayed(const Duration(milliseconds: 800));

    final resposta = _gerarResposta(pergunta, dados);
    setState(() {
      _mensagens.add({'role': 'assistant', 'content': resposta});
      _loading = false;
    });
  }

  String _gerarResposta(String pergunta, Map<String, double> dados) {
    final p = pergunta.toLowerCase();
    final saldo = dados['saldo']!;
    final ganhos = dados['ganhos']!;
    final gastos = dados['gastos']!;
    final taxa = ganhos > 0 ? (gastos / ganhos * 100).toStringAsFixed(1) : '0';

    if (p.contains('saldo') || p.contains('quanto tenho')) {
      return 'Seu saldo atual é R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')}. '
          'Você ganhou R\$ ${ganhos.toStringAsFixed(2).replaceAll('.', ',')} e gastou '
          'R\$ ${gastos.toStringAsFixed(2).replaceAll('.', ',')}.';
    }
    if (p.contains('economizar') || p.contains('gastar menos')) {
      return 'Você está gastando $taxa% dos seus ganhos. '
          '${double.parse(taxa) > 70 ? 'Atenção: isso está alto! Tente reduzir gastos supérfluos.' : 'Bom controle! Mantenha assim.'} '
          'Dica: separe 20% do salário assim que receber para poupança.';
    }
    if (p.contains('investir') || p.contains('investimento')) {
      return 'Com saldo de R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')}, sugiro:\n'
          '• Tesouro Selic: segurança e liquidez diária\n'
          '• CDB 100% CDI: rendimento próximo ao Tesouro\n'
          '• Comece com pelo menos R\$ 30,00';
    }
    if (p.contains('dívida') || p.contains('divida')) {
      return 'Para sair das dívidas mais rápido:\n'
          '1. Liste todas as dívidas por taxa de juros\n'
          '2. Pague o mínimo de todas\n'
          '3. Direcione o extra para a de maior juros\n'
          '4. Negocie descontos para pagamento à vista';
    }
    return 'Com base nos seus dados (ganhos: R\$ ${ganhos.toStringAsFixed(2).replaceAll('.', ',')}, '
        'gastos: R\$ ${gastos.toStringAsFixed(2).replaceAll('.', ',')}), '
        'posso ajudar com orçamento, investimentos, economias e planejamento. '
        'O que você quer saber especificamente?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Assistente Financeiro IA', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _mensagens.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.psychology, color: Color(0xFF7B1FA2), size: 64),
                      const SizedBox(height: 16),
                      const Text('Olá! Sou seu assistente financeiro.', style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Pergunte sobre:\n• Como economizar\n• Investimentos\n• Saldo e gastos\n• Dívidas',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensagens.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _mensagens.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(children: [
                            SizedBox(width: 8),
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Analisando...', style: TextStyle(color: Colors.white54)),
                          ]),
                        );
                      }
                      final m = _mensagens[i];
                      final isUser = m['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFF1A237E) : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(m['content']!, style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0D1B2A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensagemController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Pergunte algo sobre suas finanças...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF7B1FA2),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _loading ? null : _enviar,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
