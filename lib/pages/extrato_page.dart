import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExtratoPage extends StatelessWidget {
  const ExtratoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Extrato', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder(
        future: Future.wait([
          FirebaseFirestore.instance.collection('ganhos').where('userId', isEqualTo: uid).orderBy('data', descending: true).get(),
          FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: uid).orderBy('data', descending: true).get(),
        ]),
        builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final ganhos = snapshot.data![0].docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {...data, '_tipo': 'ganho', '_id': d.id};
          }).toList();

          final gastos = snapshot.data![1].docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {...data, '_tipo': 'gasto', '_id': d.id};
          }).toList();

          // Merge and sort by date
          final todos = [...ganhos, ...gastos];
          todos.sort((a, b) {
            final ta = (a['data'] as Timestamp?)?.toDate() ?? DateTime(0);
            final tb = (b['data'] as Timestamp?)?.toDate() ?? DateTime(0);
            return tb.compareTo(ta);
          });

          if (todos.isEmpty) {
            return const Center(child: Text('Nenhuma transação registrada', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            itemBuilder: (context, i) {
              final item = todos[i];
              final isGanho = item['_tipo'] == 'ganho';
              final valor = (item['valor'] as num).toDouble();
              final data = (item['data'] as Timestamp?)?.toDate();
              final dataStr = data != null ? DateFormat('dd/MM/yyyy').format(data) : '';
              final descricao = item['descricao'] ?? item['categoria'] ?? (isGanho ? 'Ganho' : 'Gasto');

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isGanho ? Colors.green : Colors.red).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isGanho ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isGanho ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(descricao, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text('${isGanho ? 'Ganho' : (item['categoria'] ?? 'Gasto')} • $dataStr',
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ]),
                    ),
                    Text(
                      '${isGanho ? '+' : '-'} R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(color: isGanho ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
