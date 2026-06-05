import 'package:cloud_firestore/cloud_firestore.dart';

const kCategorias = [
  'Todas',
  'Mercados',
  'Postos de combustível',
  'Farmácias',
  'Padarias',
  'Restaurantes',
  'Pizzarias',
  'Lanchonetes',
  'Materiais de construção',
  'Eletrônicos',
  'Roupas',
  'Serviços',
  'Outros',
];

class PromoModel {
  final String id;
  final String nomeEstabelecimento;
  final String categoria;
  final String produto;
  final double valorPromo;
  final double? valorOriginal;
  final String? fotoUrl;
  final double lat;
  final double lng;
  final String endereco;
  final String criadoPorUid;
  final String criadoPorNome;
  final int duracaoHoras;
  final DateTime inicio;
  final DateTime expiracao;
  final bool ativa;
  final int confirmacoes;
  final int curtidas;
  final int reportes;
  final int acessos;
  double? distanciaKm;

  PromoModel({
    required this.id,
    required this.nomeEstabelecimento,
    required this.categoria,
    required this.produto,
    required this.valorPromo,
    this.valorOriginal,
    this.fotoUrl,
    required this.lat,
    required this.lng,
    required this.endereco,
    required this.criadoPorUid,
    required this.criadoPorNome,
    required this.duracaoHoras,
    required this.inicio,
    required this.expiracao,
    required this.ativa,
    required this.confirmacoes,
    required this.curtidas,
    required this.reportes,
    required this.acessos,
    this.distanciaKm,
  });

  factory PromoModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PromoModel(
      id: doc.id,
      nomeEstabelecimento: d['nome_estabelecimento'] ?? '',
      categoria: d['categoria'] ?? 'Outros',
      produto: d['produto'] ?? '',
      valorPromo: (d['valor_promo'] as num?)?.toDouble() ?? 0,
      valorOriginal:
          d['valor_original'] != null ? (d['valor_original'] as num).toDouble() : null,
      fotoUrl: d['foto_url'],
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      endereco: d['endereco'] ?? '',
      criadoPorUid: d['criado_por_uid'] ?? '',
      criadoPorNome: d['criado_por_nome'] ?? 'Usuário',
      duracaoHoras: d['duracao_horas'] ?? 72,
      inicio: (d['inicio'] as Timestamp).toDate(),
      expiracao: (d['expiracao'] as Timestamp).toDate(),
      ativa: d['ativa'] ?? true,
      confirmacoes: d['confirmacoes'] ?? 0,
      curtidas: d['curtidas'] ?? 0,
      reportes: d['reportes'] ?? 0,
      acessos: d['acessos'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'nome_estabelecimento': nomeEstabelecimento,
        'categoria': categoria,
        'produto': produto,
        'valor_promo': valorPromo,
        'valor_original': valorOriginal,
        'foto_url': fotoUrl,
        'lat': lat,
        'lng': lng,
        'endereco': endereco,
        'criado_por_uid': criadoPorUid,
        'criado_por_nome': criadoPorNome,
        'duracao_horas': duracaoHoras,
        'inicio': Timestamp.fromDate(inicio),
        'expiracao': Timestamp.fromDate(expiracao),
        'ativa': ativa,
        'confirmacoes': confirmacoes,
        'curtidas': curtidas,
        'reportes': reportes,
        'acessos': acessos,
      };

  String get trustLevel {
    if (confirmacoes >= 3) return 'verde';
    if (confirmacoes >= 1) return 'amarelo';
    return 'vermelho';
  }

  Duration get tempoRestante => expiracao.difference(DateTime.now());
  bool get expirada => DateTime.now().isAfter(expiracao);

  double? get economia =>
      valorOriginal != null ? valorOriginal! - valorPromo : null;

  int? get percentualDesconto =>
      economia != null && valorOriginal! > 0
          ? (economia! / valorOriginal! * 100).round()
          : null;
}
