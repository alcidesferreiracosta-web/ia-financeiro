import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/promocao_model.dart';
import '../services/gps_economia_service.dart';
import 'cadastrar_promocao_page.dart';
import 'ranking_gps_page.dart';

// ── Helpers de categoria ──────────────────────────────────────────────────────

IconData categoriaIcon(String cat) {
  switch (cat) {
    case 'Mercados':
      return Icons.shopping_cart;
    case 'Postos de combustível':
      return Icons.local_gas_station;
    case 'Farmácias':
      return Icons.local_pharmacy;
    case 'Padarias':
      return Icons.bakery_dining;
    case 'Restaurantes':
      return Icons.restaurant;
    case 'Pizzarias':
      return Icons.local_pizza;
    case 'Lanchonetes':
      return Icons.lunch_dining;
    case 'Materiais de construção':
      return Icons.construction;
    case 'Eletrônicos':
      return Icons.devices;
    case 'Roupas':
      return Icons.checkroom;
    case 'Serviços':
      return Icons.miscellaneous_services;
    default:
      return Icons.local_offer;
  }
}

Color categoriaColor(String cat) {
  switch (cat) {
    case 'Mercados':
      return const Color(0xFF4CAF50);
    case 'Postos de combustível':
      return const Color(0xFFFF9800);
    case 'Farmácias':
      return const Color(0xFFF44336);
    case 'Padarias':
      return const Color(0xFFFF7043);
    case 'Restaurantes':
      return const Color(0xFF8D6E63);
    case 'Pizzarias':
      return const Color(0xFFE91E63);
    case 'Lanchonetes':
      return const Color(0xFFFF5722);
    case 'Materiais de construção':
      return const Color(0xFF607D8B);
    case 'Eletrônicos':
      return const Color(0xFF2196F3);
    case 'Roupas':
      return const Color(0xFF9C27B0);
    case 'Serviços':
      return const Color(0xFF00BCD4);
    default:
      return const Color(0xFF1565C0);
  }
}

// ── Página principal ──────────────────────────────────────────────────────────

class GpsEconomiaPage extends StatefulWidget {
  const GpsEconomiaPage({super.key});

  @override
  State<GpsEconomiaPage> createState() => _GpsEconomiaPageState();
}

