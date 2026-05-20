import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ── Seus IDs de afiliado (preencha após cadastro) ──────────────────────────
const _mlAfiliadoId = '450000067'; // Mercado Livre — User ID afiliado
const _hotmartRef = '';       // Hotmart → hotmart.com → Mercado de Afiliados → seu código
const _amazonTag = '';        // Amazon → associados-amazon.com.br → sua tag
const _shopeeAffId = '';      // Shopee Afiliados → affiliate.shopee.com.br → Site ID
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
        title: const Text('Produtos Recomendados',
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
        children: const [_TabDigital(), _TabFisico()],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Busca genérica no Mercado Livre (reutilizada nas duas abas)
// ══════════════════════════════════════════════════════════════════════════════

Future<List<Map<String, dynamic>>> _buscarML(
    String query, {String? categoria}) async {
  var url =
      'https://api.mercadolibre.com/sites/MLB/search?q=${Uri.encodeComponent(query)}&limit=20';
  if (categoria != null) url += '&category=$categoria';
  final res =
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) return [];
  final List items = jsonDecode(res.body)['results'] ?? [];
  return items.map<Map<String, dynamic>>((item) {
    String link = item['permalink'] as String? ?? '';
    if (_mlAfiliadoId.isNotEmpty) {
      link += '${link.contains('?') ? '&' : '?'}affiliation_id=$_mlAfiliadoId';
    }
    return {
      'titulo': item['title'] ?? '',
      'preco': (item['price'] ?? 0).toDouble(),
      'imagem': (item['thumbnail'] as String? ?? '').replaceFirst('http:', 'https:'),
      'link': link,
      'frete_gratis': item['shipping']?['free_shipping'] ?? false,
      'condicao': item['condition'] == 'new' ? 'Novo' : 'Usado',
      'vendidos': item['sold_quantity'] ?? 0,
    };
  }).toList();
}

// ── Link de afiliado Hotmart (automático pelo código do produto) ────────────
String _hotmartLink(String productCode) {
  final base = 'https://pay.hotmart.com/$productCode';
  return _hotmartRef.isNotEmpty ? '$base?ref=$_hotmartRef' : base;
}

// ── Busca Shopee Brasil ─────────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> _buscarShopee(String query) async {
  final encoded = Uri.encodeComponent(query.trim());
  final uri = Uri.parse(
    'https://shopee.com.br/api/v4/search/search_items'
    '?by=relevancy&keyword=$encoded&limit=20&newest=0'
    '&order=desc&page_type=search&scenario=PAGE_GLOBAL_SEARCH&version=2',
  );
  final res = await http.get(uri, headers: {
    'User-Agent': 'Mozilla/5.0',
    'Referer': 'https://shopee.com.br',
    'x-api-source': 'pc',
  }).timeout(const Duration(seconds: 12));

  if (res.statusCode != 200) return [];

  final data = jsonDecode(res.body);
  final List items = data['items'] ?? [];
  return items.map<Map<String, dynamic>>((e) {
    final info = e['item_basic'] ?? e;
    final shopId = info['shopid'] ?? 0;
    final itemId = info['itemid'] ?? 0;
    final nome = (info['name'] as String? ?? '').replaceAll(' ', '-');
    String link = 'https://shopee.com.br/$nome-i.$shopId.$itemId';
    if (_shopeeAffId.isNotEmpty) link += '?af_siteid=$_shopeeAffId&smtt=0.0';
    final thumb = info['image'] as String? ?? '';
    return {
      'titulo': info['name'] ?? '',
      'preco': ((info['price'] ?? 0) / 100000).toDouble(),
      'imagem': thumb.isNotEmpty
          ? 'https://cf.shopee.com.br/file/$thumb'
          : '',
      'link': link,
      'frete_gratis': (info['show_free_shipping'] ?? false) as bool,
      'condicao': 'Novo',
      'vendidos': info['sold'] ?? 0,
    };
  }).toList();
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB DIGITAL — busca por cursos e eBooks no ML (categoria Cursos Online)
// + produtos em destaque do Hotmart com link de afiliado automático
// ══════════════════════════════════════════════════════════════════════════════

class _TabDigital extends StatefulWidget {
  const _TabDigital();
  @override
  State<_TabDigital> createState() => _TabDigitalState();
}

