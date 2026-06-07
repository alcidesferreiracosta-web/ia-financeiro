import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'criar_conta_page.dart';
import 'social_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _loading = false;
  bool _senhaVisivel = false;
  String? _erro;

  Future<void> _loginEmail() async {
    if (_emailController.text.isEmpty || _senhaController.text.isEmpty) {
      setState(() => _erro = 'Preencha e-mail e senha.');
      return;
    }
    setState(() { _loading = true; _erro = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Erro ao entrar.';
      if (e.code == 'user-not-found') msg = 'E-mail não cadastrado.';
      if (e.code == 'wrong-password') msg = 'Senha incorreta.';
      if (e.code == 'invalid-email') msg = 'E-mail inválido.';
      setState(() => _erro = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _esqueceuSenha() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A3A),
        title: const Text('Redefinir senha', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Informe seu e-mail para receber o link de redefinição.',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-mail',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link enviado para $email. Verifique sua caixa de entrada.'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              } on FirebaseAuthException {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('E-mail não encontrado. Verifique e tente novamente.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginGoogle() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final result = await SocialAuth.loginGoogle();
      if (result == null && mounted) setState(() => _loading = false);
    } catch (e) {
      setState(() => _erro = 'Erro ao entrar com Google.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: Color(0xFF4FC3F7), size: 64),
              ),
              const SizedBox(height: 20),
              const Text('IA Financeiro', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Gerencie suas finanças com inteligência',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 40),

              // E-mail
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('E-mail', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Senha
              TextField(
                controller: _senhaController,
                style: const TextStyle(color: Colors.white),
                obscureText: !_senhaVisivel,
                decoration: _inputDecoration('Senha', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_senhaVisivel ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54),
                    onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                  ),
                ),
                onSubmitted: (_) => _loginEmail(),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _esqueceuSenha,
                  child: const Text('Esqueci minha senha',
                      style: TextStyle(color: Color(0xFF4FC3F7), fontSize: 13)),
                ),
              ),

              if (_erro != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(_erro!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 20),

              // Botão entrar
              ElevatedButton(
                onPressed: _loading ? null : _loginEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 12),

              // Divisor
              Row(children: [
                const Expanded(child: Divider(color: Colors.white24)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou', style: TextStyle(color: Colors.white38)),
                ),
                const Expanded(child: Divider(color: Colors.white24)),
              ]),
              const SizedBox(height: 12),

              // Botão Google
              OutlinedButton(
                onPressed: _loading ? null : _loginGoogle,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                    child: const Center(
                      child: Text('G', style: TextStyle(
                          color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Continuar com Google',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ]),
              ),
              const SizedBox(height: 24),

              // Criar conta
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Não tem conta?', style: TextStyle(color: Colors.white54)),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CriarContaPage())),
                  child: const Text('Criar agora',
                      style: TextStyle(color: Color(0xFF4FC3F7), fontWeight: FontWeight.bold)),
                ),
              ]),
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
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4FC3F7))),
    );
  }
}
