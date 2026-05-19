import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScorePage extends StatelessWidget {
  const ScorePage({super.key});

  static int calcScore(double ganhos, double gastos) {
    if (ganhos == 0) return 50;
    final taxa = (ganhos - gastos) / ganhos;
    if (taxa >= 0.30) return 95;
    if (taxa >= 0.20) return 82;
    if (taxa >= 0.10) return 68;
    if (taxa >= 0.05) return 55;
    if (taxa >= 0.00) return 45;
    if (taxa >= -0.20) return 30;
    return 15;
  }

  static String nivel(int score) {
    if (score >= 80) return 'Mestre Financeiro';
    if (score >= 65) return 'Investidor';
    if (score >= 50) return 'Organizado';
    return 'Iniciante';
  }

  static String emoji(int score) {
    if (score >= 80) return '🥇';
    if (score >= 65) return '🥈';
    if (score >= 50) return '🥉';
    return '🎯';
  }

  static Color corNivel(int score) {
    if (score >= 80) return const Color(0xFFFFD700);
    if (score >= 65) return Colors.greenAccent;
    if (score >= 50) return Colors.blueAccent;
    return Colors.orangeAccent;
  }

  static int proxNivel(int score) {
    if (score >= 80) return 100;
    if (score >= 65) return 80;
    if (score >= 50) return 65;
    return 50;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Score Financeiro', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ganhos')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (ctx, gSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('gastos')
                .where('userId', isEqualTo: uid)
                .snapshots(),
            builder: (ctx, eSnap) {
              double ganhos = 0, gastos = 0;
              int desnecessarios = 0;
              if (gSnap.hasData) {
                ganhos = gSnap.data!.docs.fold(
                    0, (s, d) => s + ((d['valor'] as num?)?.toDouble() ?? 0));
              }
              if (eSnap.hasData) {
                for (final d in eSnap.data!.docs) {
                  gastos += (d['valor'] as num?)?.toDouble() ?? 0;
                  if (d['necessario'] == false) desnecessarios++;
                }
              }

              final score = calcScore(ganhos, gastos);
              final nv = nivel(score);
              final em = emoji(score);
              final cor = corNivel(score);
              final prox = proxNivel(score);
              final taxa = ganhos > 0
                  ? ((ganhos - gastos) / ganhos * 100).clamp(0.0, 100.0)
                  : 0.0;
              final risco = gastos > ganhos
                  ? 'Alto'
                  : gastos > ganhos * 0.8
                      ? 'Médio'
                      : 'Baixo';
              final corRisco = gastos > ganhos
                  ? Colors.redAccent
                  : gastos > ganhos * 0.8
                      ? Colors.orange
                      : Colors.greenAccent;
              final capacidade = taxa >= 20
                  ? 'Alta'
                  : taxa >= 10
                      ? 'Média'
                      : 'Baixa';
              final corCap = taxa >= 20
                  ? Colors.greenAccent
                  : taxa >= 10
                      ? Colors.orange
                      : Colors.redAccent;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gauge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2A3A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cor.withOpacity(0.3)),
                      ),
                      child: Column(children: [
                        Stack(alignment: Alignment.center, children: [
                          SizedBox(
                            width: 130,
                            height: 130,
                            child: CircularProgressIndicator(
                              value: score / 100,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation(cor),
                              strokeWidth: 10,
                            ),
                          ),
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('$score',
                                style: TextStyle(
                                    color: cor,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold)),
                            const Text('/100',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 13)),
                          ]),
                        ]),
                        const SizedBox(height: 16),
                        Text('$em $nv',
                            style: TextStyle(
                                color: cor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        if (score < 100)
                          Text(
                              'Faltam ${prox - score} pontos para ${nivel(prox)}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    _MetricCard(
                      titulo: 'Organização Financeira',
                      valor: '${taxa.toStringAsFixed(0)}%',
                      descricao: 'Taxa de economia mensal',
                      progress: taxa / 100,
                      cor: taxa >= 20
                          ? Colors.greenAccent
                          : taxa >= 10
                              ? Colors.orange
                              : Colors.redAccent,
                    ),

                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(
                          child: _InfoCard(
                              titulo: 'Risco de Endividamento',
                              valor: risco,
                              cor: corRisco)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _InfoCard(
                              titulo: 'Capacidade de Investir',
                              valor: capacidade,
                              cor: corCap)),
                    ]),

                    const SizedBox(height: 20),

                    const Text('Conquistas',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    Wrap(spacing: 10, runSpacing: 10, children: [
                      _Badge(
                          icon: Icons.attach_money,
                          label: 'Primeiro Ganho',
                          desbloqueado: ganhos > 0),
                      _Badge(
                          icon: Icons.money_off,
                          label: 'Primeiro Gasto',
                          desbloqueado: gastos > 0),
                      _Badge(
                          icon: Icons.savings,
                          label: 'Economizando',
                          desbloqueado: ganhos > gastos && ganhos > 0),
                      _Badge(
                          icon: Icons.star,
                          label: 'Score 50+',
                          desbloqueado: score >= 50),
                      _Badge(
                          icon: Icons.emoji_events,
                          label: 'Investidor',
                          desbloqueado: score >= 65),
                      _Badge(
                          icon: Icons.workspace_premium,
                          label: 'Mestre',
                          desbloqueado: score >= 80),
                      _Badge(
                          icon: Icons.thumb_up,
                          label: 'Consciente',
                          desbloqueado: desnecessarios == 0 && gastos > 0),
                    ]),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Como melhorar seu score',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 10),
                            if (taxa < 20)
                              _Dica(
                                  'Economize ao menos 20% da renda — meta ideal'),
                            if (gastos > ganhos)
                              _Dica(
                                  'Reduza gastos para não ultrapassar a renda'),
                            if (desnecessarios > 2)
                              _Dica(
                                  'Você tem $desnecessarios gastos desnecessários registrados'),
                            if (score >= 50 && taxa >= 20)
                              _Dica(
                                  'Invista o excedente para acelerar seu crescimento'),
                            if (ganhos == 0)
                              _Dica('Registre seus ganhos para calcular o score'),
                          ]),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String titulo, valor, descricao;
  final double progress;
  final Color cor;
  const _MetricCard(
      {required this.titulo,
      required this.valor,
      required this.descricao,
      required this.progress,
      required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(titulo,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(valor,
              style: TextStyle(
                  color: cor, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(cor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text(descricao,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String titulo, valor;
  final Color cor;
  const _InfoCard(
      {required this.titulo, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 6),
        Text(valor,
            style: TextStyle(
                color: cor, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool desbloqueado;
  const _Badge(
      {required this.icon,
      required this.label,
      required this.desbloqueado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: desbloqueado
            ? Colors.orange.withOpacity(0.15)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: desbloqueado ? Colors.orange.withOpacity(0.5) : Colors.white12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            color: desbloqueado ? Colors.orange : Colors.white24, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: desbloqueado ? Colors.orange : Colors.white24,
                fontSize: 11,
                fontWeight:
                    desbloqueado ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }
}

class _Dica extends StatelessWidget {
  final String texto;
  const _Dica(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 14),
        const SizedBox(width: 6),
        Expanded(
            child: Text(texto,
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
      ]),
    );
  }
}
