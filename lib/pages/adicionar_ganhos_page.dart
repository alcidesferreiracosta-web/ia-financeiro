import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdicionarGanhosPage extends StatefulWidget {
  const AdicionarGanhosPage({super.key});
  @override
  State<AdicionarGanhosPage> createState() => _AdicionarGanhosPageState();
}

class _AdicionarGanhosPageState extends State<AdicionarGanhosPage> {
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  String _categoria = 'Salário';
  bool _loading = false;

  final List<String> _categorias = [
    'Salário', 'Freelance', 'Venda', 'Investimento', 'Aluguel', 'Presente', 'Outros',
  ];

  Future<void> _salvar() async {
    if (_valorController.text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { _loading = true; });
    try {
      final valor = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0;
      if (valor <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digite um valor válido.'), backgroundColor: Colors.orange),
        );
        setState(() { _loading = false; });
        return;
      }
      await FirebaseFirestore.instance.collection('ganhos').add({
        'userId': user.uid,
        'valor': valor,
        'categoria': _categoria,
        'descricao': _descricaoController.text.trim(),
        'data': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ganho salvo com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      String msg = 'Erro ao salvar.';
      if (e.code == 'permission-denied') {
        msg = 'Sem permissão. Verifique as regras do Firestore no Firebase Console.';
      } else if (e.code == 'unavailable') {
        msg = 'Sem conexão com a internet.';
      } else {
        msg = 'Erro Firebase: ${e.code}';
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Adicionar Ganho', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _valorController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Valor (R\$)', Icons.attach_money),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoria,
              dropdownColor: const Color(0xFF1A2A3A),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Categoria', Icons.category_outlined),
              items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() { _categoria = v!; }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Descrição (opcional)', Icons.description_outlined),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Salvar Ganho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
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
