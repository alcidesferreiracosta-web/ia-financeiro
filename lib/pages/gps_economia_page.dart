import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;
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

// ── Modelos auxiliares ────────────────────────────────────────────────────────

class _OverpassPlace {
  final String id;
  final String nome;
  final String categoria;
  final double lat;
  final double lng;

  _OverpassPlace({required this.id, required this.nome, required this.categoria, required this.lat, required this.lng});

  static String _mapCategoria(Map tags) {
    final amenity = (tags['amenity'] as String? ?? '').toLowerCase();
    final shop = (tags['shop'] as String? ?? '').toLowerCase();
    if (amenity == 'supermarket' || amenity == 'convenience' ||
        shop.contains('supermarket') || shop.contains('convenience') ||
        shop.contains('grocery') || shop.contains('greengrocer')) return 'Mercados';
    if (amenity == 'fuel') return 'Postos de combustível';
    if (amenity == 'pharmacy') return 'Farmácias';
    if (shop == 'bakery' || amenity == 'bakery') return 'Padarias';
    if (amenity == 'restaurant') return 'Restaurantes';
    if (amenity == 'fast_food') return 'Lanchonetes';
    if (amenity == 'cafe') return 'Lanchonetes';
    if (amenity == 'pizza') return 'Pizzarias';
    return 'Outros';
  }

  factory _OverpassPlace.fromJson(Map element) {
    final tags = element['tags'] as Map? ?? {};
    final nome = (tags['name'] as String?)?.trim() ??
        (tags['brand'] as String?)?.trim() ?? '';
    final lat = (element['lat'] as num).toDouble();
    final lng = (element['lon'] as num).toDouble();
    return _OverpassPlace(
      id: element['id'].toString(),
      nome: nome,
      categoria: _mapCategoria(tags),
      lat: lat,
      lng: lng,
    );
  }
}

class _SearchSuggestion {
  final String nome;
  final String subtitulo;
  final double lat;
  final double lng;
  _SearchSuggestion({required this.nome, required this.subtitulo, required this.lat, required this.lng});
}

// ── Estado principal ──────────────────────────────────────────────────────────

class _GpsEconomiaPageState extends State<GpsEconomiaPage> {
  final _mapController = MapController();
  final _buscaCtrl = TextEditingController();
  final _buscaFocus = FocusNode();
  Position? _userPos;
  double _raioKm = 5;
  String _categoriaFiltro = 'Todas';
  bool _carregando = true;
  bool _seguirUsuario = true;
  StreamSubscription<Position>? _posSub;
  Stream<List<PromoModel>>? _promoStream;
  _NavDestino? _tapDestino;
  bool _buscando = false;

  // Nearby places (Overpass API)
  List<_OverpassPlace> _nearbyPlaces = [];
  bool _loadingPlaces = false;
  LatLng? _lastFetchPos;

