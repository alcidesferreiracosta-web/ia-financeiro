import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GastosPage extends StatefulWidget {
  const GastosPage({super.key});
  @override
  State<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  String _categoria = 'Alimentação';
  bool _necessario = true;
  bool _loading = false;

  final List<String> _categorias = [
    'Alimentação', 'Transporte', 'Moradia', 'Saúde', 'Educação',
    'Lazer', 'Roupas', 'Tecnologia', 'Outros',
  ];

  Future<void> _salvar() async {
    if (_valorController.text.isEmpty) return;
    setState(() { _loading = true; });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final valor = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0;
      await FirebaseFirestore.instance.collection('gastos').add({
        'userId': uid,
        'valor': valor,
        'categoria': _categoria,
        'descricao': _descricaoController.text.trim(),
        'data': FieldValue.serverTimestamp(),
        'necessario': _necessario,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Adicionar Gasto', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
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
            TextField(
              controller: _descricaoController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Descrição', Icons.description_outlined),
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
            Row(children: [
              const Text('Gasto necessário?', style: TextStyle(color: Colors.white70)),
              const Spacer(),
              Switch(value: _necessario, onChanged: (v) => setState(() { _necessario = v; }),
                  activeColor: Colors.green),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Salvar Gasto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
