import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssistentePage extends StatefulWidget {
  const AssistentePage({super.key});
  @override
  State<AssistentePage> createState() => _AssistentePageState();
}

class _AssistentePageState extends State<AssistentePage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _msgs = [];
  bool _loading = false;

  // Estado da conversa
  String? _contexto;
  String? _goalNome;
  double? _goalValor;
  double? _rendaConversa;

  @override
  void initState() {
    super.initState();
    _msgs.add({'role': 'assistant', 'content':
      'Olá! Sou seu assistente financeiro com IA. 💰\n\n'
      'Posso te ajudar com:\n'
      '• Calcular quanto tempo para comprar um carro, casa, viagem\n'
      '• Comparar CDB, Tesouro Direto, LCI/LCA\n'
      '• Saldo, gastos e dicas de economia\n\n'
      'Tente me dizer: "Quero comprar um carro e ganho 3 mil por mês"'
    });
  }

  Future<Map<String, double>> _buscarDados() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {'ganhos': 0, 'gastos': 0, 'saldo': 0};
      final uid = user.uid;
      final g1 = await FirebaseFirestore.instance.collection('ganhos').where('userId', isEqualTo: uid).get();
      final g2 = await FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: uid).get();
      double ganhos = g1.docs.fold(0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
      double gastos = g2.docs.fold(0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
      return {'ganhos': ganhos, 'gastos': gastos, 'saldo': ganhos - gastos};
    } catch (_) {
      return {'ganhos': 0, 'gastos': 0, 'saldo': 0};
    }
  }

  Future<void> _enviar() async {
    if (_controller.text.trim().isEmpty) return;
    final pergunta = _controller.text.trim();
    setState(() {
      _msgs.add({'role': 'user', 'content': pergunta});
      _controller.clear();
      _loading = true;
    });
    _rolarParaBaixo();

    final dados = await _buscarDados();
    await Future.delayed(const Duration(milliseconds: 700));

    final resposta = _responder(pergunta, dados);
    if (mounted) {
      setState(() {
        _msgs.add({'role': 'assistant', 'content': resposta});
        _loading = false;
      });
      _rolarParaBaixo();
    }
  }

  void _rolarParaBaixo() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _norm(String s) => s.toLowerCase()
      .replaceAll('ã', 'a').replaceAll('á', 'a').replaceAll('â', 'a')
      .replaceAll('é', 'e').replaceAll('ê', 'e').replaceAll('í', 'i')
      .replaceAll('ó', 'o').replaceAll('ô', 'o').replaceAll('ú', 'u')
      .replaceAll('ç', 'c').replaceAll('õ', 'o');

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String _tempo(double meses) {
    int m = meses.ceil().clamp(1, 9999);
    int anos = m ~/ 12;
    int resto = m % 12;
    if (anos == 0) return '$m ${m == 1 ? 'mês' : 'meses'}';
    if (resto == 0) return '$anos ${anos == 1 ? 'ano' : 'anos'}';
    return '$anos ${anos == 1 ? 'ano' : 'anos'} e $resto ${resto == 1 ? 'mês' : 'meses'}';
  }

  double? _extrairNumero(String texto) {
    // "50 mil", "3mil", "50.000", "50000", "R$ 3.000"
    final t = texto.replaceAll(RegExp(r'R\$\s?'), '').trim();
    final milReg = RegExp(r'(\d+(?:[,.]\d+)?)\s*mil', caseSensitive: false);
    final milMatch = milReg.firstMatch(t);
    if (milMatch != null) {
      final n = double.tryParse(milMatch.group(1)!.replaceAll(',', '.'));
      if (n != null) return n * 1000;
    }
    // Remove pontos de milhar, substitui vírgula decimal
    final clean = t.replaceAll(RegExp(r'[^\d,.]'), '')
        .replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(clean);
  }

  double? _extrairRenda(String texto) {
    final p = _norm(texto);
    final patterns = [
      RegExp(r'ganho\s+(?:de\s+)?(.+?)(?:\s+(?:por\s+mes|mensais|reais|r\$)|\s*$)', caseSensitive: false),
      RegExp(r'salario\s+(?:de\s+)?(.+?)(?:\s+(?:por\s+mes|mensais|reais|r\$)|\s*$)', caseSensitive: false),
      RegExp(r'recebo\s+(?:de\s+)?(.+?)(?:\s+(?:por\s+mes|mensais|reais|r\$)|\s*$)', caseSensitive: false),
      RegExp(r'renda\s+(?:de\s+)?(.+?)(?:\s+(?:por\s+mes|mensais|reais|r\$)|\s*$)', caseSensitive: false),
    ];
    for (final pat in patterns) {
      final m = pat.firstMatch(p);
      if (m != null) {
        final v = _extrairNumero(m.group(1) ?? '');
        if (v != null && v > 0) return v;
      }
    }
    return null;
  }

  String? _detectarObjetivo(String p) {
    final objetivos = {
      'carro': ['carro', 'carro novo', 'carro usado', 'automovel', 'veiculo'],
      'moto': ['moto', 'motocicleta'],
      'casa': ['casa', 'imovel', 'apartamento', 'apto'],
      'viagem': ['viagem', 'viajar', 'ferias', 'trip'],
      'notebook': ['notebook', 'computador', 'pc', 'laptop'],
      'celular': ['celular', 'iphone', 'smartphone'],
      'tv': ['televisao', 'tv', 'televisor'],
      'investimento': ['investir', 'investimento'],
    };
    for (final entry in objetivos.entries) {
      for (final kw in entry.value) {
        if (p.contains(kw)) return entry.key;
      }
    }
    return null;
  }

  String _calcularMeta(double meta, double renda, String nomeGoal) {
    // Sugere poupar 25% da renda; se insuficiente, 30%
    double poupanca = renda * 0.25;
    if (poupanca <= 0) poupanca = 500;

    double calcMeses(double pmt, double taxaAnual) {
      if (taxaAnual == 0) return meta / pmt;
      double r = pow(1 + taxaAnual, 1 / 12).toDouble() - 1;
      if (pmt >= meta * r + meta) return 0; // valor inicial já cobre
      return log(1 + meta * r / pmt) / log(1 + r);
    }

    double semJuros = meta / poupanca;
    double mCDB = calcMeses(poupanca, 0.12);
    double mSelic = calcMeses(poupanca, 0.1075);
    double mLCI = calcMeses(poupanca, 0.10);
    double economiaVsCDB = semJuros - mCDB;

    _contexto = null;
    _goalValor = null;

    return '🎯 Planejamento: $nomeGoal\n'
        '━━━━━━━━━━━━━━━━━━━\n'
        '💰 Meta: ${_fmt(meta)}\n'
        '📈 Sua renda: ${_fmt(renda)}/mês\n'
        '💵 Guardar por mês: ${_fmt(poupanca)} (25%)\n\n'
        '⏱️ Quanto tempo vai levar:\n\n'
        '❌ Sem investir (dinheiro parado):\n'
        '   → ${_tempo(semJuros)}\n\n'
        '🟡 Tesouro Selic ~10,75% a.a.:\n'
        '   → ${_tempo(mSelic)}\n\n'
        '🟢 LCI/LCA ~10% a.a. (isento IR):\n'
        '   → ${_tempo(mLCI)}\n\n'
        '🔵 CDB 12% a.a. (melhor opção):\n'
        '   → ${_tempo(mCDB)} ✅\n'
        '   → Economia: ${economiaVsCDB.round()} meses a mais!\n\n'
        '📌 Recomendação: CDB de 12% a.a. em banco digital (Nubank, Inter, PicPay).\n\n'
        '💡 Dica: todo dia de pagamento transfira automaticamente ${_fmt(poupanca)} para o investimento. '
        'Não veja esse dinheiro como disponível!';
  }

  String _responder(String pergunta, Map<String, double> dados) {
    final p = _norm(pergunta);
    final renda = _rendaConversa ?? dados['ganhos']!;
    final gastos = dados['gastos']!;
    final saldo = dados['saldo']!;

    // Extrai renda mencionada na mensagem
    final rendaMsg = _extrairRenda(pergunta);
    if (rendaMsg != null) _rendaConversa = rendaMsg;

    // ── Contexto: aguardando valor da meta ──
    if (_contexto == 'aguardando_valor_meta') {
      final valor = _extrairNumero(pergunta);
      if (valor != null && valor > 0) {
        _goalValor = valor;
        final rendaCalc = _rendaConversa ?? renda;
        if (rendaCalc <= 0) {
          _contexto = 'aguardando_renda';
          return 'Entendido! ${_fmt(valor)} para ${_goalNome ?? 'sua meta'}.\n\nQual é a sua renda mensal? (salário ou ganhos totais por mês)';
        }
        return _calcularMeta(valor, rendaCalc, _goalNome ?? 'meta');
      }
      return 'Não entendi o valor. Me diga em reais:\nExemplo: "50 mil" ou "50000" ou "R\$ 50.000"';
    }

    // ── Contexto: aguardando renda ──
    if (_contexto == 'aguardando_renda') {
      final rendaR = _extrairNumero(pergunta);
      if (rendaR != null && rendaR > 0) {
        _rendaConversa = rendaR;
        if (_goalValor != null) {
          return _calcularMeta(_goalValor!, rendaR, _goalNome ?? 'meta');
        }
        _contexto = null;
        return 'Renda de ${_fmt(rendaR)}/mês anotada! O que você quer calcular?\n\nExemplo: "Quero comprar um carro de 50 mil"';
      }
      return 'Não entendi. Digite sua renda mensal. Exemplo: "3000" ou "3 mil"';
    }

    // ── Saudações ──
    if (RegExp(r'\b(oi|ola|bom dia|boa tarde|boa noite|tudo bem|ola)\b').hasMatch(p)) {
      return 'Olá! 😊 Estou aqui para ajudar com suas finanças.\n\n'
          '${renda > 0 ? 'Seu saldo atual: ${_fmt(saldo)}\n\n' : ''}'
          'Me diga o que quer comprar ou alcançar e eu calculo o plano completo!';
    }

    // ── Detecta objetivo de compra/poupança ──
    if (RegExp(r'\b(comprar|adquirir|quero|queria|preciso|sonho|meta|objetivo|juntar|guardar)\b').hasMatch(p)) {
      final objetivo = _detectarObjetivo(p);
      final rendaMsg2 = _rendaConversa ?? rendaMsg;

      // Tentativa de extrair valor direto na mensagem
      final valorDireto = _extrairNumero(pergunta.replaceAll(RegExp(r'ganho .+'), ''));

      if (objetivo != null) _goalNome = objetivo;

      if (valorDireto != null && valorDireto > 0 && rendaMsg2 != null && rendaMsg2 > 0) {
        // Tem tudo na mesma mensagem
        _goalValor = valorDireto;
        return _calcularMeta(valorDireto, rendaMsg2, objetivo ?? 'meta');
      }

      if (objetivo != null) {
        _contexto = 'aguardando_valor_meta';
        final rendaStr = rendaMsg2 != null && rendaMsg2 > 0
            ? '\n\nVi que sua renda é ${_fmt(rendaMsg2)}/mês. 👍' : '';
        return 'Ótimo objetivo! $objetivo${rendaStr}\n\n'
            'Qual é o valor que você precisa?\nExemplo: "50 mil" ou "R\$ 50.000"';
      }

      // Sem objetivo específico mas tem valor + renda
      if (valorDireto != null && valorDireto > 0 && rendaMsg2 != null && rendaMsg2 > 0) {
        _goalValor = valorDireto;
        return _calcularMeta(valorDireto, rendaMsg2, 'meta');
      }
    }

    // ── Saldo ──
    if (RegExp(r'\b(saldo|quanto tenho|meu dinheiro|disponivel|sobrou)\b').hasMatch(p)) {
      final status = saldo >= 0 ? '✅ Saldo positivo!' : '⚠️ Saldo negativo!';
      return '$status\n\n'
          '💰 Saldo: ${_fmt(saldo)}\n'
          '📈 Ganhos: ${_fmt(renda)}\n'
          '📉 Gastos: ${_fmt(gastos)}\n\n'
          '${renda > 0 ? 'Você gastou ${(gastos / renda * 100).toStringAsFixed(1)}% dos seus ganhos.' : ''}';
    }

    // ── Economizar ──
    if (RegExp(r'\b(economizar|poupar|gastar menos|cortar|reducao)\b').hasMatch(p)) {
      return '💡 Para economizar mais:\n\n'
          '1. Regra 50-30-20:\n'
          '   50% necessidades | 30% desejos | 20% poupança\n\n'
          '${renda > 0 ? '   Poupança ideal: ${_fmt(renda * 0.2)}/mês\n\n' : ''}'
          '2. Cancele assinaturas que não usa\n'
          '3. Cozinhe mais em casa\n'
          '4. Compare preços antes de comprar\n'
          '5. Espere 48h antes de comprar por impulso\n\n'
          '💬 Quer calcular quanto tempo para uma meta específica?\n'
          'Ex: "Quero juntar 30 mil para uma viagem"';
    }

    // ── Investir ──
    if (RegExp(r'\b(investir|investimento|aplicar|render|rendimento|cdb|lci|tesouro)\b').hasMatch(p)) {
      return '📊 Melhores investimentos para iniciantes:\n\n'
          '🔵 CDB 12% a.a.\n'
          '   Melhor retorno | Seguro até R\$ 250 mil (FGC)\n'
          '   Bancos: Nubank, Inter, PicPay\n\n'
          '🟡 Tesouro Selic ~10,75% a.a.\n'
          '   100% seguro | Liquidez diária\n'
          '   Ideal para reserva de emergência\n\n'
          '🟢 LCI/LCA ~10% a.a.\n'
          '   Isento de Imposto de Renda\n'
          '   Precisa ter prazo mínimo (90 dias)\n\n'
          '💡 Quer ver quanto tempo para uma meta específica?\n'
          'Ex: "Quero comprar um carro de 50 mil e ganho 3 mil"';
    }

    // ── Dívida ──
    if (RegExp(r'\b(divida|devo|cartao|credito|emprestimo|parcela|juros)\b').hasMatch(p)) {
      return '🎯 Para sair das dívidas:\n\n'
          '1. Liste todas com taxa de juros\n'
          '2. Pague o mínimo de todas\n'
          '3. Todo extra → maior juros (método avalanche)\n'
          '4. Negocie desconto para pagamento à vista\n\n'
          '⚠️ Cartão rotativo cobra 300-400% ao ano!\n'
          'Prioridade: quite o cartão primeiro.\n\n'
          '📞 Se não conseguir: Serasa Limpa Nome tem acordos com desconto de até 99%';
    }

    // ── Planejamento ──
    if (RegExp(r'\b(planejar|planejamento|orcamento|meta|objetivo|mes)\b').hasMatch(p)) {
      final rendaUsar = renda > 0 ? renda : 3000.0;
      return '📅 Planejamento com ${_fmt(rendaUsar)}/mês (regra 50-30-20):\n\n'
          '🏠 Necessidades (50%): ${_fmt(rendaUsar * 0.5)}\n'
          '   Aluguel, alimentação, transporte, saúde\n\n'
          '🎮 Desejos (30%): ${_fmt(rendaUsar * 0.3)}\n'
          '   Lazer, roupas, restaurante\n\n'
          '💰 Poupança (20%): ${_fmt(rendaUsar * 0.2)}\n'
          '   Investimentos + reserva de emergência\n\n'
          '💡 Quer calcular uma meta específica?\n'
          'Ex: "Quero comprar um carro de 50 mil"';
    }

    // ── Resposta padrão inteligente ──
    return '💬 Não entendi completamente, mas posso te ajudar!\n\n'
        'Tente:\n'
        '🚗 "Quero comprar um carro de 50 mil e ganho 3 mil"\n'
        '✈️ "Quero fazer uma viagem de 10 mil"\n'
        '💰 "Como economizar mais?"\n'
        '📈 "Onde investir?"\n'
        '💳 "Tenho dívidas no cartão"\n'
        '📊 "Meu saldo"\n\n'
        '${renda > 0 ? 'Seus dados: ganhos ${_fmt(renda)} | gastos ${_fmt(gastos)} | saldo ${_fmt(saldo)}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Assistente IA', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: () {
              setState(() {
                _msgs.clear();
                _contexto = null;
                _goalNome = null;
                _goalValor = null;
                _rendaConversa = null;
                _msgs.add({'role': 'assistant', 'content': 'Conversa reiniciada! O que você quer calcular?'});
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(14),
              itemCount: _msgs.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _msgs.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      SizedBox(width: 6),
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Calculando...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ]),
                  );
                }
                final m = _msgs[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
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
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                  ),
                );
              },
            ),
          ),

          // Sugestões rápidas
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                'Quero comprar um carro',
                'Meu saldo',
                'Onde investir',
                'Como economizar',
                'Tenho dívidas',
              ].map((s) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: Colors.white10,
                  side: const BorderSide(color: Colors.white12),
                  onPressed: () { _controller.text = s; _enviar(); },
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
            color: const Color(0xFF0D1B2A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ex: Quero comprar um carro de 50 mil...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
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