class _TabDigitalState extends State<_TabDigital> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _resultados = [];
  String? _erro;
  String _fonte = 'ml'; // 'ml' ou 'hotmart'

  // Produtos populares Hotmart — atualiza com seus links de afiliado
  static const _hotmartDestaques = [
    {
      'titulo': 'Fórmula Negócio Online',
      'descricao': 'O curso de marketing digital mais vendido do Brasil.',
      'preco': 'R\$ 197,00',
      'comissao': '40%',
      'code': 'B4958963T',
    },
    {
      'titulo': 'Viver de Renda',
      'descricao': 'Aprenda a investir e criar renda passiva do zero.',
      'preco': 'R\$ 97,00',
      'comissao': '50%',
      'code': 'O86443985T',
    },
    {
      'titulo': 'Método CDA de Finanças',
      'descricao': 'Controle financeiro e planejamento pessoal.',
      'preco': 'R\$ 67,00',
      'comissao': '45%',
      'code': 'N70805064L',
    },
    {
      'titulo': 'Riqueza Interior — Mentalidade Financeira',
      'descricao': 'Reprogramação da mentalidade para atrair prosperidade.',
      'preco': 'R\$ 47,00',
      'comissao': '60%',
      'code': 'K14836679S',
    },
    {
      'titulo': 'Investidor de Sucesso',
      'descricao': 'Carteira de investimentos, ações, FIIs e tesouro direto.',
      'preco': 'R\$ 247,00',
      'comissao': '30%',
      'code': 'H65498214Y',
    },
    {
      'titulo': 'Criando Meu Negócio Online',
      'descricao': 'Venda produtos digitais e físicos pela internet.',
      'preco': 'R\$ 127,00',
      'comissao': '40%',
      'code': 'P24167453R',
    },
  ];

  final List<String> _categoriasML = [
    'curso finanças', 'ebook finanças', 'curso investimento',
    'curso marketing digital', 'ebook empreendedorismo',
  ];

  Future<void> _buscarDigital(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _loading = true; _resultados = []; _erro = null; _fonte = 'ml'; });
    try {
      // MLB267349 = Cursos e Capacitação no ML
      final items = await _buscarML(query, categoria: 'MLB267349');
      if (items.isEmpty) {
        final itemsSemFiltro = await _buscarML('curso $query');
        setState(() => _resultados = itemsSemFiltro);
      } else {
        setState(() => _resultados = items);
      }
    } catch (_) {
      setState(() => _erro = 'Sem conexão com a internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
              onSubmitted: _buscarDigital,
              decoration: InputDecoration(
                hintText: 'Buscar curso, eBook, planilha...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                prefixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white54),
                  onPressed: () => _buscarDigital(_ctrl.text),
                ),
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
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categoriasML.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(c, style: const TextStyle(
                        color: Colors.white, fontSize: 12)),
                    backgroundColor: Colors.white10,
                    side: const BorderSide(color: Colors.orange, width: 0.5),
                    onPressed: () {
                      _ctrl.text = c;
                      _buscarDigital(c);
                    },
                  ),
                )).toList(),
              ),
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : _erro != null
                  ? Center(child: Text(_erro!,
                      style: const TextStyle(color: Colors.redAccent)))
                  : _resultados.isNotEmpty
                      ? _listaML()
                      : _listaHotmart(),
        ),
      ],
    );
  }

  Widget _listaML() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _resultados.length,
      itemBuilder: (_, i) => _CardProduto(_resultados[i]),
    );
  }

  Widget _listaHotmart() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Cursos e eBooks em destaque',
              style: TextStyle(color: Colors.white70,
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        ..._hotmartDestaques.map((p) => _CardHotmart(p)),
      ],
    );
  }
}

class _CardHotmart extends StatelessWidget {
  final Map<String, dynamic> produto;
  const _CardHotmart(this.produto);

