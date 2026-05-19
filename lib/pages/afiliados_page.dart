import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ─── Configure seus IDs de afiliado aqui ───────────────────────────────────
const _mlAfiliadoId = '';        // Ex: 'MLB-123456' — Mercado Livre Afiliados
const _hotmartRefCode = '';      // Ex: 'abcd1234'   — Hotmart (seu código de ref)
const _amazonTag = '';           // Ex: 'seusite-20' — Amazon Associates tag
// ───────────────────────────────────────────────────────────────────────────

class AfiliadosPage extends StatefulWidget {
  const AfiliadosPage({super.key});
  @override
  State<AfiliadosPage> createState() => _AfiliadosPageState();
}

class _AfiliadosPageState extends State<AfiliadosPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Loja de Afiliados',
            style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Digital'),
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Físico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _TabDigital(),
          _TabFisico(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB DIGITAL — Cursos e eBooks (Hotmart + Amazon digital)
// ══════════════════════════════════════════════════════════════════════════════

class _TabDigital extends StatelessWidget {
  const _TabDigital();

  // Produtos digitais curados — troque os links pelos seus links de afiliado
  static const _produtos = [
    {
      'titulo': 'Curso Investimentos do Zero',
      'descricao': 'Aprenda a investir do zero com renda variável e fixa.',
      'preco': 'R\$ 97,00',
      'plataforma': 'Hotmart',
      'comissao': '40%',
      'cor': 0xFFFF6B00,
      'icone': Icons.school_outlined,
      'link': 'https://hotmart.com/marketplace',  // substitua pelo seu link de afiliado
    },
    {
      'titulo': 'eBook: Independência Financeira',
      'descricao': 'Guia completo para sair das dívidas e construir patrimônio.',
      'preco': 'R\$ 47,00',
      'plataforma': 'Hotmart',
      'comissao': '50%',
      'cor': 0xFFFF6B00,
      'icone': Icons.menu_book_outlined,
      'link': 'https://hotmart.com/marketplace',
    },
    {
      'titulo': 'Planilha de Controle Financeiro',
      'descricao': 'Planilha profissional para controlar ganhos e gastos.',
      'preco': 'R\$ 27,00',
      'plataforma': 'Hotmart',
      'comissao': '60%',
      'cor': 0xFFFF6B00,
      'icone': Icons.table_chart_outlined,
      'link': 'https://hotmart.com/marketplace',
    },
    {
      'titulo': 'Curso: Day Trade na Prática',
      'descricao': 'Estratégias reais de day trade para iniciantes e avançados.',
      'preco': 'R\$ 197,00',
      'plataforma': 'Hotmart',
      'comissao': '30%',
      'cor': 0xFFFF6B00,
      'icone': Icons.candlestick_chart_outlined,
      'link': 'https://hotmart.com/marketplace',
    },
    {
      'titulo': 'Mentoria: Renda Passiva Online',
      'descricao': 'Como criar fontes de renda passiva pela internet.',
      'preco': 'R\$ 397,00',
      'plataforma': 'Eduzz',
      'comissao': '35%',
      'cor': 0xFF6C2BD9,
      'icone': Icons.attach_money,
      'link': 'https://eduzz.com',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Você ganha comissão em cada venda feita pelo seu link.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _produtos.length,
            itemBuilder: (ctx, i) => _CardDigital(_produtos[i]),
          ),
        ),
      ],
    );
  }
}

class _CardDigital extends StatelessWidget {
  final Map<String, dynamic> produto;
  const _CardDigital(this.produto);

