import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/subscription_service.dart';
import 'pages/login_page.dart';
import 'pages/main_nav.dart';
import 'pages/paywall_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = FlutterError.presentError;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SubscriptionService.instance.init();
  runApp(const IAFinanceiroApp());
}

class IAFinanceiroApp extends StatelessWidget {
  const IAFinanceiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IA Financeiro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0D1B2A),
              body: Center(child: CircularProgressIndicator(color: Colors.orange)),
            );
          }
          if (!snapshot.hasData) return const LoginPage();
          // Usuário logado — verifica assinatura
          return SubscriptionService.instance.isSubscribed
              ? const MainNav()
              : const PaywallPage();
        },
      ),
    );
  }
}
