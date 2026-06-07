import 'package:flutter/material.dart';
import 'home_page.dart';
import 'ofertas_page.dart';
import 'assistente_page.dart';
import 'score_page.dart';
import 'gps_economia_page.dart';
import 'paywall_page.dart';
import '../services/subscription_service.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final sub = SubscriptionService.instance;
    final showTrialBanner = sub.isTrial && sub.trialDaysLeft <= 3;

    return Scaffold(
      body: Column(
        children: [
          if (showTrialBanner)
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const PaywallPage())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.orange.shade800,
                child: Text(
                  sub.trialDaysLeft == 0
                      ? 'Seu período gratuito expira hoje! Toque para assinar.'
                      : 'Faltam ${sub.trialDaysLeft} dia${sub.trialDaysLeft == 1 ? "" : "s"} grátis. Toque para assinar.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _idx,
              children: const [
                HomePage(),
                GpsEconomiaPage(),
                OfertasPage(),
                AssistentePage(),
                ScorePage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          backgroundColor: const Color(0xFF0A1628),
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 9,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'GPS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined),
              activeIcon: Icon(Icons.local_offer),
              label: 'Ofertas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'FinanceIA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.stars_outlined),
              activeIcon: Icon(Icons.stars),
              label: 'Score',
            ),
          ],
        ),
      ),
    );
  }
}
