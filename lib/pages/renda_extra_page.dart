import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Modelo de oportunidade ───────────────────────────────────────────────────
class _Oportunidade {
  final String nome;
  final String descricao;
  final String ganhoMin;
  final String ganhoMax;
  final String requisitos;
  final String categoria;
  final IconData icone;
  final Color cor;
  final String url;
  final String dificuldade; // 'Fácil' | 'Médio' | 'Avançado'

  const _Oportunidade({
    required this.nome,
    required this.descricao,
    required this.ganhoMin,
    required this.ganhoMax,
    required this.requisitos,
    required this.categoria,
    required this.icone,
    required this.cor,
    required this.url,
    required this.dificuldade,
  });
}

// ─── Dados ────────────────────────────────────────────────────────────────────
const _oportunidades = [
  // TRANSPORTE & ENTREGA
  _Oportunidade(
    nome: 'Uber',
    descricao: 'Transporte de passageiros pelo app. Defina seus horários e ganhe por corrida.',
    ganhoMin: 'R\$ 1.500', ganhoMax: 'R\$ 5.000',
    requisitos: 'Carro 2015+, CNH B, aprovação no app',
    categoria: 'Transporte',
    icone: Icons.directions_car, cor: Color(0xFF000000),
    url: 'https://www.uber.com/br/pt-br/drive/',
    dificuldade: 'Fácil',
  ),
  _Oportunidade(
    nome: '99',
    descricao: 'Alternativa ao Uber com menos taxas para o motorista. Corridas e mototáxi.',
    ganhoMin: 'R\$ 1.200', ganhoMax: 'R\$ 4.500',
    requisitos: 'Carro 2013+ ou moto, CNH',
    categoria: 'Transporte',
    icone: Icons.local_taxi, cor: Color(0xFFFFCC00),
    url: 'https://99app.com/motorista/',
    dificuldade: 'Fácil',
  ),
  _Oportunidade(
    nome: 'iFood — Entregador',
    descricao: 'Entrega de comida de bike, moto ou carro. Alta demanda nas refeições.',
    ganhoMin: 'R\$ 800', ganhoMax: 'R\$ 3.500',
    requisitos: 'Bike, moto ou carro. Bolsa térmica.',
    categoria: 'Transporte',
    icone: Icons.delivery_dining, cor: Color(0xFFEA1D2C),
    url: 'https://entregador.ifood.com.br/',
    dificuldade: 'Fácil',
  ),
  _Oportunidade(
    nome: 'Rappi',
    descricao: 'Entregas de supermercado, farmácia e restaurantes. Pagamento semanal.',
    ganhoMin: 'R\$ 700', ganhoMax: 'R\$ 3.000',
    requisitos: 'Bike ou moto, smartphone',
    categoria: 'Transporte',
    icone: Icons.pedal_bike, cor: Color(0xFFFF441A),
    url: 'https://rappitendero.com.br/',
    dificuldade: 'Fácil',
  ),
  _Oportunidade(
    nome: 'Loggi',
    descricao: 'Entregas de pacotes e e-commerce. Regiões planejadas, sem esperar cliente.',
    ganhoMin: 'R\$ 1.000', ganhoMax: 'R\$ 3.800',
    requisitos: 'Moto ou carro, CNH',
    categoria: 'Transporte',
    icone: Icons.local_shipping, cor: Color(0xFF00B4D8),
    url: 'https://www.loggi.com/parceiros/',
    dificuldade: 'Fácil',
  ),
  _Oportunidade(
    nome: 'Lalamove',
    descricao: 'Fretes e mudanças. Moto, van ou caminhão. Pedidos imediatos pelo app.',
    ganhoMin: 'R\$ 1.500', ganhoMax: 'R\$ 6.000',
    requisitos: 'Moto, van ou caminhão. CNH correspondente.',
    categoria: 'Transporte',
    icone: Icons.airport_shuttle, cor: Color(0xFFFF6600),
    url: 'https://www.lalamove.com/pt-BR/driver',
    dificuldade: 'Fácil',
  ),

  // SERVIÇOS
  _Oportunidade(
    nome: 'GetNinjas',
    descricao: 'Plataforma de serviços: elétrica, pintura, informática, faxina e muito mais.',
    ganhoMin: 'R\$ 800', ganhoMax: 'R\$ 5.000',
    requisitos: 'Habilidade na área, comprar créditos para propostas',
    categoria: 'Serviços',
    icone: Icons.handyman, cor: Color(0xFF1A73E8),
    url: 'https://www.getninjas.com.br/anuncie/',
    dificuldade: 'Fácil',
  ),
  _Oportunidade(
    nome: 'Superprof — Aulas',
    descricao: 'Dê aulas particulares do que você sabe: matemática, inglês, violão, esportes.',
    ganhoMin: 'R\$ 30', ganhoMax: 'R\$ 120/hora',
    requisitos: 'Conhecimento na área. Sem curso obrigatório.',
    categoria: 'Serviços',
    icone: Icons.school, cor: Color(0xFFFF6B35),
    url: 'https://www.superprof.com.br/ensinar/',
    dificuldade: 'Fácil',
  ),
  _Oportunidade(
    nome: 'Airbnb — Anfitrião',
    descricao: 'Alugue um quarto ou imóvel. Ganho alto sem sair de casa.',
    ganhoMin: 'R\$ 600', ganhoMax: 'R\$ 8.000',
    requisitos: 'Quarto ou imóvel disponível para alugar',
    categoria: 'Serviços',
    icone: Icons.home, cor: Color(0xFFFF5A5F),
    url: 'https://www.airbnb.com.br/host/homes',
    dificuldade: 'Médio',
  ),
  _Oportunidade(
    nome: 'Marmita & Doces',
    descricao: 'Venda marmitas, bolos, salgados e doces pelo WhatsApp, iFood ou vizinhança.',
    ganhoMin: 'R\$ 500', ganhoMax: 'R\$ 4.000',
    requisitos: 'Habilidade culinária, materiais básicos',
    categoria: 'Serviços',
    icone: Icons.lunch_dining, cor: Color(0xFF4CAF50),
    url: 'https://www.ifood.com.br/restaurantes',
    dificuldade: 'Fácil',
  ),

  // VENDAS
  _Oportunidade(
    nome: 'Mercado Livre',
    descricao: 'Venda produtos novos ou usados. Maior marketplace do Brasil com 50M de usuários.',
    ganhoMin: 'R\$ 500', ganhoMax: 'R\$ 15.000',
    requisitos: 'Produtos para vender. Conta gratuita.',
    categoria: 'Vendas',
    icone: Icons.storefront, cor: Color(0xFFFFE600),
    url: 'https://www.mercadolivre.com.br/anunciar',
    dificuldade: 'Fácil',
  ),
  _Oportunidade(
    nome: 'Shopee',
    descricao: 'Loja virtual gratuita com frete subsidiado. Ideal para iniciantes.',
    ganhoMin: 'R\$ 300', ganhoMax: 'R\$ 10.000',
    requisitos: 'Produtos para vender. Conta gratuita.',
    categoria: 'Vendas',
    icone: Icons.shopping_bag, cor: Color(0xFFEE4D2D),
    url: 'https://seller.shopee.com.br/',
    dificuldade: 'Fácil',
  ),
  _Oportunidade(
    nome: 'Dropshipping',
    descricao: 'Venda sem estoque. Você anuncia, fornecedor entrega. Margem de 20-60%.',
    ganhoMin: 'R\$ 1.000', ganhoMax: 'R\$ 20.000',
    requisitos: 'Capital inicial pequeno. Loja online.',
    categoria: 'Vendas',
    icone: Icons.inventory_2, cor: Color(0xFF7C4DFF),
    url: 'https://www.shopify.com.br/',
    dificuldade: 'Médio',
  ),
  _Oportunidade(
    nome: 'OLX — Brechó',
    descricao: 'Venda roupas, eletrônicos e móveis usados. Rápido para começar.',
    ganhoMin: 'R\$ 200', ganhoMax: 'R\$ 2.000',
    requisitos: 'Itens que não usa mais. Conta gratuita.',
    categoria: 'Vendas',
    icone: Icons.sell, cor: Color(0xFF6C2D91),
    url: 'https://www.olx.com.br/',
    dificuldade: 'Fácil',
  ),

  // DIGITAL
  _Oportunidade(
    nome: 'Afiliado — ML/Hotmart',
    descricao: 'Divulgue produtos e ganhe comissão por venda. Funciona 24h sem você trabalhar.',
    ganhoMin: 'R\$ 200', ganhoMax: 'R\$ 10.000',
    requisitos: 'Celular e redes sociais. Curso não obrigatório.',
    categoria: 'Digital',
    icone: Icons.link, cor: Color(0xFF00BCD4),
    url: 'https://www.hotmart.com/marketplace',
    dificuldade: 'Fácil',
  ),
  _Oportunidade(
    nome: 'TikTok Creator',
    descricao: 'Crie vídeos curtos e ganhe com o Creator Fund, Lives e parcerias de marca.',
    ganhoMin: 'R\$ 300', ganhoMax: 'R\$ 15.000',
    requisitos: 'Celular com câmera. Conta TikTok.',
    categoria: 'Digital',
    icone: Icons.play_circle_filled, cor: Color(0xFF010101),
    url: 'https://www.tiktok.com/creators/creator-portal/',
    dificuldade: 'Médio',
  ),
  _Oportunidade(
    nome: 'YouTube',
    descricao: 'Canal no YouTube monetizado com AdSense. Renda passiva após crescer.',
    ganhoMin: 'R\$ 500', ganhoMax: 'R\$ 30.000',
    requisitos: '1.000 inscritos e 4.000h assistidas para monetizar.',
    categoria: 'Digital',
    icone: Icons.smart_display, cor: Color(0xFFFF0000),
    url: 'https://www.youtube.com/creators/',
    dificuldade: 'Avançado',
  ),
  _Oportunidade(
    nome: '99Freelas',
    descricao: 'Freelancer de design, código, redação, tradução e marketing digital.',
    ganhoMin: 'R\$ 50', ganhoMax: 'R\$ 8.000',
    requisitos: 'Habilidade específica. Portfólio ajuda.',
    categoria: 'Digital',
    icone: Icons.computer, cor: Color(0xFF2196F3),
    url: 'https://www.99freelas.com.br/',
    dificuldade: 'Médio',
  ),
  _Oportunidade(
    nome: 'Workana',
    descricao: 'Plataforma de freelancers com projetos nacionais e internacionais.',
    ganhoMin: 'R\$ 80', ganhoMax: 'R\$ 12.000',
    requisitos: 'Portfolio e inglês básico para projetos internacionais.',
    categoria: 'Digital',
    icone: Icons.work, cor: Color(0xFF00897B),
    url: 'https://www.workana.com/register/freelancer',
    dificuldade: 'Médio',
  ),
  _Oportunidade(
    nome: 'Hotmart — Infoprodutos',
    descricao: 'Crie e venda cursos, eBooks e mentorias online. Alta margem de lucro.',
    ganhoMin: 'R\$ 1.000', ganhoMax: 'R\$ 50.000',
    requisitos: 'Conhecimento em alguma área. Dedicação para criar conteúdo.',
    categoria: 'Digital',
    icone: Icons.menu_book, cor: Color(0xFFFF4C00),
    url: 'https://www.hotmart.com/product/criar-produto',
    dificuldade: 'Avançado',
  ),
];

