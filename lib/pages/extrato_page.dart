import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExtratoPage extends StatefulWidget {
  const ExtratoPage({super.key});
  @override
  State<ExtratoPage> createState() => _ExtratoPageState();
}

class _ExtratoPageState extends State<ExtratoPage> {
  List<Map<String, dynamic>> _items = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('ganhos').where('userId', isEqualTo: uid).orderBy('data', descending: true).get(),
        FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: uid).orderBy('data', descending: true).get(),
      ]);

      final ganhos = results[0].docs.map((d) => {...d.data() as Map<String, dynamic>, '_tipo': 'ganho', '_id': d.id}).toList();
      final gastos = results[1].docs.map((d) => {...d.data() as Map<String, dynamic>, '_tipo': 'gasto', '_id': d.id}).toList();

      final todos = [...ganhos, ...gastos];
      todos.sort((a, b) {
        final ta = (a['data'] as Timestamp?)?.toDate() ?? DateTime(0);
        final tb = (b['data'] as Timestamp?)?.toDate() ?? DateTime(0);
        return tb.compareTo(ta);
      });

      setState(() { _items = todos; _carregando = false; });
    } catch (e) {
      setState(() { _erro = 'Erro ao carregar extrato. Verifique sua conexão.'; _carregando = false; });
    }
  }

  Future<void> _apagar(Map<String, dynamic> item, int index) async {
    final tipo = item['_tipo'] as String;
    final id = item['_id'] as String;
    setState(() => _items.removeAt(index));

    try {
      await FirebaseFirestore.instance.collection(tipo == 'ganho' ? 'ganhos' : 'gastos').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tipo == 'ganho' ? 'Ganho' : 'Gasto'} apagado com sucesso.'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Restaura o item se falhar
      setState(() => _items.insert(index, item));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao apagar. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmarApagar(Map<String, dynamic> item, int index) {
    final isGanho = item['_tipo'] == 'ganho';
    final valor = (item['valor'] as num).toDouble();
    final descricao = item['descricao'] ?? item['categoria'] ?? (isGanho ? 'Ganho' : 'Gasto');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A3A),
        title: const Text('Apagar registro', style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja apagar "$descricao" (R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')})?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { Navigator.pop(ctx); _apagar(item, index); },
            child: const Text('Apagar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Extrato', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            tooltip: 'Atualizar',
            onPressed: _carregar,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7)))
          : _erro != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
                    const SizedBox(height: 12),
                    Text(_erro!, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                  ]),
                ))
              : _items.isEmpty
                  ? const Center(child: Text('Nenhuma transação registrada.',
                      style: TextStyle(color: Colors.white54)))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(children: [
                            const Icon(Icons.swipe_left, color: Colors.white38, size: 16),
                            const SizedBox(width: 6),
                            const Text('Deslize para a esquerda para apagar',
                                style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ]),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _items.length,
                            itemBuilder: (context, i) {
                              final item = _items[i];
                              final isGanho = item['_tipo'] == 'ganho';
                              final valor = (item['valor'] as num).toDouble();
                              final data = (item['data'] as Timestamp?)?.toDate();
                              final dataStr = data != null ? DateFormat('dd/MM/yyyy').format(data) : '';
                              final descricao = item['descricao'] ?? item['categoria'] ?? (isGanho ? 'Ganho' : 'Gasto');
                              final cor = isGanho ? Colors.green : Colors.red;

                              return Dismissible(
                                key: Key(item['_id']),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade800,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete, color: Colors.white, size: 28),
                                      SizedBox(height: 4),
                                      Text('Apagar', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  bool confirmed = false;
                                  await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF1A2A3A),
                                      title: const Text('Apagar registro', style: TextStyle(color: Colors.white)),
                                      content: Text(
                                        'Apagar "$descricao" (${isGanho ? '+' : '-'} R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')})?',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () { Navigator.pop(ctx); confirmed = false; },
                                          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () { Navigator.pop(ctx); confirmed = true; },
                                          child: const Text('Apagar', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  return confirmed;
                                },
                                onDismissed: (direction) => _apagar(item, i),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: cor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isGanho ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: cor, size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(descricao, style: const TextStyle(
                                              color: Colors.white, fontWeight: FontWeight.w600)),
                                          Text('${isGanho ? 'Ganho' : (item['categoria'] ?? 'Gasto')} • $dataStr',
                                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        ]),
                                      ),
                                      Text(
                                        '${isGanho ? '+' : '-'} R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                                        style: TextStyle(color: cor, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _confirmarApagar(item, i),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.delete_outline,
                                              color: Colors.redAccent, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
