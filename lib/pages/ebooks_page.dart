import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EbooksPage extends StatelessWidget {
  const EbooksPage({super.key});

  static const kitsJornada = [
    {
      'titulo': 'Kit Starter',
      'subtitulo': '3 eBooks — Passo 1',
      'preco': 'R\$ 67',
      'de': 'De R\$ 113,70',
      'badge': 'POPULAR',
      'url': 'https://pay.kiwify.com.br/6lm6Iih',
      'cor': Color(0xFF1A237E),
    },
    {
      'titulo': 'Kit Acelerador',
      'subtitulo': '9 eBooks — Passos 1, 2 e 3',
      'preco': 'R\$ 147',
      'de': 'De R\$ 341,10',
      'badge': 'MAIS VENDIDO',
      'url': 'https://pay.kiwify.com.br/6rVEIGm',
      'cor': Color(0xFF4A148C),
    },
    {
      'titulo': 'Jornada Completa',
      'subtitulo': 'Todos os 12 eBooks',
      'preco': 'R\$ 197',
      'de': 'De R\$ 454,80',
      'badge': 'MELHOR VALOR',
      'url': 'https://pay.kiwify.com.br/vsIk65Y',
      'cor': Color(0xFFBF360C),
    },
  ];

  static const kitsTematicos = [
    {
      'titulo': 'Kit Finanças Pessoais',
      'subtitulo': '3 eBooks de finanças',
      'preco': 'R\$ 67',
      'de': 'De R\$ 103,70',
      'badge': 'FINANÇAS',
      'url': 'https://pay.kiwify.com.br/t5mj2Et',
      'cor': Color(0xFF00695C),
    },
    {
      'titulo': 'Kit Marketing Digital',
      'subtitulo': '3 eBooks de marketing',
      'preco': 'R\$ 67',
      'de': 'De R\$ 113,70',
      'badge': 'MARKETING',
      'url': 'https://pay.kiwify.com.br/V5nVOCd',
      'cor': Color(0xFF4A148C),
    },
    {
      'titulo': 'Kit Renda Extra',
      'subtitulo': '3 eBooks de renda extra',
      'preco': 'R\$ 67',
      'de': 'De R\$ 123,70',
      'badge': 'RENDA EXTRA',
      'url': 'https://pay.kiwify.com.br/oUsY51z',
      'cor': Color(0xFF2E7D32),
    },
    {
      'titulo': 'Kit Investimentos',
      'subtitulo': '3 eBooks de investimentos',
      'preco': 'R\$ 97',
      'de': 'De R\$ 133,70',
      'badge': 'INVESTIMENTOS',
      'url': 'https://pay.kiwify.com.br/RUOaYx7',
      'cor': Color(0xFF1B5E20),
    },
  ];

  static const ebooks = [
    {
      'n': '01',
      'titulo': 'Copywriting com IA para Iniciantes',
      'preco': 'R\$ 37,90',
      'url': 'https://pay.kiwify.com.br/Z1ZLyxD',
      'emoji': '✍️',
      'cor': Color(0xFF1565C0),
      'desc': 'Escreva textos que vendem usando IA e multiplique suas conversões',
    },
    {
      'n': '02',
      'titulo': 'Instagram e TikTok para Vender Mais',
      'preco': 'R\$ 37,90',
      'url': 'https://pay.kiwify.com.br/5cC2Gso',
      'emoji': '📱',
      'cor': Color(0xFFAD1457),
      'desc': 'Estratégias para explodir seguidores e vendas nas redes sociais',
    },
    {
      'n': '03',
      'titulo': 'Renda Passiva com Produtos Digitais',
      'preco': 'R\$ 37,90',
      'url': 'https://pay.kiwify.com.br/2XHrfps',
      'emoji': '💰',
      'cor': Color(0xFF2E7D32),
      'desc': 'Ganhe dinheiro enquanto dorme com sistemas automatizados de renda',
    },
    {
      'n': '04',
      'titulo': 'Planejamento Financeiro em 30 Dias',
      'preco': 'R\$ 27,90',
      'url': 'https://pay.kiwify.com.br/ZDsTaF1',
      'emoji': '📅',
      'cor': Color(0xFF00695C),
      'desc': 'Plano prático mês a mês para organizar suas finanças do zero',
    },
    {
      'n': '05',
      'titulo': 'Como Criar e Vender Infoprodutos',
      'preco': 'R\$ 37,90',
      'url': 'https://pay.kiwify.com.br/K4ImSkf',
      'emoji': '🚀',
      'cor': Color(0xFF6A1B9A),
      'desc': 'Lance seu eBook, curso ou mentoria usando IA para criar tudo',
    },
    {
      'n': '06',
      'titulo': 'Finanças com IA: O Guia Definitivo',
      'preco': 'R\$ 37,90',
      'url': 'https://pay.kiwify.com.br/NZPtsP4',
      'emoji': '📊',
      'cor': Color(0xFF1A237E),
      'desc': 'Organize, economize e crie renda extra com IA em 30 dias',
    },
    {
      'n': '07',
      'titulo': 'Renda Extra com IA: 50 Formas',
      'preco': 'R\$ 47,90',
      'url': 'https://pay.kiwify.com.br/dXcT1bp',
      'emoji': '💡',
      'cor': Color(0xFFE65100),
      'desc': '50 formas comprovadas de ganhar dinheiro extra com IA em 2026',
    },
    {
      'n': '08',
      'titulo': 'Investimentos com IA: Do Zero ao 1º Milhão',
      'preco': 'R\$ 57,90',
      'url': 'https://pay.kiwify.com.br/2kyii2i',
      'emoji': '📈',
      'cor': Color(0xFF1B5E20),
      'desc': 'Aprenda a investir em CDB, Tesouro e ações com ajuda da IA',
    },
    {
      'n': '09',
      'titulo': 'Diga Adeus às Dívidas',
      'preco': 'R\$ 37,90',
      'url': 'https://pay.kiwify.com.br/6Ng1b7X',
      'emoji': '🔓',
      'cor': Color(0xFFB71C1C),
      'desc': 'Método comprovado para eliminar dívidas e conquistar liberdade financeira',
    },
    {
      'n': '10',
      'titulo': 'Guia Completo de Renda Extra no Brasil',
      'preco': 'R\$ 37,90',
      'url': 'https://pay.kiwify.com.br/CAQ8GUK',
      'emoji': '🇧🇷',
      'cor': Color(0xFF2E7D32),
      'desc': '15 formas comprovadas de ganhar dinheiro extra no Brasil',
    },
    {
      'n': '11',
      'titulo': 'Marketing Digital com IA',
      'preco': 'R\$ 37,90',
      'url': 'https://pay.kiwify.com.br/qvt30BI',
      'emoji': '🎯',
      'cor': Color(0xFF4A148C),
      'desc': 'Guia definitivo para empreendedores dominarem o marketing com IA',
    },
    {
      'n': '12',
      'titulo': 'Tráfego Pago com IA',
      'preco': 'R\$ 37,90',
      'url': 'https://pay.kiwify.com.br/BxdF6mG',
      'emoji': '📣',
      'cor': Color(0xFF0D47A1),
      'desc': 'Anuncie no Google e Meta com estratégias de IA para vender mais',
    },
  ];

  Future<void> _abrir(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(children: [
          Icon(Icons.menu_book, color: Colors.orange, size: 22),
          SizedBox(width: 8),
          Text('eBooks IA Financeiro',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📚 Biblioteca IA Financeiro',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('12 eBooks para transformar suas finanças e criar renda extra com inteligência artificial.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Kits Jornada
          const Text('🔥 Kits Jornada — Melhor Custo-Benefício',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Economize comprando a coleção completa',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 12),

          ...kitsJornada.map((kit) => _KitCard(kit: kit, onTap: () => _abrir(kit['url'] as String))),

          const SizedBox(height: 20),

          // Kits Temáticos
          const Text('🎯 Kits Temáticos',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Aprofunde em uma área específica',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 12),

          ...kitsTematicos.map((kit) => _KitCard(kit: kit, onTap: () => _abrir(kit['url'] as String))),

          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),

          // eBooks individuais
          const Text('📖 eBooks Individuais',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Escolha o que mais precisa agora',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 12),

          ...ebooks.map((e) => _EbookCard(ebook: e, onTap: () => _abrir(e['url'] as String))),
        ],
      ),
    );
  }
}

class _KitCard extends StatelessWidget {
  final Map kit;
  final VoidCallback onTap;
  const _KitCard({required this.kit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cor = kit['cor'] as Color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withOpacity(0.5)),
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_stories, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(kit['titulo'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
                child: Text(kit['badge'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(kit['subtitulo'] as String,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              Text(kit['de'] as String,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.white38)),
              const SizedBox(width: 8),
              Text(kit['preco'] as String,
                  style: const TextStyle(
                      color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Comprar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}

class _EbookCard extends StatelessWidget {
  final Map ebook;
  final VoidCallback onTap;
  const _EbookCard({required this.ebook, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cor = ebook['cor'] as Color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 60,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cor.withOpacity(0.5)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(ebook['emoji'] as String, style: const TextStyle(fontSize: 22)),
              Text(ebook['n'] as String,
                  style: TextStyle(color: cor, fontSize: 9, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ebook['titulo'] as String,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 3),
            Text(ebook['desc'] as String,
                style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.3)),
            const SizedBox(height: 6),
            Text(ebook['preco'] as String,
                style: TextStyle(color: cor, fontSize: 14, fontWeight: FontWeight.bold)),
          ])),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        ]),
      ),
    );
  }
}
