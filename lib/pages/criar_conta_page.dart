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
  bool _loading = false;
  String? _erro;

  Future<void> _criarConta() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': _emailController.text.trim(),
        'nome': _nomeController.text.trim(),
        'rendaMensal': 0.0,
        'saldoAtual': 0.0,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      await cred.user!.updateDisplayName(_nomeController.text.trim());
    } on FirebaseAuthException catch (e) {
      setState(() { _erro = e.message; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Criar Conta', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Nome completo', Icons.person_outline),
              ),
              const SizedBox(height: 16),
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
                onPressed: _loading ? null : _criarConta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Criar Conta', fontWeight: FontWeight.bold, fontSize: 16),
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
