import 'package:flutter/material.dart';

import 'app_store.dart';
import 'pages/finance_page.dart';
import 'pages/food_page.dart';
import 'pages/scanner_page.dart';
import 'pages/tasks_page.dart';
import 'pages/today_page.dart';
import 'theme.dart';

class Home extends StatefulWidget {
  const Home({required this.store, super.key});

  final AppStore store;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;

  late final pages = [
    TodayPage(store: widget.store),
    TasksPage(store: widget.store),
    ScannerPage(store: widget.store, onSaved: () => setState(() => index = 3)),
    FinancePage(store: widget.store),
    FoodPage(store: widget.store),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBody: true,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF283B4A), Color(0xFF17182B)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween(begin: const Offset(.035, 0), end: Offset.zero)
                          .animate(animation),
                  child: child,
                ),
              ),
              child: Padding(
                key: ValueKey(index),
                padding: const EdgeInsets.only(bottom: 80),
                child: pages[index],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _GameNavigation(
          index: index,
          onChanged: (value) => setState(() => index = value),
        ),
      );
}

class _GameNavigation extends StatelessWidget {
  const _GameNavigation({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const items = [
    (Icons.home_rounded, 'День', sunYellow),
    (Icons.checklist_rounded, 'Справи', gameCoral),
    (Icons.document_scanner_rounded, 'Сканер', gameMint),
    (Icons.savings_rounded, 'Гроші', orange),
    (Icons.restaurant_rounded, 'Їжа', Color(0xFF80A9D7)),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: gamePlum,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF181424), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                offset: Offset(0, 5),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (itemIndex) {
              final item = items[itemIndex];
              final selected = itemIndex == index;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: item.$2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => onChanged(itemIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: selected ? item.$3 : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        border: selected
                            ? Border.all(color: gameInk, width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.$1,
                            size: selected ? 24 : 22,
                            color: selected ? gameInk : Colors.white70,
                          ),
                          if (selected)
                            Text(
                              item.$2,
                              maxLines: 1,
                              style: const TextStyle(
                                color: gameInk,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
}
