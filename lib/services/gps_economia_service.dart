import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../models/promocao_model.dart';

class GpsEconomiaService {
  static final GpsEconomiaService instance = GpsEconomiaService._();
  GpsEconomiaService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  // ── Localização ──────────────────────────────────────────

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
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
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

  // ── Promoções ────────────────────────────────────────────

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

  // ── Cadastro ─────────────────────────────────────────────

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
    if (foto != null) {
      final ref = _storage.ref('promocoes/${user.uid}/${docRef.id}.jpg');
      await ref.putFile(foto);
      fotoUrl = await ref.getDownloadURL();
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
    return docRef.id;
  }

  // ── Interações ───────────────────────────────────────────

  Future<void> confirmarPromocao(String promoId, String criadoPorUid) async {
    await _db.collection('promocoes').doc(promoId).update({
      'confirmacoes': FieldValue.increment(1),
    });
    if (criadoPorUid != _auth.currentUser?.uid) {
      await _addPontos(criadoPorUid, 5);
    }
  }

  Future<void> curtirPromocao(String promoId) async {
    await _db.collection('promocoes').doc(promoId).update({
      'curtidas': FieldValue.increment(1),
    });
  }

  Future<void> reportarPromocao(String promoId) async {
    final ref = _db.collection('promocoes').doc(promoId);
    await ref.update({'reportes': FieldValue.increment(1)});
    final doc = await ref.get();
    if ((doc.data()?['reportes'] ?? 0) >= 5) {
      await ref.update({'ativa': false});
    }
  }

  Future<void> registrarAcesso(String promoId, String criadoPorUid) async {
    final ref = _db.collection('promocoes').doc(promoId);
    await ref.update({'acessos': FieldValue.increment(1)});
    final doc = await ref.get();
    final acessos = (doc.data()?['acessos'] ?? 0) as int;
    if (acessos == 50 || acessos == 100 || acessos == 500) {
      await _addPontos(criadoPorUid, 20);
    }
  }

  // ── Economia gerada ──────────────────────────────────────

  Future<void> registrarEconomia(double valor, String categoria) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('usuarios').doc(uid).set({
      'economia_total': {categoria: FieldValue.increment(valor)},
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getEconomiaTotal() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};
    final doc = await _db.collection('usuarios').doc(uid).get();
    final data = doc.data();
    if (data == null) return {};
    return (data['economia_total'] as Map<String, dynamic>?) ?? {};
  }

  // ── Ranking ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> getMeusDados() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('usuarios').doc(uid).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getTopRanking() async {
    final snap = await _db
        .collection('usuarios')
        .orderBy('pontos', descending: true)
        .limit(20)
        .get();
    return snap.docs
        .map((d) => <String, dynamic>{...d.data(), 'uid': d.id})
        .toList();
  }

  // ── Pontos internos ──────────────────────────────────────

  Future<void> _addPontos(String uid, int pts) async {
    final ref = _db.collection('usuarios').doc(uid);
    await ref.set({'pontos': FieldValue.increment(pts)}, SetOptions(merge: true));
    final doc = await ref.get();
    final total = (doc.data()?['pontos'] ?? 0) as int;
    final rank = total >= 500
        ? 'ouro'
        : total >= 200
            ? 'prata'
            : total >= 50
                ? 'bronze'
                : 'iniciante';
    await ref.set({'rank': rank}, SetOptions(merge: true));
  }
}
