import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/promocao_model.dart';
import '../services/gps_economia_service.dart';
import 'gps_economia_page.dart' show categoriaColor, categoriaIcon;

class CadastrarPromocaoPage extends StatefulWidget {
  final Position? userPos;
  const CadastrarPromocaoPage({super.key, this.userPos});

  @override
  State<CadastrarPromocaoPage> createState() =>
      _CadastrarPromocaoPageState();
}

class _CadastrarPromocaoPageState extends State<CadastrarPromocaoPage> {
  final _form = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _produtoCtrl = TextEditingController();
  final _valorPromoCtrl = TextEditingController();
  final _valorOrigCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();

  String _categoria = 'Mercados';
  int _duracaoHoras = 72;
  File? _foto;
  LatLng? _localSelecionado;
  bool _salvando = false;
  bool _escolhendoLocal = false;

  @override
  void initState() {
    super.initState();
    if (widget.userPos != null) {
      _localSelecionado =
          LatLng(widget.userPos!.latitude, widget.userPos!.longitude);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _produtoCtrl.dispose();
    _valorPromoCtrl.dispose();
    _valorOrigCtrl.dispose();
    _enderecoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0A1628),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.camera_alt, color: Colors.white),
          title: const Text('Câmera', style: TextStyle(color: Colors.white)),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library, color: Colors.white),
          title: const Text('Galeria', style: TextStyle(color: Colors.white)),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
        const SizedBox(height: 8),
      ]),
    );
    if (source == null) return;
    final xfile = await picker.pickImage(source: source, imageQuality: 80);
    if (xfile != null && mounted) {
      setState(() => _foto = File(xfile.path));
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_localSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecione o local no mapa'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _salvando = true);
    try {
      await GpsEconomiaService.instance.criarPromocao(
        nomeEstabelecimento: _nomeCtrl.text.trim(),
        categoria: _categoria,
        produto: _produtoCtrl.text.trim(),
        valorPromo: double.parse(_valorPromoCtrl.text.replaceAll(',', '.')),
        valorOriginal: _valorOrigCtrl.text.isNotEmpty
            ? double.parse(_valorOrigCtrl.text.replaceAll(',', '.'))
            : null,
        lat: _localSelecionado!.latitude,
        lng: _localSelecionado!.longitude,
        endereco: _enderecoCtrl.text.trim(),
        duracaoHoras: _duracaoHoras,
        foto: _foto,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_escolhendoLocal) {
      return _MapaPicker(
        initialPos: _localSelecionado ??
            LatLng(widget.userPos?.latitude ?? -15.7801,
                widget.userPos?.longitude ?? -47.9292),
        onConfirm: (pos) {
          setState(() {
            _localSelecionado = pos;
            _escolhendoLocal = false;
          });
        },
        onCancel: () => setState(() => _escolhendoLocal = false),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        title: const Text('Nova Promoção'),
        elevation: 0,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Foto
            GestureDetector(
              onTap: _pickFoto,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: _foto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_foto!, fit: BoxFit.cover,
                            width: double.infinity),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              color: Colors.white38, size: 40),
                          SizedBox(height: 8),
                          Text('Adicionar foto',
                              style: TextStyle(color: Colors.white38)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            _Campo(
              ctrl: _nomeCtrl,
              label: 'Nome do estabelecimento',
              icon: Icons.store,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo obrigatório' : null,
            ),

            const SizedBox(height: 12),

            // Categoria
            _Label('Categoria'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButton<String>(
                value: _categoria,
                isExpanded: true,
                dropdownColor: const Color(0xFF0A1628),
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                items: kCategorias
                    .where((c) => c != 'Todas')
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(children: [
                            Icon(categoriaIcon(c),
                                color: categoriaColor(c), size: 18),
                            const SizedBox(width: 8),
                            Text(c),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _categoria = v);
                },
              ),
            ),

            const SizedBox(height: 12),

            _Campo(
              ctrl: _produtoCtrl,
              label: 'Produto ou serviço',
              icon: Icons.inventory_2_outlined,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo obrigatório' : null,
            ),

            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                  child: _Campo(
                ctrl: _valorPromoCtrl,
                label: 'Valor promocional (R\$)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _Campo(
                ctrl: _valorOrigCtrl,
                label: 'Valor original (opcional)',
                icon: Icons.money_off,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Inválido';
                  }
                  return null;
                },
              )),
            ]),

            const SizedBox(height: 12),

            _Campo(
              ctrl: _enderecoCtrl,
              label: 'Endereço (rua, número, bairro)',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo obrigatório' : null,
            ),

            const SizedBox(height: 16),

            // Duração
            _Label('Duração da promoção'),
            const SizedBox(height: 8),
            Row(children: [
              _DuracaoChip(24, _duracaoHoras,
                  onTap: () => setState(() => _duracaoHoras = 24)),
              const SizedBox(width: 8),
              _DuracaoChip(48, _duracaoHoras,
                  onTap: () => setState(() => _duracaoHoras = 48)),
              const SizedBox(width: 8),
              _DuracaoChip(72, _duracaoHoras,
                  onTap: () => setState(() => _duracaoHoras = 72)),
            ]),

            const SizedBox(height: 16),

            // Local no mapa
            _Label('Local no mapa (toque para ajustar)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _escolhendoLocal = true),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _localSelecionado != null
                        ? const Color(0xFF4CAF50).withOpacity(0.6)
                        : Colors.white24,
                  ),
                  color: Colors.white.withOpacity(0.03),
                ),
                child: _localSelecionado != null
                    ? Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: IgnorePointer(
                            child: FlutterMap(
                              options: MapOptions(
                                  initialCenter: _localSelecionado!,
                                  initialZoom: 15),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.ia_financeiro',
                                ),
                                MarkerLayer(markers: [
                                  Marker(
                                    point: _localSelecionado!,
                                    width: 36,
                                    height: 36,
                                    child: Icon(Icons.location_on,
                                        color: const Color(0xFF4CAF50),
                                        size: 36),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20)),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.edit_location_alt,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Ajustar',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ]),
                          ),
                        ),
                      ])
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_location_alt,
                              color: Colors.white38, size: 40),
                          SizedBox(height: 8),
                          Text('Toque para selecionar no mapa',
                              style: TextStyle(color: Colors.white38)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Botão salvar
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Publicar Promoção +10 pts',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Mapa picker ──────────────────────────────────────────────────────────────

class _MapaPicker extends StatefulWidget {
  final LatLng initialPos;
  final ValueChanged<LatLng> onConfirm;
  final VoidCallback onCancel;

  const _MapaPicker(
      {required this.initialPos,
      required this.onConfirm,
      required this.onCancel});

  @override
  State<_MapaPicker> createState() => _MapaPickerState();
}

class _MapaPickerState extends State<_MapaPicker> {
  late LatLng _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        title: const Text('Selecione o local'),
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel),
        actions: [
          TextButton(
            onPressed: () => widget.onConfirm(_selected),
            child: const Text('Confirmar',
                style: TextStyle(
                    color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _selected,
            initialZoom: 16,
            onTap: (_, point) => setState(() => _selected = point),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ia_financeiro',
            ),
            MarkerLayer(markers: [
              Marker(
                point: _selected,
                width: 48,
                height: 56,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.location_on,
                          color: Color(0xFF4CAF50), size: 48),
                    ]),
              ),
            ]),
          ],
        ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628).withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Toque no mapa para marcar o local exato da promoção',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Widgets de formulário ────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13));
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Campo(
      {required this.ctrl,
      required this.label,
      required this.icon,
      this.keyboardType,
      this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF4CAF50))),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }
}

class _DuracaoChip extends StatelessWidget {
  final int horas;
  final int selected;
  final VoidCallback onTap;

  const _DuracaoChip(this.horas, this.selected, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = horas == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4CAF50).withOpacity(0.2)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : Colors.white24),
          ),
          child: Column(children: [
            Text('${horas}h',
                style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(
                horas == 24
                    ? '1 dia'
                    : horas == 48
                        ? '2 dias'
                        : '3 dias',
                style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : Colors.white38,
                    fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}
