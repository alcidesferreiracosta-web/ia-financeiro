import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class OfertasPage extends StatefulWidget {
  const OfertasPage({super.key});
  @override
  State<OfertasPage> createState() => _OfertasPageState();
}

class _OfertasPageState extends State<OfertasPage> {
  final _searchController = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _resultados = [];
  String? _erro;

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
    setState(() {
      _loading = true;
      _resultados = [];
      _erro = null;
    });

    try {
      final encoded = Uri.encodeComponent(query.trim());
      final uri = Uri.parse(
          'https://api.mercadolibre.com/sites/MLB/search?q=$encoded&limit=20');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['results'] ?? [];
        setState(() {
          _resultados = items.map<Map<String, dynamic>>((item) {
            return {
              'titulo': item['title'] ?? '',
              'preco': (item['price'] ?? 0).toDouble(),
              'imagem': item['thumbnail'] ?? '',
              'link': item['permalink'] ?? '',
              'frete_gratis': item['shipping']?['free_shipping'] ?? false,
              'condicao': item['condition'] == 'new' ? 'Novo' : 'Usado',
            };
          }).toList();
        });
      } else {
        setState(() => _erro = 'Erro ao buscar produtos. Tente novamente.');
      }
    } catch (_) {
      setState(() => _erro = 'Sem conexão. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(double v) {
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Buscar Ofertas',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: const Color(0xFF0D1B2A),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: _pesquisar,
                  decoration: InputDecoration(
                    hintText: 'Buscar produto...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.orange)),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _loading ? null : () => _pesquisar(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Buscar ofertas',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                // Chips de categorias
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categorias.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(cat['icone'] as IconData,
                              size: 15, color: Colors.orange),
                          label: Text(cat['nome'] as String,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          backgroundColor: Colors.white10,
                          side: const BorderSide(
                              color: Colors.orange, width: 0.5),
                          onPressed: () {
                            _searchController.text = cat['nome'] as String;
                            _pesquisar(cat['nome'] as String);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Resultados
          Expanded(
            child: _resultados.isEmpty && !_loading
                ? _erro != null
                    ? Center(
                        child: Text(_erro!,
                            style: const TextStyle(color: Colors.red)))
                    : _buildDicas()
                : _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _resultados.length,
                        itemBuilder: (ctx, i) =>
                            _buildCard(_resultados[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return Card(
      color: const Color(0xFF1A2A3A),
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final uri = Uri.parse(item['link'] as String);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['imagem'] as String,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.white10,
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['titulo'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmt(item['preco'] as double),
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item['frete_gratis'] as bool)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Frete grátis',
                                style: TextStyle(
                                    color: Colors.green, fontSize: 11)),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          item['condicao'] as String,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDicas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dicas para comprar melhor',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...[
            {
              'icone': Icons.compare,
              'cor': Colors.blue,
              'titulo': 'Compare preços',
              'dica':
                  'Pesquise o mesmo produto em 3 lojas antes de comprar.'
            },
            {
              'icone': Icons.calendar_today,
              'cor': Colors.green,
              'titulo': 'Aguarde datas especiais',
              'dica':
                  'Black Friday, Dia do Consumidor e aniversários de lojas têm os maiores descontos.'
            },
            {
              'icone': Icons.credit_card_off,
              'cor': Colors.orange,
              'titulo': 'Evite parcelas longas',
              'dica':
                  'Parcelar em 12x parece fácil, mas você paga mais caro. Prefira à vista quando possível.'
            },
            {
              'icone': Icons.star_outline,
              'cor': Colors.yellow,
              'titulo': 'Verifique avaliações',
              'dica':
                  'Leia comentários reais de outros compradores antes de decidir.'
            },
          ].map((d) => Card(
                color: const Color(0xFF1A2A3A),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(d['icone'] as IconData,
                          color: d['cor'] as Color, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['titulo'] as String,
                                  style: TextStyle(
                                      color: d['cor'] as Color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(d['dica'] as String,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ]),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
