import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  static SubscriptionService get instance => _instance;
  SubscriptionService._();

  // Testadores do Play Console — bypassam o paywall
  static const _testerEmails = {
    'alcidesferreira.costa21@gmail.com',
    'alcidesferreira.costa@hotmail.com',
    'betaniaba.96@gmail.com',
    'edmilson777queiroz@gmail.com',
    'estevisdany@gmail.com',
    'felipe17412@gmail.com',
    'ivancouto555@gmail.com',
    'pedro.couto.ferreiraa@gmail.com',
    'rosangelaestevescouto@gmail.com',
    'sheyla.sophia.pedro@gmail.com',
    'soepestore@gmail.com',
    'eliaslyon30@gmail.com',
    'almerita.silva.maria@gmail.com',
  };

  bool _isPremium = false;
  bool _isTrial = false;
  bool _isFree = false;
  DateTime? _premiumUntil;

  bool get isSubscribed => kDebugMode || _isPremium || _isTester;
  bool get isFree => _isFree && !_isPremium && !_isTester && !kDebugMode;
  bool get canAccessApp => isSubscribed || _isFree;
  bool get isTrial => _isTrial && !_isTester && !kDebugMode;
  int get trialDaysLeft {
    if (_premiumUntil == null) return 0;
    final diff = _premiumUntil!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get _isTester {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase().trim();
    return email != null && _testerEmails.contains(email);
  }

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  StreamSubscription? _firestoreSub;

  Future<void> init() async {
    if (kDebugMode) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _checkPendingActivation(user);
    _listenToFirestore(user.uid);
  }

  // Usuário pagou no Hotmart antes de criar conta — ativa automaticamente no 1º login
  Future<void> _checkPendingActivation(User user) async {
    final email = user.email?.toLowerCase().trim();
    if (email == null) return;

    final db = FirebaseFirestore.instance;
    final pending = await db.collection('pending_activations').doc(email).get();
    if (!pending.exists) return;

    final data = pending.data()!;
    final isPremium = data['premium'] == true;
    final update = <String, dynamic>{
      'premium': isPremium,
      'hotmart_email': email,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (isPremium) {
      // Preserva premium_until do pending_activations (ex: vitalício = 2098)
      // Se não tiver, padrão de 35 dias (assinatura mensal com margem)
      final pendingUntil = data['premium_until'];
      update['premium_until'] = pendingUntil ??
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 35)));
      if (data['trial'] == true) update['trial'] = true;
    }

    await db.collection('usuarios').doc(user.uid).set(update, SetOptions(merge: true));
    await pending.reference.delete();
  }

  void _listenToFirestore(String uid) {
    _firestoreSub?.cancel();
    _firestoreSub = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) { _setPremium(false, false, true, null); return; }
      final data = doc.data()!;
      bool active = false;
      bool trial = false;
      bool free = false;
      DateTime? until;
      if (data['premium'] == true) {
        final rawUntil = data['premium_until'];
        until = rawUntil != null ? (rawUntil as Timestamp).toDate() : null;
        active = until == null || until.isAfter(DateTime.now());
        trial = active && data['trial'] == true;
      } else {
        free = true;
      }
      _setPremium(active, trial, free, until);
    });
  }

  void _setPremium(bool value, bool trial, bool free, DateTime? until) {
    _isPremium = value;
    _isTrial = trial;
    _isFree = free;
    _premiumUntil = until;
    _statusController.add(value || free);
  }

  void reset() {
    _firestoreSub?.cancel();
    _isPremium = false;
  }

  void dispose() {
    _firestoreSub?.cancel();
    _statusController.close();
  }
}
