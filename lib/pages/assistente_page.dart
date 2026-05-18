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
  final _scrollController = ScrollController();
  final List<Map<String, String>> _mensagens = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _mensagens.add({
      'role': 'assistant',
      'content': 'Olá! Sou seu assistente financeiro com IA. 💰\n\nPosso te ajudar com:\n• Saldo e gastos\n• Como economizar\n• Investimentos\n• Dívidas e planejamento\n\nMe pergunte qualquer coisa!',
    });
  }

  Future<Map<String, dynamic>> _buscarDados() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {'ganhos': 0.0, 'gastos': 0.0, 'saldo': 0.0, 'numGastos': 0, 'numGanhos': 0};
      final uid = user.uid;
      final ganhosDocs = await FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: uid).get();
      final gastosDocs = await FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: uid).get();
      final ganhosReal = await FirebaseFirestore.instance.collection('ganhos').where('userId', isEqualTo: uid).get();
      double totalGanhos = ganhosReal.docs.fold(0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
      double totalGastos = gastosDocs.docs.fold(0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
      return {
        'ganhos': totalGanhos,
        'gastos': totalGastos,
        'saldo': totalGanhos - totalGastos,
        'numGastos': gastosDocs.docs.length,
        'numGanhos': ganhosReal.docs.length,
      };
    } catch (_) {
      return {'ganhos': 0.0, 'gastos': 0.0, 'saldo': 0.0, 'numGastos': 0, 'numGanhos': 0};
    }
  }

  Future<void> _enviar() async {
    if (_mensagemController.text.trim().isEmpty) return;
    final pergunta = _mensagemController.text.trim();
    setState(() {
      _mensagens.add({'role': 'user', 'content': pergunta});
      _mensagemController.clear();
      _loading = true;
    });
    _rolarParaBaixo();

    final dados = await _buscarDados();
    await Future.delayed(const Duration(milliseconds: 600));

    final resposta = _gerarResposta(pergunta, dados);
    if (mounted) {
      setState(() {
        _mensagens.add({'role': 'assistant', 'content': resposta});
        _loading = false;
      });
      _rolarParaBaixo();
    }
  }

  void _rolarParaBaixo() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String _gerarResposta(String pergunta, Map<String, dynamic> dados) {
    final p = pergunta.toLowerCase()
        .replaceAll('ã', 'a').replaceAll('ç', 'c').replaceAll('é', 'e')
        .replaceAll('ê', 'e').replaceAll('ó', 'o').replaceAll('á', 'a')
        .replaceAll('í', 'i').replaceAll('ú', 'u').replaceAll('õ', 'o');
    final saldo = (dados['saldo'] as num).toDouble();
    final ganhos = (dados['ganhos'] as num).toDouble();
    final gastos = (dados['gastos'] as num).toDouble();
    final taxa = ganhos > 0 ? (gastos / ganhos * 100) : 0.0;

    // Saudações
    if (p.contains('oi') || p.contains('ola') || p.contains('bom dia') ||
        p.contains('boa tarde') || p.contains('boa noite') || p.contains('tudo bem')) {
      return 'Olá! Estou aqui para te ajudar com suas finanças. 😊\n\nSeu saldo atual é ${_fmt(saldo)}.\n\nO que você gostaria de saber?';
    }

    // Saldo
    if (p.contains('saldo') || p.contains('quanto tenho') || p.contains('meu dinheiro') ||
        p.contains('quanto sobrou') || p.contains('disponivel')) {
      final status = saldo >= 0 ? '✅ Saldo positivo!' : '⚠️ Saldo negativo!';
      return '$status\n\n💰 Saldo: ${_fmt(saldo)}\n📈 Ganhos: ${_fmt(ganhos)}\n📉 Gastos: ${_fmt(gastos)}\n📊 Você gastou ${taxa.toStringAsFixed(1)}% dos seus ganhos.';
    }

    // Gastos
    if (p.contains('gastei') || p.contains('gastos') || p.contains('despesa') ||
        p.contains('quanto gastei') || p.contains('saiu')) {
      return '📉 Seus gastos totais: ${_fmt(gastos)}\n\n${taxa > 80 ? '⚠️ Atenção: você está gastando ${taxa.toStringAsFixed(0)}% dos seus ganhos. Isso é muito alto!' : taxa > 50 ? '⚠️ Você gastou ${taxa.toStringAsFixed(0)}% dos seus ganhos. Tente manter abaixo de 50%.' : '✅ Bom controle! Você gastou ${taxa.toStringAsFixed(0)}% dos seus ganhos.'}\n\nDica: categorize seus gastos para identificar onde cortar.';
    }

    // Ganhos
    if (p.contains('ganhei') || p.contains('ganhos') || p.contains('receita') ||
        p.contains('quanto ganhei') || p.contains('renda')) {
      return '📈 Seus ganhos totais: ${_fmt(ganhos)}\n\nDica: tente diversificar suas fontes de renda. Freelance, investimentos e renda extra podem aumentar muito seus ganhos ao longo do tempo.';
    }

    // Economizar
    if (p.contains('economizar') || p.contains('poupar') || p.contains('gastar menos') ||
        p.contains('reducao') || p.contains('cortar')) {
      return '💡 Dicas para economizar ${_fmt(gastos * 0.2)} por mês:\n\n1. Regra 50-30-20: 50% necessidades, 30% desejos, 20% poupança\n2. Cancele assinaturas que não usa\n3. Cozinhe mais em casa\n4. Compare preços antes de comprar\n5. Evite compras por impulso — espere 48h\n\nSeu potencial de economia: ${_fmt(saldo > 0 ? saldo * 0.3 : 0)}';
    }

    // Investir
    if (p.contains('investir') || p.contains('investimento') || p.contains('aplicar') ||
        p.contains('render') || p.contains('rendimento')) {
      if (saldo < 100) {
        return '💡 Você ainda não tem saldo suficiente para investir.\n\nPrimeiro, tente juntar uma reserva de emergência de pelo menos ${_fmt(ganhos * 3)} (3 meses de ganhos).\n\nEnquanto isso: Nubank e PicPay oferecem rendimento automático no saldo da conta.';
      }
      return '📊 Com ${_fmt(saldo)} disponível, sugestões:\n\n🟢 Reserva emergência (prioridade):\n• Tesouro Selic — 100% seguro, liquidez diária\n• CDB com liquidez diária — bancos digitais\n\n🟡 Renda fixa (após reserva):\n• CDB 110-120% CDI — prazo 1-2 anos\n• LCI/LCA — isento de IR\n\n🔵 Longo prazo (5+ anos):\n• Fundos Imobiliários (FIIs)\n• Tesouro IPCA+\n\nComece com pelo menos R\$ 30,00 no Tesouro Direto!';
    }

    // Dívidas
    if (p.contains('divida') || p.contains('devo') || p.contains('cartao') ||
        p.contains('credito') || p.contains('emprestimo') || p.contains('parcela')) {
      return '🎯 Estratégia para sair das dívidas:\n\n1. Liste todas as dívidas com taxa de juros\n2. Pague o mínimo de todas\n3. Direcione todo extra para a de MAIOR juros (método avalanche)\n4. Negocie desconto para pagamento à vista\n5. Evite cartão de crédito rotativo (juros de 400% ao ano!)\n\n⚠️ Nunca pague uma dívida com outra! Busque renegociação.';
    }

    // Reserva de emergência
    if (p.contains('emergencia') || p.contains('reserva') || p.contains('guardar')) {
      final meta = ganhos * 6;
      return '🛡️ Reserva de emergência:\n\nMeta ideal: ${_fmt(meta)} (6 meses de ganhos)\n\nOnde guardar:\n• Tesouro Selic (mais rentável)\n• CDB com liquidez diária\n• Conta remunerada (Nubank, Inter)\n\nNUNCA invista a reserva em renda variável! Precisa ser acessível a qualquer momento.';
    }

    // Planejamento / orçamento
    if (p.contains('planejar') || p.contains('planejamento') || p.contains('orcamento') ||
        p.contains('meta') || p.contains('objetivo') || p.contains('budget')) {
      return '📅 Planejamento financeiro mensal:\n\nCom ganhos de ${_fmt(ganhos)}:\n• Necessidades (50%): ${_fmt(ganhos * 0.5)}\n• Lazer (30%): ${_fmt(ganhos * 0.3)}\n• Poupança (20%): ${_fmt(ganhos * 0.2)}\n\nDica: anote seus gastos diariamente. O que é medido, é controlado!';
    }

    // Dica geral / padrão
    return '💬 Com base nos seus dados:\n• Ganhos: ${_fmt(ganhos)}\n• Gastos: ${_fmt(gastos)}\n• Saldo: ${_fmt(saldo)}\n\nPosso te ajudar com:\n📊 "Meu saldo"\n💰 "Como economizar"\n📈 "Onde investir"\n🎯 "Planejamento mensal"\n💳 "Tenho dívidas"\n🛡️ "Reserva de emergência"\n\nO que você quer saber?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Assistente Financeiro IA', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: () => setState(() => _mensagens
              ..clear()
              ..add({'role': 'assistant', 'content': 'Conversa reiniciada. Como posso ajudar?'})),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _mensagens.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _mensagens.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      SizedBox(width: 8),
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Analisando...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ]),
                  );
                }
                final m = _mensagens[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF1565C0) : const Color(0xFF1A2A3A),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(m['content']!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                  ),
                );
              },
            ),
          ),

          // Sugestões rápidas
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['Meu saldo', 'Economizar', 'Investir', 'Planejamento', 'Reserva'].map((s) =>
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: Colors.white10,
                    onPressed: () {
                      _mensagemController.text = s;
                      _enviar();
                    },
                  ),
                ),
              ).toList(),
            ),
          ),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            color: const Color(0xFF0D1B2A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensagemController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Pergunte sobre suas finanças...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0),
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
