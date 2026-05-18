import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CriarContaPage extends StatefulWidget {
  const CriarContaPage({super.key});
  @override
  State<CriarContaPage> createState() => _CriarContaPageState();
}

class _CriarContaPageState extends State<CriarContaPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _loading = false;
  bool _senhaVisivel = false;
  String? _erro;

  String _traduzirErro(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Este e-mail já está cadastrado. Faça login.';
      case 'invalid-email': return 'E-mail inválido. Verifique e tente novamente.';
      case 'weak-password': return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'operation-not-allowed': return 'Cadastro com e-mail desativado. Contate o suporte.';
      case 'network-request-failed': return 'Sem conexão com a internet. Verifique o Wi-Fi.';
      case 'too-many-requests': return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      default: return 'Erro ao criar conta. Tente novamente.';
    }
  }

  Future<void> _criarConta() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmar = _confirmarSenhaController.text;

    if (nome.isEmpty) { setState(() => _erro = 'Informe seu nome completo.'); return; }
    if (email.isEmpty) { setState(() => _erro = 'Informe seu e-mail.'); return; }
    if (senha.length < 6) { setState(() => _erro = 'A senha deve ter pelo menos 6 caracteres.'); return; }
    if (senha != confirmar) { setState(() => _erro = 'As senhas não coincidem.'); return; }

    setState(() { _loading = true; _erro = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      await cred.user!.updateDisplayName(nome);
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'nome': nome,
        'rendaMensal': 0.0,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      // Limpa toda a pilha de navegação — StreamBuilder detecta o login e abre o HomePage
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _traduzirErro(e.code));
    } catch (e) {
      setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Criar Conta', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add_outlined, color: Color(0xFF4FC3F7), size: 56),
              const SizedBox(height: 8),
              const Text('Crie sua conta gratuita', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 28),

              TextField(
                controller: _nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Nome completo', Icons.person_outline),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('E-mail', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _senhaController,
                style: const TextStyle(color: Colors.white),
                obscureText: !_senhaVisivel,
                decoration: _inputDecoration('Senha (mín. 6 caracteres)', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_senhaVisivel ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54),
                    onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmarSenhaController,
                style: const TextStyle(color: Colors.white),
                obscureText: !_senhaVisivel,
                decoration: _inputDecoration('Confirmar senha', Icons.lock_outline),
                onSubmitted: (_) => _criarConta(),
              ),

              if (_erro != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_erro!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _criarConta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Criar Conta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Já tem conta?', style: TextStyle(color: Colors.white54)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entrar', style: TextStyle(
                      color: Color(0xFF4FC3F7), fontWeight: FontWeight.bold)),
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
