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

  // Extrai prazo em meses ("em 12 meses", "em 1 ano", "em 2 anos", "em 6 meses")
  double? _extrairPrazo(String texto) {
    final p = _norm(texto);
    final anosReg = RegExp(r'em\s+(\d+)\s+anos?');
    final mesesReg = RegExp(r'em\s+(\d+)\s+meses?');
    final mA = anosReg.firstMatch(p);
    if (mA != null) return double.parse(mA.group(1)!) * 12;
    final mM = mesesReg.firstMatch(p);
    if (mM != null) return double.parse(mM.group(1)!);
    return null;
  }

  // Cálculo PMT reverso: quanto guardar por mês para atingir meta em N meses
  String _calcularPMT(double meta, double meses, double taxaAnual) {
    double pmt;
    if (taxaAnual == 0) {
      pmt = meta / meses;
    } else {
      final r = pow(1 + taxaAnual, 1 / 12).toDouble() - 1;
      pmt = meta * r / (pow(1 + r, meses).toDouble() - 1);
    }
    return _fmt(pmt);
  }

  // Cálculo de quitar dívida: n = -log(1 - r*PV/PMT) / log(1+r)
  String _calcularQuitarDivida(double divida, double pagamentoMensal, double taxaMensal) {
    if (taxaMensal == 0) {
      final meses = (divida / pagamentoMensal).ceil();
      return _tempo(meses.toDouble());
    }
    if (pagamentoMensal <= divida * taxaMensal) return 'nunca (pagamento menor que os juros!)';
    final n = -log(1 - taxaMensal * divida / pagamentoMensal) / log(1 + taxaMensal);
    return _tempo(n);
  }

  String? _detectarObjetivo(String p) {
    final objetivos = {
      'carro': ['carro', 'automovel', 'veiculo', 'carro novo', 'carro usado'],
      'moto': ['moto', 'motocicleta'],
      'casa': ['casa', 'imovel', 'apartamento', 'apto', 'terreno'],
      'viagem': ['viagem', 'viajar', 'ferias', 'passeio', 'turismo'],
      'notebook': ['notebook', 'computador', 'pc', 'laptop', 'mac'],
      'celular': ['celular', 'iphone', 'smartphone', 'telefone'],
      'tv': ['televisao', 'tv', 'televisor', 'smart tv'],
      'reforma': ['reforma', 'reformar', 'construir', 'construcao'],
      'casamento': ['casamento', 'casar', 'festa'],
      'educacao': ['curso', 'faculdade', 'pos graduacao', 'mba', 'formacao'],
      'investimento': ['investir', 'investimento', 'aplicar'],
    };
    for (final entry in objetivos.entries) {
      for (final kw in entry.value) {
        if (p.contains(kw)) return entry.key;
      }
    }
    return null;
  }

  double _calcMeses(double meta, double pmt, double taxaAnual) {
    if (taxaAnual == 0) return meta / pmt;
    final double r = pow(1 + taxaAnual, 1 / 12).toDouble() - 1;
    if (pmt >= meta * r + meta) return 0.0;
    return log(1 + meta * r / pmt) / log(1 + r);
  }

  String _calcularMeta(double meta, double renda, String nomeGoal) {
    double poupanca = renda * 0.25;
    if (poupanca <= 0) poupanca = 500;

    final double semJuros = meta / poupanca;
    final double mCDB = _calcMeses(meta, poupanca, 0.12);
    final double mSelic = _calcMeses(meta, poupanca, 0.1075);
    final double mLCI = _calcMeses(meta, poupanca, 0.10);
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
          return 'Entendido! ${_fmt(valor)} para ${_goalNome ?? 'sua meta'}.\n\nQual é a sua renda mensal?';
        }
        return _calcularMeta(valor, rendaCalc, _goalNome ?? 'meta');
      }
      return 'Não entendi o valor. Tente: "50 mil" ou "R\$ 50.000"';
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
        return 'Renda de ${_fmt(rendaR)}/mês anotada! O que quer calcular?\n\nEx: "Quero comprar um carro de 50 mil"';
      }
      return 'Digite sua renda mensal. Ex: "3000" ou "3 mil"';
    }

    // ── Saudações ──
    if (RegExp(r'\b(oi|ola|ola|bom dia|boa tarde|boa noite|tudo bem|hey|hello)\b').hasMatch(p)) {
      final resumo = renda > 0
          ? '\n\nSeu resumo:\n💰 Ganhos: ${_fmt(renda)} | Gastos: ${_fmt(gastos)} | Saldo: ${_fmt(saldo)}'
          : '';
      return 'Olá! 😊 Sou sua IA financeira.$resumo\n\n'
          'Posso calcular metas, analisar investimentos, criar planos de economia e muito mais!\n\n'
          'O que você quer hoje?';
    }

    // ── Quanto preciso guardar por mês para atingir X em Y meses? ──
    if (RegExp(r'\b(guardar por mes|poupar por mes|economizar por mes|quanto por mes|quanto guardar|quanto poupar)\b').hasMatch(p)) {
      final meta = _extrairNumero(pergunta);
      final prazo = _extrairPrazo(pergunta);
      if (meta != null && meta > 0 && prazo != null && prazo > 0) {
        final semJuros = _calcularPMT(meta, prazo, 0);
        final comCDB = _calcularPMT(meta, prazo, 0.12);
        final comSelic = _calcularPMT(meta, prazo, 0.1075);
        return '📊 Para juntar ${_fmt(meta)} em ${_tempo(prazo)}:\n\n'
            '❌ Sem investir: $semJuros/mês\n'
            '🟡 Tesouro Selic: $comSelic/mês\n'
            '🔵 CDB 12% a.a.: $comCDB/mês ✅\n\n'
            '💡 Com CDB você economiza dinheiro todo mês comparado a guardar sem investir!';
      }
      if (meta != null && meta > 0) {
        _goalValor = meta;
        _contexto = 'aguardando_prazo_pmt';
        return 'Para calcular quanto guardar por mês para ${_fmt(meta)},\nem quanto tempo quer atingir?\n\nEx: "em 12 meses" ou "em 2 anos"';
      }
      return 'Me diga o valor da sua meta e o prazo.\nEx: "Quanto guardar por mês para 30 mil em 2 anos?"';
    }

    // ── Quitar dívida ──
    if (RegExp(r'\b(quitar|pagar divida|saldar|zerar divida|quanto tempo para pagar|tempo para quitar)\b').hasMatch(p)) {
      final numeros = RegExp(r'\d+(?:[.,]\d+)?(?:\s*mil)?').allMatches(pergunta).toList();
      if (numeros.length >= 2) {
        final divida = _extrairNumero(numeros[0].group(0)!);
        final pagamento = _extrairNumero(numeros[1].group(0)!);
        if (divida != null && pagamento != null && divida > 0 && pagamento > 0) {
          final tempoSemJuros = _calcularQuitarDivida(divida, pagamento, 0);
          final tempoCartao = _calcularQuitarDivida(divida, pagamento, 0.20);
          final tempoPessoal = _calcularQuitarDivida(divida, pagamento, 0.035);
          return '💳 Para quitar ${_fmt(divida)} pagando ${_fmt(pagamento)}/mês:\n\n'
              '✅ Sem juros: $tempoSemJuros\n'
              '🟡 Empréstimo pessoal (~3,5%/mês): $tempoPessoal\n'
              '🔴 Cartão rotativo (~20%/mês): $tempoCartao\n\n'
              '⚠️ O cartão rotativo é o pior! Tente parcelar no banco ou usar FGTS como garantia.';
        }
      }
      return '🎯 Para sair das dívidas:\n\n'
          '1. Liste todas com taxa de juros\n'
          '2. Pague o mínimo de todas\n'
          '3. Todo extra → maior taxa (método avalanche)\n'
          '4. Negocie desconto para pagamento à vista\n\n'
          '⚠️ Cartão rotativo: ~240% ao ano!\n'
          '📞 Serasa Limpa Nome: acordos com desconto de até 99%\n\n'
          '💬 Quer calcular? Me diga: "Tenho dívida de 5 mil, pago 300 por mês"';
    }

    // ── Reserva de emergência ──
    if (RegExp(r'\b(reserva|emergencia|fundo|reserva de emergencia|quanto reservar)\b').hasMatch(p)) {
      final double reservaIdeal = gastos > 0 ? gastos * 6 : (renda > 0 ? renda * 6 : 0.0);
      final double reserva3 = gastos > 0 ? gastos * 3 : (renda > 0 ? renda * 3 : 0.0);
      return '🛡️ Reserva de emergência:\n\n'
          'É o dinheiro para cobrir imprevistos sem entrar em dívidas.\n\n'
          '📌 Regra geral:\n'
          '• Empregado CLT: 3 a 6 meses de gastos\n'
          '• Autônomo/Freela: 6 a 12 meses\n\n'
          '${reservaIdeal > 0 ? '💰 Para você:\n   Mínimo: ${_fmt(reserva3)}\n   Ideal: ${_fmt(reservaIdeal)}\n\n' : ''}'
          '📈 Onde guardar: Tesouro Selic ou CDB com liquidez diária\n'
          '   (não deixe na poupança — rende menos!)\n\n'
          '💡 Comece pequeno: meta de ${renda > 0 ? _fmt(renda * 0.1) : "R\$ 100,00"}/mês';
    }

    // ── Saldo / Situação financeira ──
    if (RegExp(r'\b(saldo|quanto tenho|meu dinheiro|disponivel|situacao|como estou|minha situacao)\b').hasMatch(p)) {
      if (renda == 0 && gastos == 0) {
        return '📊 Sem dados ainda.\nAdicione seus ganhos e gastos no app para eu analisar!';
      }
      final pct = renda > 0 ? (gastos / renda * 100) : 0.0;
      final status = saldo >= 0 ? '✅ Situação positiva!' : '⚠️ Gastos maiores que ganhos!';
      final dica = pct > 80
          ? '🚨 Você está gastando ${pct.toStringAsFixed(0)}% da renda. Corte gastos urgente!'
          : pct > 60
              ? '⚠️ ${pct.toStringAsFixed(0)}% comprometido. Cuidado para não ultrapassar.'
              : '👍 Ótimo controle! ${pct.toStringAsFixed(0)}% comprometido.';
      return '$status\n\n'
          '📈 Ganhos: ${_fmt(renda)}\n'
          '📉 Gastos: ${_fmt(gastos)}\n'
          '💰 Saldo: ${_fmt(saldo)}\n\n'
          '$dica\n\n'
          '${renda > 0 ? '💡 Poupança ideal (20%): ${_fmt(renda * 0.2)}/mês' : ''}';
    }

    // ── Economizar ──
    if (RegExp(r'\b(economizar|poupar|gastar menos|cortar gastos|reducao|gasto alto|diminuir gasto)\b').hasMatch(p)) {
      return '💡 Como economizar mais:\n\n'
          '📌 Regra 50-30-20:\n'
          '   🏠 50% necessidades (aluguel, comida, transporte)\n'
          '   🎮 30% desejos (lazer, roupas)\n'
          '   💰 20% poupança\n\n'
          '${renda > 0 ? '   Sua poupança ideal: ${_fmt(renda * 0.2)}/mês\n\n' : ''}'
          '🔪 Cortes que funcionam:\n'
          '• Cancele assinaturas que não usa\n'
          '• Cozinhe em casa (economiza 40-60% em alimentação)\n'
          '• Espere 48h antes de comprar por impulso\n'
          '• Compare preços sempre\n'
          '• Use transporte público ou carpool\n\n'
          '💬 Quer calcular uma meta de economia? Me diga o valor!';
    }

    // ── Investimentos ──
    if (RegExp(r'\b(investir|investimento|aplicar|render|rendimento|cdb|lci|lca|tesouro|renda fixa|acoes|fundos)\b').hasMatch(p)) {
      return '📊 Melhores investimentos em renda fixa:\n\n'
          '🔵 CDB 12% a.a. — Recomendado\n'
          '   Seguro até R\$ 250 mil (FGC)\n'
          '   Nubank, Inter, PicPay, BTG\n\n'
          '🟡 Tesouro Selic ~10,75% a.a.\n'
          '   100% seguro (governo federal)\n'
          '   Liquidez diária — ideal para reserva\n\n'
          '🟢 LCI/LCA ~10% a.a.\n'
          '   Isento de IR — equivale a ~12% bruto\n'
          '   Prazo mínimo de 90 dias\n\n'
          '📈 Renda variável (para quem já tem reserva):\n'
          '   • Fundos Imobiliários (FIIs) — renda mensal\n'
          '   • Ações — maior risco, maior potencial\n\n'
          '💡 Comece pela reserva de emergência no Tesouro Selic,\ndepois migre para CDB para metas específicas.\n\n'
          '${renda > 0 ? 'Quer calcular quanto tempo para uma meta? Me diga o valor!' : ''}';
    }

    // ── Quanto vale a pena parcelar? ──
    if (RegExp(r'\b(parcelar|parcela|prestacao|vale a pena parcelar|juros do parcelamento)\b').hasMatch(p)) {
      return '💳 Parcelar vale a pena?\n\n'
          '✅ Vale parcelar SEM juros:\n'
          '   • Parcelas não comprometem mais de 30% da renda\n'
          '   • Você investe o valor enquanto parcela (arbitragem)\n\n'
          '❌ NÃO vale parcelar COM juros:\n'
          '   • Cartão rotativo: até 20% ao mês!\n'
          '   • Loja: 3-8% ao mês\n'
          '   • CEF/BB crédito pessoal: 2-4% ao mês\n\n'
          '🧮 Regra simples: se a taxa da parcela > 1%/mês, prefira juntar e pagar à vista.\n\n'
          '${renda > 0 ? '📌 Seu limite saudável de parcelas: ${_fmt(renda * 0.3)}/mês (30% da renda)' : ''}';
    }

    // ── Poupança (conta poupança) ──
    if (RegExp(r'\b(poupanca|caderneta|conta poupanca)\b').hasMatch(p)) {
      return '📊 Sobre a poupança:\n\n'
          '⚠️ A poupança rende pouco!\n'
          '   Taxa atual: ~6,5% ao ano (com Selic alta rende 70% dela)\n\n'
          '📈 Alternativas melhores:\n'
          '   🔵 CDB 12% a.a. — quase o dobro da poupança\n'
          '   🟡 Tesouro Selic ~10,75% a.a. — mais seguro que poupança\n\n'
          '💡 A poupança SÓ vale se você não tem nenhum outro investimento '
          'ou o banco cobra tarifa para outros produtos.\n\n'
          'Para o mesmo risco, CDB e Tesouro rendem muito mais!';
    }

    // ── Salário / renda mensal ──
    if (RegExp(r'\b(salario|quanto devo ganhar|renda minima|salario minimo|aumento|negociar salario)\b').hasMatch(p)) {
      return '💼 Sobre salário e renda:\n\n'
          '📌 Salário mínimo 2024: R\$ 1.412,00\n\n'
          '💡 Para saber se seu salário é justo:\n'
          '• Pesquise sua função no Glassdoor, LinkedIn Salários\n'
          '• Compare com colegas da área\n'
          '• Considere benefícios (VT, VR, plano de saúde)\n\n'
          '🎯 Como pedir aumento:\n'
          '1. Documente suas conquistas com números\n'
          '2. Pesquise o mercado primeiro\n'
          '3. Peça em um bom momento (resultado positivo)\n'
          '4. Tenha uma oferta concorrente se possível\n\n'
          '${renda > 0 ? '💰 Com sua renda de ${_fmt(renda)}, sua poupança ideal é ${_fmt(renda * 0.2)}/mês' : ''}';
    }

    // ── Detecta objetivo de compra/poupança ──
    if (RegExp(r'\b(comprar|adquirir|quero|queria|preciso|sonho|meta|objetivo|juntar|guardar|realizar)\b').hasMatch(p)) {
      final objetivo = _detectarObjetivo(p);
      final rendaMsg2 = _rendaConversa ?? rendaMsg;
      final valorDireto = _extrairNumero(pergunta.replaceAll(RegExp(r'ganho.+|salario.+|renda.+'), ''));

      if (objetivo != null) _goalNome = objetivo;

      if (valorDireto != null && valorDireto > 0 && rendaMsg2 != null && rendaMsg2 > 0) {
        _goalValor = valorDireto;
        return _calcularMeta(valorDireto, rendaMsg2, objetivo ?? 'meta');
      }

      if (objetivo != null) {
        _contexto = 'aguardando_valor_meta';
        final rendaStr = rendaMsg2 != null && rendaMsg2 > 0
            ? '\n(Vi que sua renda é ${_fmt(rendaMsg2)}/mês 👍)' : '';
        return 'Ótimo! Vamos planejar o(a) $objetivo.$rendaStr\n\n'
            'Qual o valor que você precisa?\nEx: "50 mil" ou "R\$ 50.000"';
      }

      if (valorDireto != null && valorDireto > 0) {
        if (rendaMsg2 != null && rendaMsg2 > 0) {
          return _calcularMeta(valorDireto, rendaMsg2, 'meta');
        }
        _goalValor = valorDireto;
        _contexto = 'aguardando_renda';
        return 'Meta de ${_fmt(valorDireto)} anotada! 🎯\n\nQual é sua renda mensal?';
      }
    }

    // ── Planejamento geral ──
    if (RegExp(r'\b(planejar|planejamento|orcamento|organizar|financas|controle)\b').hasMatch(p)) {
      final rendaUsar = renda > 0 ? renda : 3000.0;
      return '📅 Planejamento mensal — Regra 50-30-20:\n\n'
          '🏠 Necessidades (50%): ${_fmt(rendaUsar * 0.5)}\n'
          '   Aluguel, alimentação, transporte, saúde\n\n'
          '🎮 Desejos (30%): ${_fmt(rendaUsar * 0.3)}\n'
          '   Lazer, roupas, restaurante\n\n'
          '💰 Poupança (20%): ${_fmt(rendaUsar * 0.2)}\n'
          '   Investimentos + reserva de emergência\n\n'
          '💡 Primeiro passo: reserva de emergência de ${_fmt(rendaUsar * 3)} (3 meses)';
    }

    // ── Dívida geral ──
    if (RegExp(r'\b(divida|devo|cartao|credito|emprestimo|parcela|negativado|serasa|spc)\b').hasMatch(p)) {
      return '🎯 Para sair das dívidas — método avalanche:\n\n'
          '1️⃣ Liste todas as dívidas com a taxa de juros\n'
          '2️⃣ Pague o mínimo de todas\n'
          '3️⃣ Todo valor extra vai para a de MAIOR taxa\n'
          '4️⃣ Negocie desconto para pagar à vista\n\n'
          '⚠️ Cartão rotativo: até 240% ao ano! Prioridade máxima.\n'
          '📞 Serasa Limpa Nome: descontos de até 99%\n'
          '🏦 CET/BB: tem linha de crédito com juro menor para quitar cartão\n\n'
          '💬 Me diga quanto deve e quanto paga por mês para calcular!';
    }

    // ── Resposta padrão inteligente ──
    final dadosStr = renda > 0
        ? '\n\n📊 Seus dados: ganhos ${_fmt(renda)} | gastos ${_fmt(gastos)} | saldo ${_fmt(saldo)}'
        : '';
    return '🤔 Não entendi completamente. Tente perguntar assim:\n\n'
        '🚗 "Quero comprar um carro de 50 mil e ganho 3 mil"\n'
        '✈️ "Quanto guardar por mês para 20 mil em 1 ano?"\n'
        '💳 "Tenho dívida de 5 mil, pago 300 por mês"\n'
        '📈 "Onde investir meu dinheiro?"\n'
        '🛡️ "Quanto preciso de reserva de emergência?"\n'
        '💰 "Meu saldo"$dadosStr';
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
