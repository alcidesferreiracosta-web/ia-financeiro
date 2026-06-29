import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/subscription_service.dart';
import 'paywall_page.dart';

class AssistentePage extends StatefulWidget {
  const AssistentePage({super.key});
  @override
  State<AssistentePage> createState() => _AssistentePageState();
}

class _AssistentePageState extends State<AssistentePage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _msgs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _msgs.add({'role': 'assistant', 'content':
      'Olá! Sou a FinanceIA, sua assistente financeira com IA real. 💰\n\n'
      'Tenho acesso aos seus dados financeiros e posso te ajudar com:\n'
      '• Análise dos seus gastos e sugestões de economia\n'
      '• Planejamento para metas (carro, casa, viagem)\n'
      '• Comparação de investimentos (CDB, Tesouro, LCI)\n'
      '• Dicas personalizadas baseadas na sua realidade\n\n'
      'Me pergunte qualquer coisa sobre suas finanças!'
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final pergunta = _controller.text.trim();
    if (pergunta.isEmpty || _loading) return;

    setState(() {
      _msgs.add({'role': 'user', 'content': pergunta});
      _controller.clear();
      _loading = true;
    });
    _rolarParaBaixo();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final fn = FirebaseFunctions.instance.httpsCallable(
        'chatFinanceiro',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await fn.call({'pergunta': pergunta, 'uid': uid});
      final resposta = result.data['resposta'] as String? ?? 'Não consegui processar. Tente novamente.';

      if (mounted) {
        setState(() {
          _msgs.add({'role': 'assistant', 'content': resposta});
          _loading = false;
        });
        _rolarParaBaixo();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _msgs.add({'role': 'assistant', 'content': 'Erro ao conectar com a IA. Verifique sua internet e tente novamente.'});
          _loading = false;
        });
        _rolarParaBaixo();
      }
    }
  }

  void _rolarParaBaixo() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (SubscriptionService.instance.isFree) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B2A),
          automaticallyImplyLeading: false,
          title: const Text('FinanceIA', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.psychology, color: Colors.orange, size: 72),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text('Recurso Premium', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 20),
              const Text('Assistente FinanceIA com IA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'O assistente com IA real analisa seus dados financeiros e dá conselhos personalizados. Disponível apenas para assinantes.',
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
          Icon(Icons.psychology, color: Colors.orange, size: 22),
          SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FinanceIA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Gemini AI • Dados reais', style: TextStyle(color: Colors.white38, fontSize: 10)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _msgs.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (_loading && i == _msgs.length) {
                  return const _TypingIndicator();
                }
                final msg = _msgs[i];
                final isUser = msg['role'] == 'user';
                return _BubbleMensagem(
                  texto: msg['content']!,
                  isUser: isUser,
                );
              },
            ),
          ),

          // Sugestões rápidas
          if (_msgs.length <= 1)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  'Como estão meus gastos?',
                  'Dicas para economizar',
                  'Quanto investir?',
                  'Minha situação financeira',
                ].map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(s),
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    backgroundColor: const Color(0xFF1A2A3A),
                    side: const BorderSide(color: Colors.orange, width: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    onPressed: () {
                      _controller.text = s;
                      _enviar();
                    },
                  ),
                )).toList(),
              ),
            ),

          const SizedBox(height: 8),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0A1628),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviar(),
                  decoration: InputDecoration(
                    hintText: 'Pergunte sobre suas finanças...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _loading ? null : _enviar,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _loading ? Colors.white24 : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _loading ? Icons.hourglass_empty : Icons.send_rounded,
                    color: Colors.white, size: 20,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _BubbleMensagem extends StatelessWidget {
  final String texto;
  final bool isUser;
  const _BubbleMensagem({required this.texto, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: Colors.orange, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.orange : const Color(0xFF1A2A3A),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                texto,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.psychology, color: Colors.orange, size: 18),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A3A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
              _Dot(delay: 0, ctrl: _ctrl),
              const SizedBox(width: 4),
              _Dot(delay: 0.3, ctrl: _ctrl),
              const SizedBox(width: 4),
              _Dot(delay: 0.6, ctrl: _ctrl),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final double delay;
  final AnimationController ctrl;
  const _Dot({required this.delay, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: ctrl,
      curve: Interval(delay, (delay + 0.4).clamp(0, 1), curve: Curves.easeInOut),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.4 + anim.value * 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
