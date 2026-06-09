import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gps_economia_service.dart';

class RankingGpsPage extends StatefulWidget {
  const RankingGpsPage({super.key});

  @override
  State<RankingGpsPage> createState() => _RankingGpsPageState();
}

class _RankingGpsPageState extends State<RankingGpsPage> {
  List<Map<String, dynamic>> _ranking = [];
  Map<String, dynamic>? _meusDados;
  bool _carregando = true;
  final _myUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final results = await Future.wait([
      GpsEconomiaService.instance.getTopRanking(),
      GpsEconomiaService.instance.getMeusDados(),
    ]);
    if (mounted) {
      setState(() {
        _ranking = results[0] as List<Map<String, dynamic>>;
        _meusDados = results[1] as Map<String, dynamic>?;
        _carregando = false;
      });
    }
  }

  String _nivelEmoji(String nivel) {
    switch (nivel) {
      case 'rei':          return '👑';
      case 'lenda':        return '💎';
      case 'mestre':       return '🥇';
      case 'especialista': return '🥈';
      default:             return '🥉'; // cacador
    }
  }

  String _nivelLabel(String nivel) {
    switch (nivel) {
      case 'rei':          return 'Rei da Economia';
      case 'lenda':        return 'Lenda da Economia';
      case 'mestre':       return 'Mestre da Economia';
      case 'especialista': return 'Especialista em Economia';
      default:             return 'Caçador de Ofertas';
    }
  }

  Color _nivelColor(String nivel) {
    switch (nivel) {
      case 'rei':          return const Color(0xFFFFD700);
      case 'lenda':        return const Color(0xFF9C27B0);
      case 'mestre':       return const Color(0xFFFF9800);
      case 'especialista': return const Color(0xFFB0BEC5);
      default:             return const Color(0xFFCD7F32);
    }
  }

  // Aliases usados no restante do widget
  String _rankEmoji(String rank) => _nivelEmoji(rank);
  String _rankLabel(String rank) => _nivelLabel(rank);
  Color _rankColor(String rank) => _nivelColor(rank);

  @override
  Widget build(BuildContext context) {
    final meusPontos = (_meusDados?['pontos'] ?? 0) as int;
    final meuRank = (_meusDados?['rank'] ?? 'iniciante') as String;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        title: const Text('Ranking — GPS de Economia'),
        elevation: 0,
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : Column(children: [
              // Meu card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _rankColor(meuRank).withOpacity(0.25),
                      const Color(0xFF0A1628),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _rankColor(meuRank).withOpacity(0.5)),
                ),
                child: Row(children: [
                  Text(_rankEmoji(meuRank),
                      style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_rankLabel(meuRank),
                              style: TextStyle(
                                  color: _rankColor(meuRank),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const Text('Minha posição',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$meusPontos pts',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    const Text('total',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ]),
                ]),
              ),

              // Como ganhar pontos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Como ganhar pontos',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 8),
                        _PontoRow('+10 pts', 'Publicar uma promoção'),
                        _PontoRow('+20 pts', 'Sua promoção ser confirmada por alguém'),
                        _PontoRow('+5 pts',  'Sua oferta ser salva por alguém'),
                        _PontoRow('+5 pts',  'Sua oferta ser compartilhada'),
                        _PontoRow('+2 pts',  'Sua oferta receber curtida'),
                        _PontoRow('+20 pts', 'Completar missão diária'),
                        _PontoRow('+1 pt',   'Login diário'),
                        const SizedBox(height: 8),
                        const Text('Níveis',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        const SizedBox(height: 6),
                        _NivelRow('🥉', 'Caçador de Ofertas',      '0 pts'),
                        _NivelRow('🥈', 'Especialista em Economia', '500 pts'),
                        _NivelRow('🥇', 'Mestre da Economia',       '2.000 pts'),
                        _NivelRow('💎', 'Lenda da Economia',        '5.000 pts'),
                        _NivelRow('👑', 'Rei da Economia',          '10.000 pts'),
                      ]),
                ),
              ),

              const SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 18),
                  SizedBox(width: 6),
                  Text('Top Caçadores de Promoção',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ]),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: _ranking.isEmpty
                    ? const Center(
                        child: Text('Seja o primeiro!',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _ranking.length,
                        itemBuilder: (_, i) {
                          final item = _ranking[i];
                          final pontos = (item['pontos'] ?? 0) as int;
                          final rank =
                              (item['rank'] ?? 'iniciante') as String;
                          final isMe = item['uid'] == _myUid;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                                  : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isMe
                                      ? const Color(0xFF4CAF50)
                                          .withOpacity(0.4)
                                      : Colors.white12),
                            ),
                            child: Row(children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  i < 3 ? ['🥇', '🥈', '🥉'][i] : '${i + 1}º',
                                  style: TextStyle(
                                      color: i < 3
                                          ? [
                                              const Color(0xFFFFD700),
                                              const Color(0xFFC0C0C0),
                                              const Color(0xFFCD7F32)
                                            ][i]
                                          : Colors.white38,
                                      fontWeight: FontWeight.bold,
                                      fontSize: i < 3 ? 18 : 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isMe
                                            ? 'Você'
                                            : 'Usuário ${i + 1}',
                                        style: TextStyle(
                                            color: isMe
                                                ? const Color(0xFF4CAF50)
                                                : Colors.white,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(_rankLabel(rank),
                                          style: TextStyle(
                                              color: _rankColor(rank),
                                              fontSize: 11)),
                                    ]),
                              ),
                              Text('$pontos pts',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ]),
                          );
                        },
                      ),
              ),
            ]),
    );
  }
}

class _NivelRow extends StatelessWidget {
  final String emoji;
  final String nome;
  final String pts;
  const _NivelRow(this.emoji, this.nome, this.pts);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
            child: Text(nome,
                style: const TextStyle(color: Colors.white70, fontSize: 11))),
        Text(pts,
            style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _PontoRow extends StatelessWidget {
  final String pts;
  final String desc;
  const _PontoRow(this.pts, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8)),
          child: Text(pts,
              style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(desc,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 12))),
      ]),
    );
  }
}