  // Autocomplete
  Timer? _debounceTimer;
  List<_SearchSuggestion> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _debounceTimer?.cancel();
    _buscaCtrl.dispose();
    _buscaFocus.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      if (!mounted) return;
      final aceito = await _mostrarDialogPermissao(false);
      if (!aceito) {
        if (mounted) setState(() => _carregando = false);
        return;
      }
    } else if (perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      final aceito = await _mostrarDialogPermissao(true);
      if (mounted) setState(() => _carregando = false);
      if (aceito) await Geolocator.openAppSettings();
      return;
    }

    final pos = await GpsEconomiaService.instance.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userPos = pos;
        _carregando = false;
      });
      if (pos != null) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
        _updateStream();
        _fetchNearbyPlaces();
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

  Future<bool> _mostrarDialogPermissao(bool permanente) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF0A1628),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(children: const [
              Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 28),
              SizedBox(width: 10),
              Text('Precisamos da sua localização',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'O GPS da Economia usa sua localização para:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _PermissaoItem(
                    Icons.map_rounded, 'Mostrar promoções perto de você'),
                _PermissaoItem(
                    Icons.navigation_rounded, 'Calcular rotas até as ofertas'),
                _PermissaoItem(
                    Icons.add_location_alt, 'Marcar onde estão as promoções'),
                if (permanente) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.orange.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'Permissão bloqueada. Você será redirecionado para as configurações do app para habilitá-la.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Agora não',
                    style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  permanente ? 'Abrir configurações' : 'Permitir localização',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
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

  // ── A) Busca locais próximos via Overpass API ──────────────────────────────

  Future<void> _fetchNearbyPlaces() async {
    if (_userPos == null || _loadingPlaces) return;
    final pos = LatLng(_userPos!.latitude, _userPos!.longitude);
    if (_lastFetchPos != null) {
      final metros = Geolocator.distanceBetween(
          pos.latitude, pos.longitude,
          _lastFetchPos!.latitude, _lastFetchPos!.longitude);
      if (metros < 500) return;
    }
    setState(() => _loadingPlaces = true);
    _lastFetchPos = pos;
    try {
      final raioM = (_raioKm * 1000).round();
      final lat = _userPos!.latitude;
      final lng = _userPos!.longitude;
      final query =
          '[out:json][timeout:15];'
          '('
          'node["amenity"~"supermarket|fuel|pharmacy|restaurant|fast_food|cafe|bakery"](around:$raioM,$lat,$lng);'
          'node["shop"~"supermarket|convenience|greengrocer|bakery|butcher|grocery"](around:$raioM,$lat,$lng);'
          ');'
          'out body;';
      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final resp = await http.post(url, body: {'data': query}).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map;
        final elements = (data['elements'] as List? ?? []);
        final places = elements
            .map((e) => _OverpassPlace.fromJson(e as Map))
            .where((p) => p.nome.isNotEmpty)
            .toList();
        setState(() => _nearbyPlaces = places);
      }
    } catch (_) {
      // silencioso — não interrompe o usuário
    } finally {
      if (mounted) setState(() => _loadingPlaces = false);
    }
  }

  // ── C) Autocomplete de busca ───────────────────────────────────────────────

  void _onBuscaChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 3) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () => _buscarSugestoes(query));
  }

  Future<void> _buscarSugestoes(String query) async {
    if (!mounted) return;
    try {
      final lat = _userPos?.latitude ?? -15.78;
      final lng = _userPos?.longitude ?? -47.93;
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json&limit=5&accept-language=pt-BR&countrycodes=BR'
          '&viewbox=${lng - 0.5},${lat + 0.5},${lng + 0.5},${lat - 0.5}'
          '&bounded=1');
      final resp = await http.get(url, headers: {
        'User-Agent': 'IAFinanceiro/1.0 (alcidesferreira.costa@hotmail.com)'
      }).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        final sugs = list.map((item) {
          final parts = (item['display_name'] as String).split(',');
          return _SearchSuggestion(
            nome: parts.first.trim(),
            subtitulo: parts.skip(1).take(2).join(',').trim(),
            lat: double.parse(item['lat'].toString()),
            lng: double.parse(item['lon'].toString()),
          );
        }).toList();
        setState(() { _suggestions = sugs; _showSuggestions = sugs.isNotEmpty; });
      }
    } catch (_) {}
  }

  void _selecionarSugestao(_SearchSuggestion s) {
    _buscaCtrl.text = s.nome;
    _buscaFocus.unfocus();
    setState(() { _showSuggestions = false; _suggestions = []; });
    final dest = _NavDestino(nome: s.nome, endereco: s.subtitulo, lat: s.lat, lng: s.lng);
    _mapController.move(LatLng(s.lat, s.lng), 16);
    setState(() => _tapDestino = dest);
    _mostrarTapSheet(dest);
  }

  void _centerOnUser() {
    setState(() => _seguirUsuario = true);
    if (_userPos != null) {
      _mapController.move(
          LatLng(_userPos!.latitude, _userPos!.longitude), 15);
    }
  }

  void _mostrarDetalhe(PromoModel p, List<PromoModel> todasPromos) {
    GpsEconomiaService.instance.registrarAcesso(p.id, p.criadoPorUid);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PromoDetalheSheet(
        promo: p,
        outrasPromos: todasPromos,
        onIrAteLa: () => _escolherApp(_NavDestino.fromPromo(p)),
      ),
    );
  }

  void _escolherApp(_NavDestino destino, {bool fecharSheet = true}) {
    if (fecharSheet) Navigator.pop(context);
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
            const SizedBox(height: 10),
            Text(destino.nome,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (destino.endereco.isNotEmpty)
              Text(destino.endereco,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            const Text('Como deseja ir até lá?',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 14),
            // GPS no próprio app — botão destaque
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => _NavegacaoPage(destino: destino)),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF1565C0).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation_rounded,
                        color: Colors.white, size: 26),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Navegar no App',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text('GPS com rota calculada',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                      '&destination=${destino.lat},${destino.lng}'
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
                      'https://waze.com/ul?ll=${destino.lat},${destino.lng}&navigate=yes');
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

  // Toque no mapa: geocodificação reversa + mostrar destino
  Future<void> _mapaTap(TapPosition _, LatLng latLng) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=${latLng.latitude}&lon=${latLng.longitude}'
          '&format=json&accept-language=pt-BR');
      final resp = await http.get(url, headers: {
        'User-Agent': 'IAFinanceiro/1.0 (alcidesferreira.costa@hotmail.com)'
      }).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      String nome = 'Local selecionado';
      String endereco = '';
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        nome = data['name'] as String? ??
            data['display_name']?.toString().split(',').first ??
            'Local selecionado';
        endereco = data['display_name'] as String? ?? '';
      }
      setState(() => _tapDestino = _NavDestino(
            nome: nome,
            endereco: endereco,
            lat: latLng.latitude,
            lng: latLng.longitude,
          ));
      _mostrarTapSheet(_tapDestino!);
    } catch (_) {
      if (!mounted) return;
      setState(() => _tapDestino = _NavDestino(
            nome: 'Local selecionado',
            endereco: '',
            lat: latLng.latitude,
            lng: latLng.longitude,
          ));
      _mostrarTapSheet(_tapDestino!);
    }
  }

  void _mostrarTapSheet(_NavDestino d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.location_pin, color: Color(0xFF4CAF50), size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.nome,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              if (d.endereco.isNotEmpty)
                Text(d.endereco,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
            ])),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _escolherApp(d, fecharSheet: false);
              },
              icon: const Icon(Icons.navigation_rounded, color: Colors.white),
              label: const Text('Ir até lá',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── D) Publicar promoção neste local ──────────────────
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CadastrarPromocaoPage(
                      userPos: _userPos,
                      nomeEstabelecimento: d.nome == 'Local selecionado' ? null : d.nome,
                      localInicial: LatLng(d.lat, d.lng),
                      categoriaInicial: d.categoria == 'Outros' ? null : d.categoria,
                    ),
                  ),
                );
                if (ok == true && mounted) {
                  _updateStream();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Promoção publicada! +10 pontos'), backgroundColor: Color(0xFF00E676)),
                  );
                }
              },
              icon: const Icon(Icons.add_location_alt, color: Color(0xFF4CAF50)),
              label: const Text('Publicar promoção aqui',
                  style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4CAF50)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ]),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _tapDestino = null);
    });
  }

  // Busca por endereço via Nominatim
  Future<void> _pesquisarEndereco(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _buscando = true);
    FocusScope.of(context).unfocus();
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json&limit=1&accept-language=pt-BR&countrycodes=BR');
      final resp = await http.get(url, headers: {
        'User-Agent': 'IAFinanceiro/1.0 (alcidesferreira.costa@hotmail.com)'
      }).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        if (list.isNotEmpty) {
          final item = list[0] as Map;
          final lat = double.parse(item['lat'].toString());
          final lng = double.parse(item['lon'].toString());
          final nome = item['display_name'].toString().split(',').first;
          final endereco = item['display_name'] as String? ?? '';
          final dest = _NavDestino(
              nome: nome, endereco: endereco, lat: lat, lng: lng);
          _mapController.move(LatLng(lat, lng), 16);
          setState(() {
            _tapDestino = dest;
            _buscando = false;
          });
          _mostrarTapSheet(dest);
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Endereço não encontrado'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao buscar endereço'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
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
                  'Ative a localização do dispositivo para usar o GPS da Economia',
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
                initialZoom: 15,
                onTap: _mapaTap,
                onPositionChanged: (_, hasGesture) {
                  if (hasGesture && _seguirUsuario) {
                    setState(() => _seguirUsuario = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                  userAgentPackageName: 'com.mycompany.iafinanceiro',
                  maxNativeZoom: 18,
                  tileSize: 512,
                  zoomOffset: -1,
                ),
                CircleLayer(circles: [
                  CircleMarker(
                    point: LatLng(
                        _userPos!.latitude, _userPos!.longitude),
                    radius: _raioKm * 1000,
                    useRadiusInMeter: true,
                    color: const Color(0xFF2979FF).withOpacity(0.08),
                    borderColor:
                        const Color(0xFF2979FF).withOpacity(0.4),
                    borderStrokeWidth: 1.8,
                  ),
                ]),
                // ── A) Marcadores Overpass (locais próximos) ──────────
                MarkerLayer(
                  markers: _nearbyPlaces
                      .where((pl) =>
                          _categoriaFiltro == 'Todas' ||
                          pl.categoria == _categoriaFiltro)
                      .map((pl) => Marker(
                            point: LatLng(pl.lat, pl.lng),
                            width: 72,
                            height: 56,
                            child: GestureDetector(
                              onTap: () {
                                final dest = _NavDestino(
                                  nome: pl.nome,
                                  endereco: '',
                                  lat: pl.lat,
                                  lng: pl.lng,
                                  categoria: pl.categoria,
                                );
                                setState(() => _tapDestino = dest);
                                _mostrarTapSheet(dest);
                              },
                              child: _OverpassMarker(pl),
                            ),
                          ))
                      .toList(),
                ),
                MarkerLayer(
                  markers: [
                    // Usuário — marcador pulsante
                    Marker(
                      point: LatLng(
                          _userPos!.latitude, _userPos!.longitude),
                      width: 56,
                      height: 56,
                      child: const _UserMarker(),
                    ),
                    // Promoções
                    ...promos.map((p) => Marker(
                          point: LatLng(p.lat, p.lng),
                          width: 90,
                          height: 100,
                          child: GestureDetector(
                            onTap: () => _mostrarDetalhe(p, promos),
                            child: _PromoMarker(p),
                          ),
                        )),
                    // Destino selecionado pelo toque
                    if (_tapDestino != null)
                      Marker(
                        point: LatLng(_tapDestino!.lat, _tapDestino!.lng),
                        width: 40,
                        height: 48,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                            ),
                            child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
                          ),
                          CustomPaint(
                              size: const Size(10, 6),
                              painter: _TrianglePainter(const Color(0xFF1565C0))),
                        ]),
                      ),
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
              // Header — identidade GPS da Economia
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2137), Color(0xFF0D2550)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFF2979FF).withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2979FF).withOpacity(0.12),
                      blurRadius: 18,
                      spreadRadius: -2,
                    ),
                    const BoxShadow(color: Colors.black54, blurRadius: 12),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2979FF).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF2979FF).withOpacity(0.5),
                          width: 1.5),
                    ),
                    child: const Icon(Icons.savings_rounded,
                        color: Color(0xFF00E676), size: 19),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('GPS da Economia',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.3)),
                      Text('Promoções perto de você',
                          style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  StreamBuilder<List<PromoModel>>(
                    stream: _promoStream,
                    builder: (_, s) {
                      final count = s.data?.length ?? 0;
                      return _Badge(
                          '$count promos', const Color(0xFF2979FF));
                    },
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const RankingGpsPage())),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.emoji_events,
                          color: Color(0xFFFFD700), size: 19),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 8),

              // ── C) Busca com autocomplete ──────────────────────────
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1628).withOpacity(0.96),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: Colors.white38, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _buscaCtrl,
                        focusNode: _buscaFocus,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        textInputAction: TextInputAction.search,
                        onChanged: _onBuscaChanged,
                        onSubmitted: (q) {
                          setState(() { _showSuggestions = false; });
                          _pesquisarEndereco(q);
                        },
                        decoration: const InputDecoration(
                          hintText: 'Buscar local, estabelecimento...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_buscando)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Color(0xFF4CAF50), strokeWidth: 2)),
                      )
                    else if (_buscaCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                        onPressed: () {
                          _buscaCtrl.clear();
                          setState(() { _suggestions = []; _showSuggestions = false; });
                        },
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Color(0xFF4CAF50), size: 20),
                        onPressed: () => _pesquisarEndereco(_buscaCtrl.text),
                      ),
                  ]),
                ),
                // Dropdown de sugestões
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F36),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                    ),
                    child: Column(
                      children: _suggestions.map((s) => InkWell(
                        onTap: () => _selecionarSugestao(s),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(children: [
                            const Icon(Icons.place, color: Color(0xFF4CAF50), size: 16),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.nome, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              if (s.subtitulo.isNotEmpty)
                                Text(s.subtitulo, style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                          ]),
                        ),
                      )).toList(),
                    ),
                  ),
              ]),

              const SizedBox(height: 8),

              // Filtros — raio + chips de categoria (B)
              Row(children: [
                _FilterBox(
                  child: DropdownButton<double>(
                    value: _raioKm,
                    dropdownColor: const Color(0xFF0A1628),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4CAF50), size: 20),
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
                        _lastFetchPos = null; // força rebusca Overpass
                        _fetchNearbyPlaces();
                      }
                    },
                  ),
                ),
                if (_loadingPlaces) ...[
                  const SizedBox(width: 10),
                  const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(color: Color(0xFF4CAF50), strokeWidth: 1.5)),
                ],
              ]),
              const SizedBox(height: 6),
              // ── B) Chips de categoria ──────────────────────────────
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: kCategorias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final cat = kCategorias[i];
                    final isActive = _categoriaFiltro == cat;
                    final cor = cat == 'Todas'
                        ? const Color(0xFF4CAF50)
                        : categoriaColor(cat);
                    return GestureDetector(
                      onTap: () {
                        setState(() => _categoriaFiltro = cat);
                        _updateStream();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? cor.withOpacity(0.22)
                              : const Color(0xFF0A1628).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isActive ? cor : Colors.white12, width: 1.2),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (cat != 'Todas') ...[
                            Icon(categoriaIcon(cat),
                                color: isActive ? cor : Colors.white38, size: 12),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            cat == 'Todas' ? '🗺 Todas' : cat.split(' ').first,
                            style: TextStyle(
                              color: isActive ? cor : Colors.white54,
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),

        // ── Barra de economia disponível ────────────────────
        Positioned(
          bottom: 104,
          left: 16,
          child: StreamBuilder<List<PromoModel>>(
            stream: _promoStream,
            builder: (_, snap) {
              final promos = snap.data ?? [];
              if (promos.isEmpty) return const SizedBox.shrink();
              final totalEco = promos.fold(0.0, (s, p) {
                if (p.valorOriginal == null) return s;
                final eco = p.valorOriginal! - p.valorPromo;
                return s + (eco > 0 ? eco : 0);
              });
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2550), Color(0xFF0D2137)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: const Color(0xFF2979FF).withOpacity(0.45)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2979FF).withOpacity(0.2),
                      blurRadius: 14,
                    ),
                    const BoxShadow(color: Colors.black45, blurRadius: 6),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_offer_rounded,
                      color: Color(0xFF00E676), size: 14),
                  const SizedBox(width: 6),
                  Text('${promos.length} promos',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  if (totalEco > 0) ...[
                    const SizedBox(width: 6),
                    Container(width: 1, height: 12, color: Colors.white24),
                    const SizedBox(width: 6),
                    Text(
                      'até R\$ ${totalEco.toStringAsFixed(0)} ec.',
                      style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ]),
              );
            },
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
                  _updateStream();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Promoção publicada! +10 pontos'),
                      backgroundColor: Color(0xFF00E676),
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

