import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OfertasPage extends StatefulWidget {
  const OfertasPage({super.key});
  @override
  State<OfertasPage> createState() => _OfertasPageState();
}

class _OfertasPageState extends State<OfertasPage> {
  final _searchController = TextEditingController();
  late final WebViewController _webController;
  bool _webViewVisivel = false;
  bool _carregando = false;
  String _queryAtual = '';

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
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.6099.144 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _carregando = true),
        onPageFinished: (_) => setState(() => _carregando = false),
        onWebResourceError: (_) => setState(() => _carregando = false),
      ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pesquisar(String query) {
    if (query.trim().isEmpty) return;
    final encoded = Uri.encodeComponent(query.trim());
    final url = 'https://www.google.com/search?q=$encoded&tbm=shop&hl=pt-BR';
    _webController.loadRequest(Uri.parse(url));
    setState(() {
      _webViewVisivel = true;
      _queryAtual = query.trim();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Melhores Ofertas', style: TextStyle(color: Colors.white)),
        actions: [
          if (_webViewVisivel)
            IconButton(
              icon: const Icon(Icons.grid_view, color: Colors.white54),
              tooltip: 'Categorias',
              onPressed: () => setState(() => _webViewVisivel = false),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onPressed: () => _pesquisar(_searchController.text),
                child: const Text('Buscar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),
          ),

          if (_webViewVisivel) ...[
            if (_carregando)
              const LinearProgressIndicator(
                  color: Color(0xFF4FC3F7),
                  backgroundColor: Colors.transparent),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Resultados para: "$_queryAtual"',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            Expanded(
              child: WebViewWidget(controller: _webController),
            ),
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('Categorias populares',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                                textAlign: TextAlign.center),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('Dicas de compra inteligente',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _Dica('🔍 Compare preços',
                        'Pesquise em pelo menos 3 lojas antes de comprar'),
                    const SizedBox(height: 8),
                    _Dica('⏳ Espere promoções',
                        'Black Friday e Dia do Consumidor têm descontos reais'),
                    const SizedBox(height: 8),
                    _Dica('💳 Prefira PIX ou débito',
                        'Parcelado tem juros; prefira à vista sempre que possível'),
                    const SizedBox(height: 8),
                    _Dica('🏷️ Veja o histórico de preços',
                        'Use Zoom ou Buscapé para confirmar se o desconto é real'),
                  ],
                ),
              ),
            ),
          ],
        ],
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
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        const SizedBox(height: 4),
        Text(descricao,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }
}