class _GpsEconomiaPageState extends State<GpsEconomiaPage> {
  final _mapController = MapController();
  Position? _userPos;
  double _raioKm = 5;
  String _categoriaFiltro = 'Todas';
  bool _carregando = true;
  bool _seguirUsuario = true;
  StreamSubscription<Position>? _posSub;
  Stream<List<PromoModel>>? _promoStream;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final pos = await GpsEconomiaService.instance.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userPos = pos;
        _carregando = false;
      });
      if (pos != null) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
        _updateStream();
      }
    }

    _posSub = GpsEconomiaService.instance.positionStream().listen((pos) {
      if (!mounted) return;
      setState(() => _userPos = pos);
      if (_seguirUsuario) {
        _mapController.move(
            LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom);
      }
    });
  }

  void _updateStream() {
    if (_userPos == null) return;
    setState(() {
      _promoStream = GpsEconomiaService.instance.promocoesProximas(
        lat: _userPos!.latitude,
        lng: _userPos!.longitude,
        raioKm: _raioKm,
        categoria: _categoriaFiltro == 'Todas' ? null : _categoriaFiltro,
      );
    });
  }

  void _centerOnUser() {
    setState(() => _seguirUsuario = true);
    if (_userPos != null) {
      _mapController.move(
          LatLng(_userPos!.latitude, _userPos!.longitude), 14);
    }
  }

  void _mostrarDetalhe(PromoModel p) {
    GpsEconomiaService.instance.registrarAcesso(p.id, p.criadoPorUid);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PromoDetalheSheet(
        promo: p,
        onIrAteLa: () => _escolherApp(p),
      ),
    );
  }

  void _escolherApp(PromoModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Abrir rota com',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: _RotaBtn(
                label: 'Google Maps',
                icon: Icons.map_rounded,
                color: const Color(0xFF4285F4),
                onTap: () async {
                  Navigator.pop(context);
                  final url = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1'
                      '&destination=${p.lat},${p.lng}'
                      '&travelmode=driving');
                  await launchUrl(url,
                      mode: LaunchMode.externalApplication);
                },
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _RotaBtn(
                label: 'Waze',
                icon: Icons.navigation_rounded,
                color: const Color(0xFF05C8F7),
                onTap: () async {
                  Navigator.pop(context);
                  final url = Uri.parse(
                      'https://waze.com/ul?ll=${p.lat},${p.lng}&navigate=yes');
                  await launchUrl(url,
                      mode: LaunchMode.externalApplication);
                },
              )),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: Color(0xFF4CAF50)),
            SizedBox(height: 16),
            Text('Obtendo localização...',
                style: TextStyle(color: Colors.white70)),
          ]),
        ),
      );
    }

    if (_userPos == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.location_off, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              const Text('GPS desativado',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'Ative a localização do dispositivo para usar o GPS de Economia',
                  style: TextStyle(color: Colors.white60),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
                icon: const Icon(Icons.gps_fixed, color: Colors.white),
                label: const Text('Ativar GPS',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50)),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(children: [
        // ── Mapa ───────────────────────────────────────────
        StreamBuilder<List<PromoModel>>(
          stream: _promoStream,
          builder: (_, snap) {
            final promos = snap.data ?? [];
            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    LatLng(_userPos!.latitude, _userPos!.longitude),
                initialZoom: 14,
                onPositionChanged: (_, hasGesture) {
                  if (hasGesture && _seguirUsuario) {
                    setState(() => _seguirUsuario = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ia_financeiro',
                  maxNativeZoom: 19,
                ),
                CircleLayer(circles: [
                  CircleMarker(
                    point: LatLng(
                        _userPos!.latitude, _userPos!.longitude),
                    radius: _raioKm * 1000,
                    useRadiusInMeter: true,
                    color: const Color(0xFF4CAF50).withOpacity(0.07),
                    borderColor:
                        const Color(0xFF4CAF50).withOpacity(0.35),
                    borderStrokeWidth: 1.5,
                  ),
                ]),
                MarkerLayer(
                  markers: [
                    // Usuário
                    Marker(
                      point: LatLng(
                          _userPos!.latitude, _userPos!.longitude),
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black38, blurRadius: 8)
                          ],
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    // Promoções
                    ...promos.map((p) => Marker(
                          point: LatLng(p.lat, p.lng),
                          width: 52,
                          height: 64,
                          child: GestureDetector(
                            onTap: () => _mostrarDetalhe(p),
                            child: _PromoMarker(p),
                          ),
                        )),
                  ],
                ),
              ],
            );
          },
        ),

        // ── Barra superior ─────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628).withOpacity(0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8)
                  ],
                ),
                child: Row(children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  const Text('GPS de Economia',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const Spacer(),
                  StreamBuilder<List<PromoModel>>(
                    stream: _promoStream,
                    builder: (_, s) => _Badge(
                        '${s.data?.length ?? 0} promoções',
                        const Color(0xFF4CAF50)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const RankingGpsPage())),
                    child: const Icon(Icons.emoji_events,
                        color: Color(0xFFFFD700), size: 22),
                  ),
                ]),
              ),

              const SizedBox(height: 8),

              // Filtros
              Row(children: [
                // Raio
                _FilterBox(
                  child: DropdownButton<double>(
                    value: _raioKm,
                    dropdownColor: const Color(0xFF0A1628),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Color(0xFF4CAF50), size: 20),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 km')),
                      DropdownMenuItem(value: 5, child: Text('5 km')),
                      DropdownMenuItem(value: 10, child: Text('10 km')),
                      DropdownMenuItem(value: 20, child: Text('20 km')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _raioKm = v);
                        _updateStream();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Categoria
                Expanded(
                  child: _FilterBox(
                    child: DropdownButton<String>(
                      value: _categoriaFiltro,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0A1628),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF4CAF50), size: 20),
                      items: kCategorias
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _categoriaFiltro = v);
                          _updateStream();
                        }
                      },
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),

        // ── FABs ───────────────────────────────────────────
        Positioned(
          bottom: 24,
          right: 16,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FloatingActionButton.small(
              heroTag: 'center',
              backgroundColor: const Color(0xFF0A1628),
              elevation: 4,
              onPressed: _centerOnUser,
              child: Icon(
                _seguirUsuario
                    ? Icons.my_location
                    : Icons.location_searching,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'add',
              backgroundColor: const Color(0xFF4CAF50),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Publicar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CadastrarPromocaoPage(userPos: _userPos)),
                );
                if (ok == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Promoção publicada! +10 pontos'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Marcador no mapa ─────────────────────────────────────────────────────────

class _PromoMarker extends StatelessWidget {
  final PromoModel p;
  const _PromoMarker(this.p);

  @override
  Widget build(BuildContext context) {
    final cor = categoriaColor(p.categoria);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(color: cor.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)
          ],
        ),
        child: Icon(categoriaIcon(p.categoria), color: Colors.white, size: 20),
      ),
      CustomPaint(
        size: const Size(12, 8),
        painter: _TrianglePainter(cor),
      ),
    ]);
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Sheet de detalhe ─────────────────────────────────────────────────────────