// ── Marcador do usuário — pulsante ──────────────────────────────────────────

class _UserMarker extends StatefulWidget {
  const _UserMarker();
  @override
  State<_UserMarker> createState() => _UserMarkerState();
}

class _UserMarkerState extends State<_UserMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => SizedBox(
        width: 56,
        height: 56,
        child: Stack(alignment: Alignment.center, children: [
          // Anel externo pulsante
          Transform.scale(
            scale: 0.4 + _pulse.value * 1.0,
            child: Opacity(
              opacity: (1.0 - _pulse.value).clamp(0.0, 1.0),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x402979FF),
                ),
              ),
            ),
          ),
          // Anel médio fixo
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2979FF).withOpacity(0.12),
              border: Border.all(
                  color: const Color(0xFF2979FF).withOpacity(0.4),
                  width: 1),
            ),
          ),
          // Ponto central
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2979FF).withOpacity(0.7),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ]),
      ),
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
    final nome = p.nomeEstabelecimento.length > 14
        ? '${p.nomeEstabelecimento.substring(0, 13)}…'
        : p.nomeEstabelecimento;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Ícone da categoria
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: cor.withOpacity(0.55), blurRadius: 8, spreadRadius: 1)
          ],
        ),
        child: Icon(categoriaIcon(p.categoria), color: Colors.white, size: 18),
      ),
      // Triângulo apontando para o local
      CustomPaint(
        size: const Size(10, 6),
        painter: _TrianglePainter(cor),
      ),
      // Label: nome + preço
      Container(
        constraints: const BoxConstraints(maxWidth: 86),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(7),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            nome,
            style: const TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'R\$ ${p.valorPromo.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 8,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    ]);
  }
}

