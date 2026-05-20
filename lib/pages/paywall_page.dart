import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/subscription_service.dart';
import 'main_nav.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});
  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _loading = false;
  String? _error;

  Future<void> _assinar() async {
    setState(() { _loading = true; _error = null; });
    final erro = await SubscriptionService.instance.subscribe();
    if (!mounted) return;
    if (erro != null) {
      setState(() { _loading = false; _error = erro; });
    } else {
      // Aguarda confirmação do Google Play
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      if (SubscriptionService.instance.isSubscribed) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNav()));
      } else {
        setState(() { _loading = false; _error = 'Assinatura não confirmada ainda. Tente restaurar.'; });
      }
    }
  }

  Future<void> _restaurar() async {
    setState(() { _loading = true; _error = null; });
    await SubscriptionService.instance.restore();
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (SubscriptionService.instance.isSubscribed) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNav()));
    } else {
      setState(() { _loading = false; _error = 'Nenhuma assinatura ativa encontrada.'; });
    }
  }

  void _sair() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF4A148C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('IA Financeiro', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Controle total da sua vida financeira com IA', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 32),

              // Preço
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF4A148C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
              const _Beneficio(icon: Icons.psychology, titulo: 'Assistente IA Gemini', desc: 'Converse com a IA sobre suas finanças'),
              const _Beneficio(icon: Icons.lightbulb_outline, titulo: 'Dicas Personalizadas', desc: '4 dicas diárias baseadas nos seus dados'),
              const _Beneficio(icon: Icons.search, titulo: 'Busca de Produtos', desc: 'Encontre ofertas com análise financeira'),
              const _Beneficio(icon: Icons.trending_up, titulo: 'Simulador de Investimentos', desc: 'Projete seu patrimônio futuro'),
              const _Beneficio(icon: Icons.attach_money, titulo: 'Oportunidades de Renda Extra', desc: '20+ formas de ganhar mais dinheiro'),
              const _Beneficio(icon: Icons.shield_outlined, titulo: 'Controle Total', desc: 'Ganhos, gastos, score e extrato ilimitados'),
              const SizedBox(height: 28),

              // Erro
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
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
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Começar 7 dias grátis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),

              // Restaurar
              TextButton(
                onPressed: _loading ? null : _restaurar,
                child: const Text('Já sou assinante — Restaurar', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: _sair,
                child: const Text('Sair da conta', style: TextStyle(color: Colors.white24, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              const Text('A cobrança inicia após o período gratuito.\nCancele a qualquer momento no Google Play.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 11)),
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