const _categorias = ['Todas', 'Transporte', 'Serviços', 'Vendas', 'Digital'];

// ─── Page ────────────────────────────────────────────────────────────────────
class RendaExtraPage extends StatefulWidget {
  const RendaExtraPage({super.key});
  @override
  State<RendaExtraPage> createState() => _RendaExtraPageState();
}

class _RendaExtraPageState extends State<RendaExtraPage> {
  String _filtro = 'Todas';

  List<_Oportunidade> get _filtradas => _filtro == 'Todas'
      ? _oportunidades
      : _oportunidades.where((o) => o.categoria == _filtro).toList();

  Color _corDificuldade(String d) {
    switch (d) {
      case 'Fácil': return Colors.greenAccent;
      case 'Médio': return Colors.orange;
      default: return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Renda Extra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Header motivacional
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_oportunidades.length} formas de ganhar mais',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text('Selecione e comece hoje mesmo',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
              ])),
            ]),
          ),

          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categorias.map((c) {
                  final ativo = _filtro == c;
                  return GestureDetector(
                    onTap: () => setState(() => _filtro = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: ativo ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ativo ? Colors.green : Colors.white24),
                      ),
                      child: Text(c,
                          style: TextStyle(
                            color: ativo ? Colors.white : Colors.white54,
                            fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Lista
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _filtradas.length,
              itemBuilder: (_, i) => _CardOportunidade(
                op: _filtradas[i],
                corDificuldade: _corDificuldade(_filtradas[i].dificuldade),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────
class _CardOportunidade extends StatelessWidget {
  final _Oportunidade op;
  final Color corDificuldade;
  const _CardOportunidade({required this.op, required this.corDificuldade});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cabeçalho
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: op.cor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(op.icone, color: op.cor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(op.nome, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: corDificuldade.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: corDificuldade.withOpacity(0.4)),
                  ),
                  child: Text(op.dificuldade,
                      style: TextStyle(color: corDificuldade, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(op.categoria,
                      style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ),
              ]),
            ])),
            // Ganho estimado
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('até', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text(op.ganhoMax,
                  style: const TextStyle(
                      color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              const Text('/mês', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ]),

          const SizedBox(height: 10),
          Text(op.descricao,
              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4)),

          const SizedBox(height: 8),

          // Requisitos
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_box_outline_blank, color: Colors.white24, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(op.requisitos,
                style: const TextStyle(color: Colors.white38, fontSize: 12))),
          ]),

          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // Barra de ganho + botão
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ganho estimado', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('${op.ganhoMin} – ${op.ganhoMax}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            ])),
            ElevatedButton(
              onPressed: () async {
                try {
                  await launchUrl(Uri.parse(op.url), mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Começar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ]),
      ),
    );
  }
}
