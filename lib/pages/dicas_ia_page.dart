import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/subscription_service.dart';
import 'paywall_page.dart';

class DicasIAPage extends StatefulWidget {
  const DicasIAPage({super.key});
  @override
  State<DicasIAPage> createState() => _DicasIAPageState();
}

class _DicasIAPageState extends State<DicasIAPage> {
  bool _loading = true;
  String? _erro;
  double _ganhos = 0, _gastos = 0, _saldo = 0;
  String _resumo = '';
  List<Map<String, dynamic>> _dicas = [];

  @override
  void initState() {
    super.initState();
    _analisar();
  }

  Future<void> _analisar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final fn = FirebaseFunctions.instance.httpsCallable(
        'dicasFinanceiras',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await fn.call({'uid': uid});
      final data = Map<String, dynamic>.from(result.data as Map);

      final dicas = (data['dicas'] as List).map((d) {
        final m = Map<String, dynamic>.from(d as Map);
        return {
          'titulo': m['titulo'] ?? '',
          'descricao': m['descricao'] ?? '',
          'tipo': m['tipo'] ?? 'dica',
          'prioridade': m['prioridade'] ?? 'media',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _ganhos = (data['ganhos'] as num?)?.toDouble() ?? 0;
          _gastos = (data['gastos'] as num?)?.toDouble() ?? 0;
          _saldo = (data['saldo'] as num?)?.toDouble() ?? 0;
          _resumo = data['resumo'] as String? ?? '';
          _dicas = dicas;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _erro = 'Erro ao gerar dicas. Verifique sua internet.'; _loading = false; });
      }
    }
  }

  Color _corTipo(String tipo) {
    switch (tipo) {
      case 'alerta': return Colors.red;
      case 'conquista': return Colors.green;
      case 'meta': return Colors.blue;
      default: return Colors.orange;
    }
  }

  IconData _iconeTipo(String tipo) {
    switch (tipo) {
      case 'alerta': return Icons.warning_amber_rounded;
      case 'conquista': return Icons.check_circle_outline;
      case 'meta': return Icons.flag_outlined;
      default: return Icons.lightbulb_outline;
    }
  }

  Color _corPrioridade(String p) {
    switch (p) {
      case 'alta': return Colors.red.shade300;
      case 'baixa': return Colors.green.shade300;
      default: return Colors.orange.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (SubscriptionService.instance.isFree) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B2A),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Row(children: [
            Icon(Icons.psychology, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text('Dicas IA', style: TextStyle(color: Colors.white)),
          ]),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 72),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text('Recurso Premium', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 20),
              const Text('Dicas Personalizadas com IA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'A IA analisa seus gastos e ganhos para gerar dicas personalizadas de economia e investimento. Recurso exclusivo para assinantes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallPage())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ver Planos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ]),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(children: [
          Icon(Icons.psychology, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Text('Dicas IA', style: TextStyle(color: Colors.white)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _loading ? null : _analisar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text('Gemini analisando suas finanças...', style: TextStyle(color: Colors.white54)),
              SizedBox(height: 6),
              Text('Isso pode levar alguns segundos', style: TextStyle(color: Colors.white30, fontSize: 12)),
            ]))
          : _erro != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
                  const SizedBox(height: 16),
                  Text(_erro!, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _analisar, child: const Text('Tentar novamente')),
                ]))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Painel resumo financeiro
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF7B1FA2)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Análise de Saúde Financeira', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          _Stat('Ganhos', 'R\$ ${_ganhos.toStringAsFixed(0)}', Colors.green),
                          _Stat('Gastos', 'R\$ ${_gastos.toStringAsFixed(0)}', Colors.red),
                          _Stat('Saldo', 'R\$ ${_saldo.toStringAsFixed(0)}',
                              _saldo >= 0 ? Colors.lightBlueAccent : Colors.red),
                        ]),
                        if (_resumo.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(children: [
                              const Icon(Icons.psychology, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_resumo,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic))),
                            ]),
                          ),
                        ],
                      ]),
                    ),

                    const SizedBox(height: 20),
                    Row(children: [
                      const Text('Dicas Personalizadas', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Gemini AI', style: TextStyle(color: Colors.orange, fontSize: 10)),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    ..._dicas.map((d) {
                      final tipo = d['tipo'] as String;
                      final prioridade = d['prioridade'] as String;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: _corTipo(tipo), width: 3)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(_iconeTipo(tipo), color: _corTipo(tipo), size: 26),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(d['titulo'],
                                  style: TextStyle(color: _corTipo(tipo), fontWeight: FontWeight.bold, fontSize: 14))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _corPrioridade(prioridade).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(prioridade,
                                    style: TextStyle(color: _corPrioridade(prioridade), fontSize: 10)),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Text(d['descricao'],
                                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                          ])),
                        ]),
                      );
                    }),

                    const SizedBox(height: 8),
                    Center(child: TextButton.icon(
                      onPressed: _analisar,
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.white38),
                      label: const Text('Atualizar análise', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    )),
                  ],
                ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  const _Stat(this.label, this.valor, this.cor);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      Text(valor, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }
}
