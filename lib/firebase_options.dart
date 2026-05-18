import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCoCKKJWK3hNY0b0ugR9vKVkl-xNTn_FhI',
    appId: '1:645717748742:android:2b7af889a236bfb53e2787',
    messagingSenderId: '645717748742',
    projectId: 'i-a-financeiro-hq2c4c',
    storageBucket: 'i-a-financeiro-hq2c4c.firebasestorage.app',
  );
}
