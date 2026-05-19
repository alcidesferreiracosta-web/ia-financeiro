import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OfertasPage extends StatefulWidget {
  const OfertasPage({super.key});
  @override
  State<OfertasPage> createState() => _OfertasPageState();
}

class _OfertasPageState extends State<OfertasPage> {
  final _searchController = TextEditingController();

  static const _categorias = [
    ('📺 Televisão', 'televisão 4K melhor preço'),
    ('📱 Celular', 'smartphone melhor custo benefício'),
    ('💻 Notebook', 'notebook melhor preço'),
    ('🎮 Videogame', 'console videogame oferta'),
    ('🍳 Eletrodoméstico', 'eletrodoméstico promoção'),
    ('❄️ Ar-condicionado', 'ar condicionado split oferta'),
    ('🛋️ Móveis', 'móveis sala quarto promoção'),
    ('👟 Tênis', 'tênis melhor preço'),
    ('🎧 Fone', 'fone bluetooth oferta'),
    ('📷 Câmera', 'câmera fotográfica melhor preço'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pesquisar(String query) async {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    final encoded = Uri.encodeComponent(query.trim());
    final uri = Uri.parse('https://www.google.com/search?q=$encoded&tbm=shop&hl=pt-BR');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o navegador.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Melhores Ofertas', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _pesquisar,
                  decoration: InputDecoration(
                    hintText: 'O que você quer comprar?',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: () => _pesquisar(_searchController.text),
                child: const Text('Buscar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.open_in_browser, color: Color(0xFF4FC3F7), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Os resultados abrem no Google Shopping pelo navegador',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 20),
            const Text('Categorias populares',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _categorias.length,
              itemBuilder: (ctx, i) {
                final (label, query) = _categorias[i];
                return InkWell(
                  onTap: () {
                    _searchController.text = label.substring(3);
                    _pesquisar(query);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    alignment: Alignment.center,
                    child: Text(label,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('Dicas de compra inteligente',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _Dica('🔍 Compare preços', 'Pesquise em pelo menos 3 lojas antes de comprar'),
            const SizedBox(height: 8),
            _Dica('⏳ Espere promoções', 'Black Friday e Dia do Consumidor têm descontos reais'),
            const SizedBox(height: 8),
            _Dica('💳 Prefira PIX ou débito', 'Parcelado tem juros; prefira à vista sempre que possível'),
            const SizedBox(height: 8),
            _Dica('🏷️ Veja o histórico de preços', 'Use Zoom ou Buscapé para confirmar se o desconto é real'),
          ],
        ),
      ),
    );
  }
}

class _Dica extends StatelessWidget {
  final String titulo;
  final String descricao;
  const _Dica(this.titulo, this.descricao);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Text(descricao, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }
}