// ── Marcador de local Overpass (sem promoção) ─────────────────────────────────

class _OverpassMarker extends StatelessWidget {
  final _OverpassPlace place;
  const _OverpassMarker(this.place);

  @override
  Widget build(BuildContext context) {
    final cor = categoriaColor(place.categoria);
    final nome = place.nome.length > 12
        ? '${place.nome.substring(0, 11)}…'
        : place.nome;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: cor.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(color: cor.withOpacity(0.7), width: 1.5),
        ),
        child: Icon(categoriaIcon(place.categoria), color: cor, size: 13),
      ),
      Container(
        constraints: const BoxConstraints(maxWidth: 70),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628).withOpacity(0.82),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: cor.withOpacity(0.35)),
        ),
        child: Text(
          nome,
          style: TextStyle(color: cor, fontSize: 8, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
  final List<PromoModel> outrasPromos;

  const _PromoDetalheSheet({
    required this.promo,
    required this.onIrAteLa,
    this.outrasPromos = const [],
  });

  @override
  State<_PromoDetalheSheet> createState() => _PromoDetalheSheetState();
}

class _PromoDetalheSheetState extends State<_PromoDetalheSheet> {
  bool _confirmou = false;
  bool _curtiu = false;
  bool _reportou = false;
  bool _registrouEconomia = false;

  PromoModel get p => widget.promo;

  Widget _buildMediaRegional() {
    final mesmaCategoria = widget.outrasPromos
        .where((x) => x.categoria == p.categoria && x.id != p.id)
        .toList();
    if (mesmaCategoria.isEmpty) return const SizedBox.shrink();
    final media = mesmaCategoria.fold(0.0, (s, x) => s + x.valorPromo) /
        mesmaCategoria.length;
    final diff = media - p.valorPromo;
    if (diff <= 0) return const SizedBox.shrink();
    final pct = (diff / media * 100).round();
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.trending_down, color: Color(0xFF4CAF50), size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$pct% abaixo da média da região (R\$ ${media.toStringAsFixed(2).replaceAll('.', ',')})',
            style: const TextStyle(
                color: Color(0xFF66BB6A),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

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

                    _buildMediaRegional(),

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

class _PermissaoItem extends StatelessWidget {
  final IconData icon;
  final String texto;
  const _PermissaoItem(this.icon, this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 18),
        const SizedBox(width: 8),
        Flexible(
            child: Text(texto,
                style: const TextStyle(color: Colors.white70, fontSize: 13))),
      ]),
    );
  }
}

