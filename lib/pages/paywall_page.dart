import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';

// Substituir pelo link real do produto Hotmart após criar a assinatura
const _kHotmartUrl = 'https://pay.hotmart.com/N106016337A';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});
  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _loading = false;
  String? _error;

  Future<void> _assinar() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final url = Uri.parse('$_kHotmartUrl?email=${Uri.encodeComponent(email)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) setState(() => _error = 'Não foi possível abrir o checkout.');
    }
  }

  Future<void> _verificar() async {
    setState(() { _loading = true; _error = null; });
    await SubscriptionService.instance.init();
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _loading = false);
    if (!SubscriptionService.instance.isSubscribed) {
      setState(() => _error = 'Pagamento não identificado. Aguarde alguns instantes e tente novamente.');
    }
  }

  void _sair() => FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('IA Financeiro',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Controle total da sua vida financeira com IA',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 32),

              // Preço
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                    child: const Text('7 DIAS GRÁTIS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  const Text('R\$ 9,90', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                  const Text('/mês', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Cancele quando quiser', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 24),

              // Benefícios
              const _Beneficio(icon: Icons.psychology, titulo: 'Assistente IA', desc: 'Converse com a IA sobre suas finanças'),
              const _Beneficio(icon: Icons.lightbulb_outline, titulo: 'Dicas Personalizadas', desc: '4 dicas diárias baseadas nos seus dados'),
              const _Beneficio(icon: Icons.search, titulo: 'Busca de Produtos', desc: 'Encontre ofertas com análise financeira'),
              const _Beneficio(icon: Icons.trending_up, titulo: 'Simulador de Investimentos', desc: 'Projete seu patrimônio futuro'),
              const _Beneficio(icon: Icons.attach_money, titulo: 'Renda Extra', desc: '20+ formas de ganhar mais dinheiro'),
              const _Beneficio(icon: Icons.shield_outlined, titulo: 'Controle Total', desc: 'Ganhos, gastos, score e extrato ilimitados'),
              const SizedBox(height: 24),

              // Aviso de e-mail
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Use o e-mail "$email" no checkout para ativar automaticamente.',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  )),
                ]),
              ),
              const SizedBox(height: 20),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                ),

              // Botão assinar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _assinar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Começar 7 dias grátis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),

              // Verificar após pagamento
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loading ? null : _verificar,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))
                      : const Text('Já paguei — Verificar acesso', style: TextStyle(color: Colors.white54)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _sair,
                child: const Text('Sair da conta', style: TextStyle(color: Colors.white24, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              const Text(
                'A cobrança inicia após os 7 dias gratuitos.\nProcessado com segurança via Hotmart.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Beneficio extends StatelessWidget {
  final IconData icon;
  final String titulo, desc;
  const _Beneficio({required this.icon, required this.titulo, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.orange, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ])),
        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
      ]),
    );
  }
}
