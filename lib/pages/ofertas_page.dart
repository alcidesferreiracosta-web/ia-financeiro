import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Link mascarado → Cloud Function → link afiliado real (nunca exposto)
const _redirectBase =
    'https://us-central1-i-a-financeiro-hq2c4c.cloudfunctions.net/redirectAfiliado';

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
        stream: FirebaseFirestore.instance
            .collection('ofertas')
            .where('ativo', isEqualTo: true)
            .orderBy('destaque', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhuma oferta disponível no momento.\nVolte em breve!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 15),
                ),
              ),
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) => _CardOferta(doc: docs[i]),
          );
        },
      ),
    );
  }
}

class _CardOferta extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _CardOferta({required this.doc});

  String _fmt(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final titulo = data['titulo'] as String? ?? '';
    final descricao = data['descricao'] as String? ?? '';
    final preco = (data['preco'] as num?)?.toDouble() ?? 0;
    final precoOriginal = (data['preco_original'] as num?)?.toDouble() ?? 0;
    final imagem = data['imagem_url'] as String? ?? '';
    final destaque = data['destaque'] as bool? ?? false;
    final freteGratis = data['frete_gratis'] as bool? ?? false;
    final redirectUrl = '$_redirectBase/${doc.id}';

    return Card(
      color: const Color(0xFF1A2A3A),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async =>
            await launchUrl(Uri.parse(redirectUrl),
                mode: LaunchMode.externalApplication),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: imagem.isNotEmpty
                  ? Image.network(
                      imagem,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge destaque
                  if (destaque)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: const Text('⭐ Em destaque',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),

                  // Título
                  Text(titulo,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),

                  // Descrição
                  if (descricao.isNotEmpty && descricao != titulo) ...[
                    const SizedBox(height: 4),
                    Text(descricao,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],

                  const SizedBox(height: 10),

                  // Preço
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmt(preco),
                          style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      if (precoOriginal > preco) ...[
                        const SizedBox(width: 8),
                        Text(_fmt(precoOriginal),
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.white38)),
                      ],
                    ],
                  ),

                  // Badges
                  if (freteGratis) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Frete grátis',
                          style:
                              TextStyle(color: Colors.green, fontSize: 11)),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Botão
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async => await launchUrl(
                          Uri.parse(redirectUrl),
                          mode: LaunchMode.externalApplication),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Ver Oferta',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 160,
      color: Colors.white10,
      child: const Icon(Icons.local_offer_outlined,
          color: Colors.white24, size: 48),
    );
  }
}
