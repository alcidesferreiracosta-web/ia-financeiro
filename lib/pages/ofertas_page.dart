import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OfertasPage extends StatefulWidget {
  const OfertasPage({super.key});
  @override
  State<OfertasPage> createState() => _OfertasPageState();
}

class _OfertasPageState extends State<OfertasPage> {
  final _searchController = TextEditingController();
  bool _loading = false;

  final List<Map<String, dynamic>> _categorias = [
    {'nome': 'Televisão', 'icone': Icons.tv},
    {'nome': 'Celular', 'icone': Icons.smartphone},
    {'nome': 'Notebook', 'icone': Icons.laptop},
    {'nome': 'Geladeira', 'icone': Icons.kitchen},
    {'nome': 'Tênis', 'icone': Icons.directions_run},
    {'nome': 'Perfume', 'icone': Icons.spa},
    {'nome': 'Fone de ouvido', 'icone': Icons.headphones},
    {'nome': 'Videogame', 'icone': Icons.sports_esports},
    {'nome': 'Ar condicionado', 'icone': Icons.ac_unit},
    {'nome': 'Máquina de lavar', 'icone': Icons.local_laundry_service},
  ];

  Future<void> _pesquisar(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _loading = true);
    final encoded = Uri.encodeComponent(query.trim());
    final uri = Uri.parse('https://www.google.com/search?q=$encoded&tbm=shop');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      final fallback = Uri.parse('https://shopping.google.com/?q=$encoded');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Buscar Ofertas', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de pesquisa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Colors.orange, size: 28),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Google Shopping', style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: _pesquisar,
                    decoration: InputDecoration(
                      hintText: 'Ex: Televisão 55 polegadas...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : () => _pesquisar(_searchController.text),
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search),
                      label: const Text('Buscar as melhores ofertas',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Categorias populares', style: TextStyle(
              color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // Chips de categorias
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categorias.map((cat) {
                return ActionChip(
                  avatar: Icon(cat['icone'] as IconData, size: 16, color: Colors.orange),
                  label: Text(cat['nome'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                  backgroundColor: Colors.white10,
                  side: const BorderSide(color: Colors.orange, width: 0.5),
                  onPressed: () {
                    _searchController.text = cat['nome'] as String;
                    _pesquisar(cat['nome'] as String);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            const Text('Dicas para comprar melhor', style: TextStyle(
              color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            ...[
              {'icone': Icons.compare, 'cor': Colors.blue,
                'titulo': 'Compare preços', 'dica': 'Pesquise o mesmo produto em 3 lojas antes de comprar.'},
              {'icone': Icons.calendar_today, 'cor': Colors.green,
                'titulo': 'Aguarde datas especiais', 'dica': 'Black Friday, Dia do Consumidor e aniversários de lojas têm os maiores descontos.'},
              {'icone': Icons.credit_card_off, 'cor': Colors.orange,
                'titulo': 'Evite parcelas longas', 'dica': 'Parcelar em 12x parece fácil, mas você paga mais caro. Prefira à vista quando possível.'},
              {'icone': Icons.star_outline, 'cor': Colors.yellow,
                'titulo': 'Verifique avaliações', 'dica': 'Leia comentários reais de outros compradores antes de decidir.'},
            ].map((d) => Card(
              color: const Color(0xFF1A2A3A),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(d['icone'] as IconData, color: d['cor'] as Color, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d['titulo'] as String,
                            style: TextStyle(color: d['cor'] as Color,
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(d['dica'] as String,
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