// ── Destino genérico de navegação ────────────────────────────────────────────

class _NavDestino {
  final String nome;
  final String endereco;
  final double lat;
  final double lng;
  final String categoria;

  const _NavDestino({
    required this.nome,
    required this.endereco,
    required this.lat,
    required this.lng,
    this.categoria = 'Outros',
  });

  factory _NavDestino.fromPromo(PromoModel p) => _NavDestino(
        nome: p.nomeEstabelecimento,
        endereco: p.endereco,
        lat: p.lat,
        lng: p.lng,
        categoria: p.categoria,
      );
}

// ── Página de Navegação GPS ──────────────────────────────────────────────────

class _NavegacaoPage extends StatefulWidget {
  final _NavDestino destino;
  const _NavegacaoPage({required this.destino});

  @override
  State<_NavegacaoPage> createState() => _NavegacaoPageState();
}

class _NavegacaoPageState extends State<_NavegacaoPage> {
  final _mapController = MapController();
  Position? _userPos;
  List<LatLng> _rotaPontos = [];
  double? _distanciaKm;
  int? _duracaoMin;
  bool _carregando = true;
  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _iniciar() async {
    final pos = await GpsEconomiaService.instance.getCurrentPosition();
    if (!mounted) return;
    setState(() => _userPos = pos);
    if (pos != null) {
      await _calcularRota(pos);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
    } else {
      setState(() => _carregando = false);
    }

    _posSub = GpsEconomiaService.instance.positionStream().listen((pos) {
      if (!mounted) return;
      setState(() => _userPos = pos);
    });
  }

