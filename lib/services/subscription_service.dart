import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  static const String productId = 'ia_financeiro_mensal';

  static final SubscriptionService _instance = SubscriptionService._();
  static SubscriptionService get instance => _instance;
  SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _isSubscribed = false;
  bool _isPremiumFirestore = false;
  bool _isLoading = true;
  String? _error;

  // Acesso liberado se: debug, Firestore premium, ou Google Play ativo
  bool get isSubscribed => kDebugMode || _isPremiumFirestore || _isSubscribed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  Future<void> init() async {
    if (kDebugMode) {
      _isLoading = false;
      return;
    }

    // Verifica campo premium no Firestore (admin bypass + combo Hotmart)
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          final premiumUntil = data['premium_until'];
          if (data['premium'] == true) {
            _isPremiumFirestore = true;
          } else if (premiumUntil != null) {
            final until = (premiumUntil as Timestamp).toDate();
            _isPremiumFirestore = until.isAfter(DateTime.now());
          }
        }
      }
    } catch (_) {}

    if (_isPremiumFirestore) {
      _isLoading = false;
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      _isLoading = false;
      _error = 'Google Play indisponível';
      return;
    }

    _sub = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (_) {
      _isLoading = false;
    });

    await _iap.restorePurchases();

    // Aguarda resposta do restore (máx 5s)
    await Future.delayed(const Duration(seconds: 5));
    _isLoading = false;
    _statusController.add(_isSubscribed);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.productID != productId) continue;

      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        _isSubscribed = true;
      } else if (p.status == PurchaseStatus.error) {
        _error = p.error?.message;
      }

      if (p.pendingCompletePurchase) {
        _iap.completePurchase(p);
      }
    }
    _isLoading = false;
    _statusController.add(_isSubscribed);
  }

  Future<String?> subscribe() async {
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        return 'Produto não encontrado no Google Play';
      }
      final param = PurchaseParam(productDetails: response.productDetails.first);
      await _iap.buyNonConsumable(purchaseParam: param);
      return null;
    } catch (e) {
      return 'Erro ao iniciar assinatura: $e';
    }
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _sub?.cancel();
    _statusController.close();
  }
}
