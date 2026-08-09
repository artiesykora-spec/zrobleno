import 'package:flutter/material.dart';

import '../app_store.dart';
import '../dialogs.dart';
import '../models.dart';
import '../theme.dart';
import 'products_page.dart';

class FoodPage extends StatelessWidget {
  const FoodPage({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final today = store.foods.where((food) => store.isToday(food.date)).toList();
          final calories = today.fold<double>(0, (sum, food) => sum + food.calories);
          final protein = today.fold<double>(0, (sum, food) => sum + food.protein);
          final fat = today.fold<double>(0, (sum, food) => sum + food.fat);
          final carbs = today.fold<double>(0, (sum, food) => sum + food.carbs);
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddFood(context),
              child: const Icon(Icons.add),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 100),
              children: [
                const GradientTitle('Харчування'),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Text(
                          '${calories.round()} ккал',
                          style: const TextStyle(
                            color: green,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _Macro('Білки', protein, purple),
                            _Macro('Жири', fat, orange),
                            _Macro('Вуглеводи', carbs, green),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ProductsPage(store: store),
                    ),
                  ),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text('Моя база продуктів · ${store.products.length}'),
                ),
                const SizedBox(height: 18),
                if (today.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_menu, size: 58, color: green),
                        SizedBox(height: 12),
                        Text(
                          'Сьогодні ще нічого не записано',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                else ...[
                  const Text(
                    'Сьогодні',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  ...today.map(
                    (food) => Dismissible(
                      key: ValueKey(food.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => store.deleteFood(food),
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.shade800,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.delete_outline),
                      ),
                      child: Card(
                        child: ListTile(
                          onTap: food.productId == null
                              ? () => editFood(context, store, food)
                              : null,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x2261E7A7),
                            child: Icon(Icons.restaurant, color: green),
                          ),
                          title: Text(
                            food.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            food.amountGrams == null
                                ? 'Б ${food.protein.toStringAsFixed(1)} · Ж ${food.fat.toStringAsFixed(1)} · В ${food.carbs.toStringAsFixed(1)}'
                                : '${food.amountGrams!.round()} г · з моєї бази',
                          ),
                          trailing: Text(
                            '${food.calories.round()} ккал',
                            style: const TextStyle(color: green),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );

  Future<void> _showAddFood(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: purple),
                title: const Text('З моєї бази продуктів'),
                subtitle: const Text('Обрати точний продукт і вказати грами'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addSavedProduct(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: green),
                title: const Text('Внести вручну'),
                subtitle: const Text('Калорії та БЖВ для разового запису'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  editFood(context, store);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addSavedProduct(BuildContext context) async {
    if (store.products.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => ProductsPage(store: store)),
      );
      if (!context.mounted || store.products.isEmpty) return;
    }
    Product selected = store.products.first;
    final grams = TextEditingController(
      text: selected.packageGrams?.toStringAsFixed(0) ?? '100',
    );
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Додати з моєї бази'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Точний продукт'),
                items: store.products
                    .map(
                      (product) => DropdownMenuItem(
                        value: product,
                        child: Text(
                          product.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() {
                    selected = value;
                    grams.text = value.packageGrams?.toStringAsFixed(0) ?? '100';
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: grams,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'З’їдено, г'),
              ),
              const SizedBox(height: 10),
              Text(
                '${selected.kcalPer100.round()} ккал / 100 г',
                style: const TextStyle(color: green),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(grams.text.replaceAll(',', '.'));
                if (value == null || value <= 0) return;
                store.addFoodFromProduct(selected, value);
                Navigator.pop(context);
              },
              child: const Text('Додати'),
            ),
          ],
        ),
      ),
    );
    grams.dispose();
  }
}

class _Macro extends StatelessWidget {
  const _Macro(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)} г',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(color: Colors.white54)),
        ],
      );
}