class _PromoDetalheSheet extends StatefulWidget {
  final PromoModel promo;
  final VoidCallback onIrAteLa;

  const _PromoDetalheSheet({required this.promo, required this.onIrAteLa});

  @override
  State<_PromoDetalheSheet> createState() => _PromoDetalheSheetState();
}

class _PromoDetalheSheetState extends State<_PromoDetalheSheet> {
  bool _confirmou = false;
  bool _curtiu = false;
  bool _reportou = false;
  bool _registrouEconomia = false;

  PromoModel get p => widget.promo;

  String _trustLabel() {
    switch (p.trustLevel) {
      case 'verde':
        return '🟢 Confirmada por usuários';
      case 'amarelo':
        return '🟡 Poucas confirmações';
      default:
        return '🔴 Não verificada';
    }
  }

  Color _trustColor() {
    switch (p.trustLevel) {
      case 'verde':
        return const Color(0xFF4CAF50);
      case 'amarelo':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFFF44336);
    }
  }

  String _tempo() {
    final dur = p.tempoRestante;
    if (dur.isNegative) return 'Expirada';
    if (dur.inHours >= 1) return 'Expira em ${dur.inHours}h ${dur.inMinutes % 60}min';
    return 'Expira em ${dur.inMinutes}min';
  }

  String _distancia() {
    if (p.distanciaKm == null) return '';
    final d = p.distanciaKm!;
    return d < 1 ? '${(d * 1000).round()}m' : '${d.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.zero,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Foto
            if (p.fotoUrl != null)
              CachedNetworkImage(
                imageUrl: p.fotoUrl!,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    height: 190,
                    color: Colors.white10,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF4CAF50)))),
                errorWidget: (_, __, ___) =>
                    _FotoPlaceholder(p.categoria),
              )
            else
              _FotoPlaceholder(p.categoria),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoria + Trust
                    Row(children: [
                      _CatChip(p.categoria),
                      const Spacer(),
                      Text(_trustLabel(),
                          style: TextStyle(
                              color: _trustColor(), fontSize: 12)),
                    ]),

                    const SizedBox(height: 10),

                    // Nome
                    Text(p.nomeEstabelecimento,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),

                    Text(p.produto,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 15)),

                    const SizedBox(height: 12),

                    // Preço
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'R\$ ${p.valorPromo.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 30,
                                fontWeight: FontWeight.bold),
                          ),
                          if (p.valorOriginal != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              'R\$ ${p.valorOriginal!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough),
                            ),
                            if (p.percentualDesconto != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                child: Text(
                                    '-${p.percentualDesconto}%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ]),

                    if (p.economia != null)
                      Text(
                          'Você economiza R\$ ${p.economia!.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Color(0xFF66BB6A), fontSize: 13)),

                    const SizedBox(height: 12),

                    // Endereço + tempo + distância
                    _InfoRow(Icons.location_on, p.endereco),
                    const SizedBox(height: 4),
                    Row(children: [
                      _InfoRow(Icons.timer_outlined, _tempo(),
                          cor: p.tempoRestante.inHours < 6
                              ? const Color(0xFFFF9800)
                              : Colors.white60),
                      if (p.distanciaKm != null) ...[
                        const SizedBox(width: 16),
                        _InfoRow(Icons.near_me, _distancia()),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    _InfoRow(Icons.visibility,
                        '${p.acessos} visualizações'),

                    const SizedBox(height: 20),

                    // Botão Ir até lá
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: widget.onIrAteLa,
                        icon: const Icon(Icons.navigation_rounded,
                            color: Colors.white),
                        label: const Text('Ir até lá',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Registrar economia usada
                    if (p.economia != null && !_registrouEconomia)
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await GpsEconomiaService.instance
                                .registrarEconomia(
                                    p.economia!, p.categoria);
                            setState(() => _registrouEconomia = true);
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                    'Economia registrada no seu perfil!'),
                                backgroundColor: Color(0xFF4CAF50),
                              ));
                            }
                          },
                          icon: const Icon(Icons.savings_outlined,
                              color: Color(0xFF4CAF50)),
                          label: const Text('Registrar economia usada',
                              style: TextStyle(
                                  color: Color(0xFF4CAF50))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF4CAF50)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),

                    if (_registrouEconomia)
                      const Center(
                        child: Text('Economia registrada ✓',
                            style: TextStyle(
                                color: Color(0xFF4CAF50), fontSize: 13)),
                      ),

                    const SizedBox(height: 12),

                    // Ações sociais
                    Row(children: [
                      Expanded(
                          child: _AcaoBtn(
                        icon: Icons.check_circle_outline,
                        label: 'Confirmar\n(${p.confirmacoes})',
                        color: const Color(0xFF4CAF50),
                        active: _confirmou,
                        onTap: _confirmou
                            ? null
                            : () async {
                                await GpsEconomiaService.instance
                                    .confirmarPromocao(
                                        p.id, p.criadoPorUid);
                                setState(() => _confirmou = true);
                              },
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _AcaoBtn(
                        icon: Icons.thumb_up_outlined,
                        label: 'Curtir\n(${p.curtidas})',
                        color: const Color(0xFF2196F3),
                        active: _curtiu,
                        onTap: _curtiu
                            ? null
                            : () async {
                                await GpsEconomiaService.instance
                                    .curtirPromocao(p.id);
                                setState(() => _curtiu = true);
                              },
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _AcaoBtn(
                        icon: Icons.flag_outlined,
                        label: 'Reportar\n(${p.reportes})',
                        color: const Color(0xFFF44336),
                        active: _reportou,
                        onTap: _reportou
                            ? null
                            : () async {
                                await GpsEconomiaService.instance
                                    .reportarPromocao(p.id);
                                setState(() => _reportou = true);
                              },
                      )),
                    ]),

                    const SizedBox(height: 10),
                    Center(
                      child: Text('Publicado por ${p.criadoPorNome}',
                          style: const TextStyle(
                              color: Colors.white30, fontSize: 11)),
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ───────────────────────────────────────────────────────

class _FotoPlaceholder extends StatelessWidget {
  final String categoria;
  const _FotoPlaceholder(this.categoria);

  @override
  Widget build(BuildContext context) {
    final cor = categoriaColor(categoria);
    return Container(
      height: 110,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Center(
          child: Icon(categoriaIcon(categoria), color: cor, size: 48)),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String cat;
  const _CatChip(this.cat);

  @override
  Widget build(BuildContext context) {
    final cor = categoriaColor(cat);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: cor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20)),
      child: Text(cat,
          style: TextStyle(
              color: cor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? cor;
  const _InfoRow(this.icon, this.text, {this.cor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: Colors.white38, size: 14),
      const SizedBox(width: 4),
      Flexible(
          child: Text(text,
              style: TextStyle(
                  color: cor ?? Colors.white60, fontSize: 12))),
    ]);
  }
}

class _AcaoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback? onTap;
  const _AcaoBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.active,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? color.withOpacity(0.5) : Colors.white12),
        ),
        child: Column(children: [
          Icon(icon, color: active ? color : Colors.white38, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: active ? color : Colors.white38, fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _FilterBox extends StatelessWidget {
  final Widget child;
  const _FilterBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628).withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: child,
    );
  }
}

class _RotaBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RotaBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }
}
