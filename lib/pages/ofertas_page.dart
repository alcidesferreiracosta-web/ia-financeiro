import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfertasPage extends StatelessWidget {
  const OfertasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Ofertas', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ofertas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.local_offer_outlined, color: Colors.white24, size: 64),
                const SizedBox(height: 16),
                const Text('Nenhuma oferta disponível', style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 8),
                const Text('As ofertas serão exibidas aqui', style: TextStyle(color: Colors.white30, fontSize: 13)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return Card(
                color: const Color(0xFF1A2A3A),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['titulo'] ?? d['nome'] ?? 'Oferta',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (d['descricao'] != null) ...[
                      const SizedBox(height: 6),
                      Text(d['descricao'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                    if (d['valor'] != null) ...[
                      const SizedBox(height: 8),
                      Text('R\$ ${(d['valor'] as num).toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
