import 'package:flutter/material.dart';

import 'app_store.dart';
import 'pages/finance_page.dart';
import 'pages/food_page.dart';
import 'pages/scanner_page.dart';
import 'pages/tasks_page.dart';
import 'pages/today_page.dart';

class Home extends StatefulWidget {
  const Home({required this.store, super.key});
  final AppStore store;
  @override State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;
  late final pages = [TodayPage(store: widget.store), TasksPage(store: widget.store), ScannerPage(store: widget.store, onSaved: () => setState(() => index = 3)), FinancePage(store: widget.store), FoodPage(store: widget.store)];
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 280), transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child), child: KeyedSubtree(key: ValueKey(index), child: pages[index]))),
    bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (value) => setState(() => index = value), destinations: const [
      NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Сьогодні'),
      NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Zrobleno'),
      NavigationDestination(icon: Icon(Icons.document_scanner_outlined), selectedIcon: Icon(Icons.document_scanner), label: 'Сканер'),
      NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Фінанси'),
      NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Їжа'),
    ]),
  );
}