  @override
  Widget build(BuildContext context) {
    final link = _hotmartLink(produto['code'] as String);
    return Card(
      color: const Color(0xFF1A2A3A),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async =>
            await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_outline,
                  color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(produto['titulo'] as String,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold,
                        fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(produto['descricao'] as String,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(produto['preco'] as String,
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB FÍSICO — busca automática no ML + Amazon
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
  String _plataforma = 'ml'; // 'ml' | 'shopee'

  final List<Map<String, dynamic>> _chips = [
    {'nome': 'Smartphone', 'icone': Icons.smartphone},
    {'nome': 'Notebook', 'icone': Icons.laptop},
    {'nome': 'Televisão', 'icone': Icons.tv},
    {'nome': 'Fone bluetooth', 'icone': Icons.headphones},
    {'nome': 'Câmera', 'icone': Icons.camera_alt_outlined},
    {'nome': 'Smartwatch', 'icone': Icons.watch_outlined},
    {'nome': 'Geladeira', 'icone': Icons.kitchen},
    {'nome': 'Ar condicionado', 'icone': Icons.ac_unit},
  ];

  Future<void> _buscar(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _loading = true; _resultados = []; _erro = null; });
    try {
      final items = _plataforma == 'shopee'
          ? await _buscarShopee(query)
          : await _buscarML(query);
      setState(() => _resultados = items);
      if (items.isEmpty) setState(() => _erro = 'Nenhum produto encontrado.');
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
        // Seletor de plataforma
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(children: [
            _BotaoPlataforma(
              label: 'Mercado Livre',
              cor: const Color(0xFF1DB954),
              ativo: _plataforma == 'ml',
              onTap: () {
                setState(() { _plataforma = 'ml'; _resultados = []; });
                if (_ctrl.text.isNotEmpty) _buscar(_ctrl.text);
              },
            ),
            const SizedBox(width: 8),
            _BotaoPlataforma(
              label: 'Shopee',
              cor: const Color(0xFFEE4D2D),
              ativo: _plataforma == 'shopee',
              onTap: () {
                setState(() { _plataforma = 'shopee'; _resultados = []; });
                if (_ctrl.text.isNotEmpty) _buscar(_ctrl.text);
              },
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(children: [
            TextField(
              controller: _ctrl,
              style: const TextStyle(color: Colors.white),
              onSubmitted: _buscar,
              decoration: InputDecoration(
                hintText: 'Buscar produto...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                prefixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white54),
                  onPressed: () => _buscar(_ctrl.text),
                ),
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
                children: _chips.map((d) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(d['icone'] as IconData,
                        size: 14, color: Colors.orange),
                    label: Text(d['nome'] as String,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                    backgroundColor: Colors.white10,
                    side: const BorderSide(
                        color: Colors.orange, width: 0.5),
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
        if (_amazonTag.isNotEmpty)
          GestureDetector(
            onTap: () async {
              final q = _ctrl.text.trim();
              final url = q.isEmpty
                  ? 'https://www.amazon.com.br/?tag=$_amazonTag'
                  : 'https://www.amazon.com.br/s?k=${Uri.encodeComponent(q)}&tag=$_amazonTag';
              await launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9900).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFF9900).withOpacity(0.4)),
              ),
              child: Row(children: [
                const Text('amazon',
                    style: TextStyle(
                        color: Color(0xFFFF9900),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(width: 4),
                const Text('.com.br',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                const Text('Buscar também na Amazon →',
                    style: TextStyle(color: Color(0xFFFF9900), fontSize: 12)),
              ]),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange))
              : _resultados.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _resultados.length,
                      itemBuilder: (_, i) => _CardProduto(_resultados[i]),
                    )
                  : _erro != null
                      ? Center(
                          child: Text(_erro!,
                              style: const TextStyle(
                                  color: Colors.redAccent)))
                      : _buildPlaceholder(),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Icon(Icons.storefront_outlined,
            color: Colors.white24, size: 56),
        const SizedBox(height: 12),
        const Text('Encontre as melhores ofertas',
            style: TextStyle(color: Colors.white54, fontSize: 15)),
        const SizedBox(height: 18),
        ...[
          'Produtos selecionados para você',
          'Preços competitivos no Mercado Livre',
          'Entrega rápida e segura',
        ].map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Text(t,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 13)),
          ]),
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Botão seletor de plataforma
// ══════════════════════════════════════════════════════════════════════════════

class _BotaoPlataforma extends StatelessWidget {
  final String label;
  final Color cor;
  final bool ativo;
  final VoidCallback onTap;
  const _BotaoPlataforma(
      {required this.label, required this.cor, required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? cor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ativo ? cor : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? Colors.white : Colors.white54,
            fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Card compartilhado para resultados do ML
// ══════════════════════════════════════════════════════════════════════════════

class _CardProduto extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CardProduto(this.item);

  String _fmt(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
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
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['imagem'] as String,
                width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80, height: 80, color: Colors.white10,
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
                    Text(item['titulo'] as String,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13,
                            fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
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
                              style: TextStyle(
                                  color: Colors.green, fontSize: 11)),
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
}
