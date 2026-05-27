import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  static SubscriptionService get instance => _instance;
  SubscriptionService._();

  bool _isPremium = false;
  bool get isSubscribed => kDebugMode || _isPremium;

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
      update['premium_until'] = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 35)),
      );
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
      if (!doc.exists) { _setPremium(false); return; }
      final data = doc.data()!;
      bool active = false;
      if (data['premium'] == true) {
        final until = data['premium_until'];
        active = until == null || (until as Timestamp).toDate().isAfter(DateTime.now());
      }
      _setPremium(active);
    });
  }

  void _setPremium(bool value) {
    _isPremium = value;
    _statusController.add(value);
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
