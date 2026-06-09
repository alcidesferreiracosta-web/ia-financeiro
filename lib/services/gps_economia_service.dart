import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../models/promocao_model.dart';

// ── Níveis de usuário ────────────────────────────────────────────────────────
class NivelUsuario {
  static const List<_Nivel> _niveis = [
    _Nivel('cacador',      'Caçador de Ofertas',      '🥉', 0),
    _Nivel('especialista', 'Especialista em Economia', '🥈', 500),
    _Nivel('mestre',       'Mestre da Economia',       '🥇', 2000),
    _Nivel('lenda',        'Lenda da Economia',        '💎', 5000),
    _Nivel('rei',          'Rei da Economia',          '👑', 10000),
  ];

  static _Nivel dePoints(int pts) {
    _Nivel result = _niveis.first;
    for (final n in _niveis) {
      if (pts >= n.minPts) result = n;
    }
    return result;
  }

  static _Nivel deId(String? id) =>
      _niveis.firstWhere((n) => n.id == id, orElse: () => _niveis.first);
}

class _Nivel {
  final String id;
  final String nome;
  final String emoji;
  final int minPts;
  const _Nivel(this.id, this.nome, this.emoji, this.minPts);
}

// ── Service principal ────────────────────────────────────────────────────────
class GpsEconomiaService {
  static final GpsEconomiaService instance = GpsEconomiaService._();
  GpsEconomiaService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  // ── Localização ─────────────────────────────────────────────────────────────

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return null;
    }
    if (perm == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Stream<Position> positionStream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

  double distanciaKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;

  // ── Promoções ────────────────────────────────────────────────────────────────

  Stream<List<PromoModel>> promocoesProximas({
    required double lat,
    required double lng,
    required double raioKm,
    String? categoria,
  }) {
    final delta = raioKm / 111.0;
    final deltaLng = raioKm / (111.0 * cos(lat * pi / 180));

    return _db
        .collection('promocoes')
        .where('lat', isGreaterThanOrEqualTo: lat - delta)
        .where('lat', isLessThanOrEqualTo: lat + delta)
        .limit(300)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map((d) => PromoModel.fromDoc(d))
          .where((p) {
            if (!p.ativa) return false;
            if (p.expiracao.isBefore(now)) return false;
            if ((p.lng - lng).abs() > deltaLng) return false;
            final dist = distanciaKm(lat, lng, p.lat, p.lng);
            if (dist > raioKm) return false;
            if (categoria != null && p.categoria != categoria) return false;
            p.distanciaKm = dist;
            return true;
          })
          .toList()
        ..sort((a, b) => (a.distanciaKm ?? 0).compareTo(b.distanciaKm ?? 0));
    });
  }

  // ── Cadastro ─────────────────────────────────────────────────────────────────

  /// Retorna o docId criado. Se o upload da foto falhar, salva sem foto e
  /// retorna o docId normalmente — o chamador pode exibir aviso se precisar.
  Future<String> criarPromocao({
    required String nomeEstabelecimento,
    required String categoria,
    required String produto,
    required double valorPromo,
    double? valorOriginal,
    required double lat,
    required double lng,
    required String endereco,
    required int duracaoHoras,
    File? foto,
  }) async {
    final user = _auth.currentUser!;
    final inicio = DateTime.now();
    final expiracao = inicio.add(Duration(hours: duracaoHoras));
    final docRef = _db.collection('promocoes').doc();

    String? fotoUrl;
    bool fotoFalhou = false;
    if (foto != null) {
      try {
        final ref = _storage.ref('promocoes/${user.uid}/${docRef.id}.jpg');
        await ref.putFile(foto);
        fotoUrl = await ref.getDownloadURL();
      } catch (_) {
        // Upload falhou — continua sem foto para não bloquear a publicação
        fotoFalhou = true;
      }
    }

    final promo = PromoModel(
      id: docRef.id,
      nomeEstabelecimento: nomeEstabelecimento,
      categoria: categoria,
      produto: produto,
      valorPromo: valorPromo,
      valorOriginal: valorOriginal,
      fotoUrl: fotoUrl,
      lat: lat,
      lng: lng,
      endereco: endereco,
      criadoPorUid: user.uid,
      criadoPorNome: user.displayName ?? 'Usuário',
      duracaoHoras: duracaoHoras,
      inicio: inicio,
      expiracao: expiracao,
      ativa: true,
      confirmacoes: 0,
      curtidas: 0,
      reportes: 0,
      acessos: 0,
    );

    await docRef.set(promo.toMap());
    await _addPontos(user.uid, 10);

    // Marca missão "publicar oferta"
    await _progredirMissao(user.uid, 'publicar_oferta');

    if (fotoFalhou) {
      throw FotoUploadException('Promoção publicada, mas a foto não foi enviada (verifique sua conexão).');
    }

    return docRef.id;
  }

  // ── Interações ───────────────────────────────────────────────────────────────

  Future<void> confirmarPromocao(String promoId, String criadoPorUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final promoRef = _db.collection('promocoes').doc(promoId);
    await promoRef.update({'confirmacoes': FieldValue.increment(1)});

    // Criador ganha +20 pts por confirmação
    if (criadoPorUid != uid) {
      await _addPontos(criadoPorUid, 20);
    }

    // Verifica se atingiu 3 confirmações (oferta verificada)
    final doc = await promoRef.get();
    final confirmacoes = (doc.data()?['confirmacoes'] ?? 0) as int;
    if (confirmacoes >= 3) {
      await promoRef.update({'status_verificacao': 'verificada'});
    }

    // Confirmar conta para missão do confirmador
    await _progredirMissao(uid, 'confirmar_oferta');
  }

  Future<void> curtirPromocao(String promoId, String criadoPorUid) async {
    final uid = _auth.currentUser?.uid;
    await _db.collection('promocoes').doc(promoId).update({
      'curtidas': FieldValue.increment(1),
    });
    // Criador ganha +2 pts por curtida
    if (uid != null && criadoPorUid != uid) {
      await _addPontos(criadoPorUid, 2);
    }
  }

  Future<void> compartilharOferta(String promoId, String criadoPorUid) async {
    final uid = _auth.currentUser?.uid;
    await _db.collection('promocoes').doc(promoId).update({
      'compartilhamentos': FieldValue.increment(1),
    });
    // Criador ganha +5 pts por compartilhamento
    if (uid != null && criadoPorUid != uid) {
      await _addPontos(criadoPorUid, 5);
    }
    // Quem compartilha progride na missão
    if (uid != null) await _progredirMissao(uid, 'compartilhar_oferta');
  }

  Future<void> salvarOferta(String promoId, String criadoPorUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('usuarios').doc(uid).set({
      'ofertas_salvas': FieldValue.arrayUnion([promoId]),
    }, SetOptions(merge: true));
    // Criador ganha +5 pts por oferta salva
    if (criadoPorUid != uid) await _addPontos(criadoPorUid, 5);
  }

  Future<void> reportarPromocao(String promoId) async {
    final ref = _db.collection('promocoes').doc(promoId);
    await ref.update({'reportes': FieldValue.increment(1)});
    final doc = await ref.get();
    final reportes = (doc.data()?['reportes'] ?? 0) as int;
    if (reportes >= 5) {
      await ref.update({'ativa': false, 'status_verificacao': 'reprovada'});
    }
  }

  Future<void> registrarAcesso(String promoId, String criadoPorUid) async {
    final uid = _auth.currentUser?.uid;
    final ref = _db.collection('promocoes').doc(promoId);
    await ref.update({'acessos': FieldValue.increment(1)});
    final doc = await ref.get();
    final acessos = (doc.data()?['acessos'] ?? 0) as int;
    if (acessos == 50 || acessos == 100 || acessos == 500) {
      await _addPontos(criadoPorUid, 20);
    }
    // Progride missão "visitar promoções"
    if (uid != null) await _progredirMissao(uid, 'visitar_promo');
  }

  // ── Login diário ─────────────────────────────────────────────────────────────

  Future<bool> loginDiario() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final hoje = _dataHoje();
    final ref = _db.collection('usuarios').doc(uid);
    final doc = await ref.get();
    final ultimoLogin = doc.data()?['ultimo_login_diario'] as String?;

    if (ultimoLogin == hoje) return false; // já ganhou hoje

    await ref.set({
      'ultimo_login_diario': hoje,
    }, SetOptions(merge: true));
    await _addPontos(uid, 1);
    return true;
  }

  // ── Missões diárias ──────────────────────────────────────────────────────────

  static const _missoesDef = [
    {'id': 'publicar_oferta',   'label': 'Publicar 1 oferta',       'meta': 1,  'icone': '📢'},
    {'id': 'confirmar_oferta',  'label': 'Confirmar 3 ofertas',      'meta': 3,  'icone': '✅'},
    {'id': 'visitar_promo',     'label': 'Visitar 5 promoções',      'meta': 5,  'icone': '👀'},
    {'id': 'compartilhar_oferta','label': 'Compartilhar 1 oferta',   'meta': 1,  'icone': '📤'},
  ];

  Future<List<Map<String, dynamic>>> getMissoesDiarias() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final hoje = _dataHoje();
    final doc = await _db.collection('usuarios').doc(uid).get();
    final progresso = (doc.data()?['missoes']?[hoje] as Map?)?.cast<String, dynamic>() ?? {};

    return _missoesDef.map((m) {
      final id = m['id'] as String;
      final meta = m['meta'] as int;
      final atual = (progresso[id] as num?)?.toInt() ?? 0;
      return {
        ...m,
        'atual': atual,
        'concluida': atual >= meta,
        'recompensa': 20,
      };
    }).toList();
  }

  Future<void> _progredirMissao(String uid, String missaoId) async {
    final hoje = _dataHoje();
    final missao = _missoesDef.firstWhere(
      (m) => m['id'] == missaoId,
      orElse: () => {},
    );
    if (missao.isEmpty) return;

    final meta = missao['meta'] as int;
    final ref = _db.collection('usuarios').doc(uid);
    final doc = await ref.get();
    final progresso = (doc.data()?['missoes']?[hoje] as Map?)?.cast<String, dynamic>() ?? {};
    final atual = (progresso[missaoId] as num?)?.toInt() ?? 0;

    if (atual >= meta) return; // já concluída

    final novoValor = atual + 1;
    await ref.set({
      'missoes': {hoje: {missaoId: novoValor}},
    }, SetOptions(merge: true));

    // Concluiu — dá +20 pts
    if (novoValor >= meta) {
      await _addPontos(uid, 20);
    }
  }

  String _dataHoje() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ── Economia gerada ──────────────────────────────────────────────────────────

  Future<void> registrarEconomia(double valor, String categoria) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final mes = _meAtual();
    final ano = DateTime.now().year.toString();
    await _db.collection('usuarios').doc(uid).set({
      'economia': {
        'total': {categoria: FieldValue.increment(valor)},
        'meses': {mes: FieldValue.increment(valor)},
        'anos': {ano: FieldValue.increment(valor)},
      },
    }, SetOptions(merge: true));
  }

  /// Retorna mapa plano {categoria: valorTotal} para exibição por categoria.
  Future<Map<String, dynamic>> getEconomiaTotal() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};
    final doc = await _db.collection('usuarios').doc(uid).get();
    final data = doc.data();
    if (data == null) return {};
    // Nova estrutura: economia.total.{categoria: valor}
    final novaEstrutura = data['economia'] as Map?;
    if (novaEstrutura != null) {
      final totalMap = novaEstrutura['total'] as Map?;
      if (totalMap != null) return Map<String, dynamic>.from(totalMap);
      return {};
    }
    // Compatibilidade com estrutura antiga
    return (data['economia_total'] as Map<String, dynamic>?) ?? {};
  }

  Future<EconomiaMetrics> getEconomiaMetrics() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const EconomiaMetrics(0, 0, 0);
    final doc = await _db.collection('usuarios').doc(uid).get();
    final data = doc.data();
    if (data == null) return const EconomiaMetrics(0, 0, 0);

    final economia = data['economia'] as Map? ?? {};
    final mes = _meAtual();
    final ano = DateTime.now().year.toString();

    double totalGeral = 0;
    final totalMap = (economia['total'] as Map?)?.values ?? [];
    for (final v in totalMap) { totalGeral += (v as num?)?.toDouble() ?? 0; }

    final economiaMes = (economia['meses']?[mes] as num?)?.toDouble() ?? 0;
    final economiaAno = (economia['anos']?[ano] as num?)?.toDouble() ?? 0;

    return EconomiaMetrics(economiaMes, economiaAno, totalGeral);
  }

  String _meAtual() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ── Ranking ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getMeusDados() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('usuarios').doc(uid).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getTopRanking({int limit = 100}) async {
    final snap = await _db
        .collection('usuarios')
        .orderBy('pontos', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => <String, dynamic>{...d.data(), 'uid': d.id})
        .toList();
  }

  // ── Pontos internos ──────────────────────────────────────────────────────────

  Future<void> _addPontos(String uid, int pts) async {
    final ref = _db.collection('usuarios').doc(uid);
    await ref.set({'pontos': FieldValue.increment(pts)}, SetOptions(merge: true));
    final doc = await ref.get();
    final total = (doc.data()?['pontos'] ?? 0) as int;
    final nivel = NivelUsuario.dePoints(total);
    await ref.set({'rank': nivel.id}, SetOptions(merge: true));
  }
}

// ── Métricas de economia ─────────────────────────────────────────────────────
class _EconomiaMetrics {
  final double mes;
  final double ano;
  final double total;
  const _EconomiaMetrics(this.mes, this.ano, this.total);
}

// Exportado para uso na UI
class EconomiaMetrics {
  final double mes;
  final double ano;
  final double total;
  const EconomiaMetrics(this.mes, this.ano, this.total);
}

// ── Exceção especial de foto ─────────────────────────────────────────────────
class FotoUploadException implements Exception {
  final String message;
  const FotoUploadException(this.message);
  @override
  String toString() => message;
}
