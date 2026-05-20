import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  static const String productId = 'ia_financeiro_mensal';

  static final SubscriptionService _instance = SubscriptionService._();
  static SubscriptionService get instance => _instance;
  SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _isSubscribed = false;
  bool _isLoading = true;
  String? _error;

  bool get isSubscribed => kDebugMode || _isSubscribed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  Future<void> init() async {
    if (kDebugMode) {
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
