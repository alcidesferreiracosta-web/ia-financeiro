import 'dart:async';
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
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _Loading();
          }
          if (!snap.hasData) return const LoginPage();
          return _SubscriptionGate(user: snap.data!);
        },
      ),
    );
  }
}

// Inicia o serviço de assinatura e escuta mudanças em tempo real via Firestore
class _SubscriptionGate extends StatefulWidget {
  final User user;
  const _SubscriptionGate({required this.user});

  @override
  State<_SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<_SubscriptionGate> {
  late bool _isSubscribed;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _isSubscribed = SubscriptionService.instance.isSubscribed;
    SubscriptionService.instance.init();
    _sub = SubscriptionService.instance.statusStream.listen((value) {
      if (mounted) setState(() => _isSubscribed = value);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _isSubscribed ? const MainNav() : const PaywallPage();
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      body: Center(child: CircularProgressIndicator(color: Colors.orange)),
    );
  }
}
