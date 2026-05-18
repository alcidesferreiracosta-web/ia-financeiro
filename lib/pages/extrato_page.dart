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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gastos')
            .where('userId', isEqualTo: uid)
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('Nenhum gasto registrado', style: TextStyle(color: Colors.white54)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final valor = (d['valor'] as num).toDouble();
              final data = (d['data'] as Timestamp?)?.toDate();
              final dataStr = data != null ? DateFormat('dd/MM/yyyy').format(data) : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d['descricao'] ?? d['categoria'] ?? 'Gasto',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text('${d['categoria'] ?? ''} • $dataStr',
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ]),
                    ),
                    Text('- R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
