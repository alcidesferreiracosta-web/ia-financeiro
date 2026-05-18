import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'criar_conta_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _loading = false;
  String? _erro;

  Future<void> _loginEmail() async {
    setState(() { _loading = true; _erro = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() { _erro = e.message; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _loginGoogle() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) { setState(() { _loading = false; }); return; }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() { _erro = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.account_balance_wallet, color: Color(0xFF4FC3F7), size: 64),
              const SizedBox(height: 16),
              const Text('IA Financeiro', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Gerencie suas finanças com inteligência', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('E-mail', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Senha', Icons.lock_outline),
                obscureText: true,
              ),
              if (_erro != null) ...[
                const SizedBox(height: 8),
                Text(_erro!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _loginEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loading ? null : _loginGoogle,
                icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                label: const Text('Entrar com Google', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CriarContaPage())),
                child: const Text('Não tem conta? Criar agora',
                    style: TextStyle(color: Color(0xFF4FC3F7))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