  @override
  Widget build(BuildContext context) {
    final cor = Color(produto['cor'] as int);
    return Card(
      color: const Color(0xFF1A2A3A),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final uri = Uri.parse(produto['link'] as String);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(produto['icone'] as IconData, color: cor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(produto['titulo'] as String,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(produto['plataforma'] as String,
                      style: TextStyle(color: cor, fontSize: 11)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${produto['comissao']} comissão',
                    style: const TextStyle(color: Colors.green, fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(produto['descricao'] as String,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(produto['preco'] as String,
                  style: const TextStyle(
                      color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(produto['link'] as String);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Ver produto', style: TextStyle(fontSize: 13)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB FÍSICO — Busca Mercado Livre + Amazon
// ══════════════════════════════════════════════════════════════════════════════

class _TabFisico extends StatefulWidget {
  const _TabFisico();
  @override
  State<_TabFisico> createState() => _TabFisicoState();
}

class _TabFisicoState extends State<_TabFisico> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _resultados = [];
  String? _erro;

  final List<Map<String, dynamic>> _destaques = [
    {'nome': 'Smartphone', 'icone': Icons.smartphone},
    {'nome': 'Notebook', 'icone': Icons.laptop},
    {'nome': 'Televisão', 'icone': Icons.tv},
    {'nome': 'Fone de ouvido', 'icone': Icons.headphones},
    {'nome': 'Câmera', 'icone': Icons.camera_alt_outlined},
    {'nome': 'Impressora', 'icone': Icons.print_outlined},
  ];

  Future<void> _buscar(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _loading = true; _resultados = []; _erro = null; });
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final uri = Uri.parse(
          'https://api.mercadolibre.com/sites/MLB/search?q=$encoded&limit=20');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List items = data['results'] ?? [];
        setState(() {
          _resultados = items.map<Map<String, dynamic>>((item) {
            String link = item['permalink'] ?? '';
            // Adiciona tag de afiliado do Mercado Livre se configurado
            if (_mlAfiliadoId.isNotEmpty) {
              link = '$link${link.contains('?') ? '&' : '?'}aff_id=$_mlAfiliadoId';
            }
            return {
              'titulo': item['title'] ?? '',
              'preco': (item['price'] ?? 0).toDouble(),
              'imagem': item['thumbnail'] ?? '',
              'link': link,
              'frete_gratis': item['shipping']?['free_shipping'] ?? false,
              'condicao': item['condition'] == 'new' ? 'Novo' : 'Usado',
              'vendidos': item['sold_quantity'] ?? 0,
            };
          }).toList();
        });
      } else {
        setState(() => _erro = 'Erro ao buscar. Tente novamente.');
      }
    } catch (_) {
      setState(() => _erro = 'Sem conexão com a internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(children: [
            TextField(
              controller: _ctrl,
              style: const TextStyle(color: Colors.white),
              onSubmitted: _buscar,
              decoration: InputDecoration(
                hintText: 'Buscar produto físico...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.orange)))
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _destaques.map((d) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(d['icone'] as IconData,
                        size: 14, color: Colors.orange),
                    label: Text(d['nome'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: Colors.white10,
                    side: const BorderSide(color: Colors.orange, width: 0.5),
                    onPressed: () {
                      _ctrl.text = d['nome'] as String;
                      _buscar(d['nome'] as String);
                    },
                  ),
                )).toList(),
              ),
            ),
          ]),
        ),
        Expanded(
          child: _resultados.isEmpty && !_loading
              ? _erro != null
                  ? Center(child: Text(_erro!,
                      style: const TextStyle(color: Colors.redAccent)))
                  : _buildPlaceholder()
              : _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _resultados.length,
                      itemBuilder: (ctx, i) => _buildCard(_resultados[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return Card(
      color: const Color(0xFF1A2A3A),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final uri = Uri.parse(item['link'] as String);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['imagem'] as String,
                width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 80, height: 80, color: Colors.white10,
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white24)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['titulo'] as String,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w500),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(_fmt(item['preco'] as double),
                    style: const TextStyle(
                        color: Colors.orange, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  if (item['frete_gratis'] as bool)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Frete grátis',
                          style: TextStyle(color: Colors.green, fontSize: 11)),
                    ),
                  const SizedBox(width: 6),
                  Text(item['condicao'] as String,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ]),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Icon(Icons.storefront_outlined, color: Colors.white24, size: 64),
        const SizedBox(height: 12),
        const Text('Busque produtos e ganhe comissão',
            style: TextStyle(color: Colors.white54, fontSize: 15)),
        const SizedBox(height: 6),
        const Text(
            'Cada venda feita pelo seu link gera comissão automática.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 24),
        ...[
          {'icone': Icons.link, 'texto': 'Mercado Livre Afiliados: até 12% por venda'},
          {'icone': Icons.star_outline, 'texto': 'Amazon Afiliados: até 10% em eletrônicos'},
          {'icone': Icons.shopping_cart_outlined, 'texto': 'Cadastre-se grátis nas plataformas'},
        ].map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Icon(d['icone'] as IconData, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            Text(d['texto'] as String,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        )),
      ]),
    );
  }
}