  Future<void> _calcularRota(Position origem) async {
    if (!mounted) return;
    setState(() => _carregando = true);
    try {
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${origem.longitude},${origem.latitude};'
          '${widget.destino.lng},${widget.destino.lat}'
          '?overview=full&geometries=geojson');
      final resp =
          await http.get(url).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['code'] == 'Ok') {
          final route = data['routes'][0];
          final coords =
              (route['geometry']['coordinates'] as List)
                  .map((c) => LatLng(
                      (c[1] as num).toDouble(), (c[0] as num).toDouble()))
                  .toList();
          final distM = (route['distance'] as num).toDouble();
          final durS = (route['duration'] as num).toDouble();
          if (mounted) {
            setState(() {
              _rotaPontos = coords;
              _distanciaKm = distM / 1000;
              _duracaoMin = (durS / 60).round();
              _carregando = false;
            });
            if (coords.length >= 2) {
              final bounds = LatLngBounds.fromPoints(coords);
              _mapController.fitCamera(
                CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.fromLTRB(40, 100, 40, 160)),
              );
            }
          }
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  String _formatDist() {
    if (_distanciaKm == null) return '';
    return _distanciaKm! < 1
        ? '${(_distanciaKm! * 1000).round()} m'
        : '${_distanciaKm!.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destino;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(children: [
        // ── Mapa ─────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(dest.lat, dest.lng),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
              userAgentPackageName: 'com.mycompany.iafinanceiro',
              maxNativeZoom: 18,
              tileSize: 512,
              zoomOffset: -1,
            ),
            if (_rotaPontos.isNotEmpty)
              PolylineLayer(polylines: [
                Polyline(
                  points: _rotaPontos,
                  strokeWidth: 7,
                  color: const Color(0xFF00B8FF),
                  borderStrokeWidth: 2.5,
                  borderColor: Colors.white.withOpacity(0.2),
                ),
              ]),
            MarkerLayer(markers: [
              // Destino
              Marker(
                point: LatLng(dest.lat, dest.lng),
                width: 52,
                height: 64,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: categoriaColor(dest.categoria),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                                color: categoriaColor(dest.categoria)
                                    .withOpacity(0.5),
                                blurRadius: 8)
                          ],
                        ),
                        child: Icon(categoriaIcon(dest.categoria),
                            color: Colors.white, size: 20),
                      ),
                      CustomPaint(
                        size: const Size(12, 8),
                        painter: _TrianglePainter(
                            categoriaColor(dest.categoria)),
                      ),
                    ]),
              ),
              // Usuário — pulsante
              if (_userPos != null)
                Marker(
                  point:
                      LatLng(_userPos!.latitude, _userPos!.longitude),
                  width: 56,
                  height: 56,
                  child: const _UserMarker(),
                ),
            ]),
          ],
        ),

        // ── Header ───────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF0A1628).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF1565C0)
                            .withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(dest.nome,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(dest.endereco,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (_distanciaKm != null)
                        Text(
                          '${_formatDist()} · ~${_duracaoMin} min de carro',
                          style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        )
                      else if (_carregando)
                        const Text('Calculando rota...',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),

        // ── Barra inferior ────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                MediaQuery.of(context).padding.bottom + 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0A1628),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _userPos == null || _carregando
                      ? null
                      : () => _calcularRota(_userPos!),
                  icon: _carregando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                      _carregando ? 'Calculando...' : 'Recalcular',
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1'
                        '&destination=${dest.lat},${dest.lng}'
                        '&travelmode=driving');
                    await launchUrl(url,
                        mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new,
                      color: Colors.white),
                  label: const Text('Abrir Maps',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ]),
          ),
        ),

        // Loading overlay
        if (_carregando && _rotaPontos.isEmpty)
          Container(
            color: Colors.black38,
            child: const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Color(0xFF4CAF50)),
                SizedBox(height: 12),
                Text('Calculando rota...',
                    style: TextStyle(
                        color: Colors.white, fontSize: 15)),
              ]),
            ),
          ),
      ]),
    );
  }
}
