import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../services/ai_service.dart';
import '../theme.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({required this.store, super.key});

  final AppStore store;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final query = search.text.trim().toLowerCase();
      final products = widget.store.products.where((product) {
        final haystack = [
          product.name,
          product.brand,
          product.variant,
          product.barcode,
        ].join(' ').toLowerCase();
        return query.isEmpty || haystack.contains(query);
      }).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
      return Scaffold(
        appBar: AppBar(
          title: const Text('Моя база продуктів'),
          backgroundColor: Colors.transparent,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => editProduct(context, widget.store),
          icon: const Icon(Icons.add),
          label: const Text('Продукт'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            const Text(
              'Точні картки зберігаються локально. Бренд, варіант і штрихкод не дадуть переплутати різне печиво.',
              style: TextStyle(color: Colors.white60, height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Назва, бренд або штрихкод',
              ),
            ),
            const SizedBox(height: 14),
            if (products.isEmpty)
              const _EmptyProducts()
            else
              ...products.map(
                (product) => Dismissible(
                  key: ValueKey(product.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Видалити картку?'),
                      content: Text(product.displayName),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Ні'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Видалити'),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) => widget.store.deleteProduct(product),
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
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () => editProduct(context, widget.store, product),
                      leading: CircleAvatar(
                        backgroundColor: purple.withValues(alpha: .16),
                        child: const Icon(Icons.cookie_outlined, color: purple),
                      ),
                      title: Text(
                        product.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          '${product.kcalPer100.round()} ккал / 100 г'
                          '${product.packageGrams == null ? '' : ' · ${product.packageGrams!.round()} г'}\n'
                          '${product.verified ? '✓ перевірено' : 'потребує перевірки'} · ${product.source}',
                        ),
                      ),
                      trailing: product.barcode.isEmpty
                          ? null
                          : const Icon(Icons.qr_code_2, color: green),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 70),
    child: Column(
      children: [
        Icon(Icons.inventory_2_outlined, size: 64, color: purple),
        SizedBox(height: 14),
        Text(
          'База ще порожня',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          'Додай перший точний продукт з етикетки.',
          style: TextStyle(color: Colors.white54),
        ),
      ],
    ),
  );
}

Future<void> editProduct(
  BuildContext context,
  AppStore store, [
  Product? item,
]) async {
  final name = TextEditingController(text: item?.name);
  final brand = TextEditingController(text: item?.brand);
  final variant = TextEditingController(text: item?.variant);
  final barcode = TextEditingController(text: item?.barcode);
  final package = TextEditingController(text: item?.packageGrams?.toString());
  final kcal = TextEditingController(text: item?.kcalPer100.toString());
  final protein = TextEditingController(text: item?.proteinPer100.toString());
  final fat = TextEditingController(text: item?.fatPer100.toString());
  final carbs = TextEditingController(text: item?.carbsPer100.toString());
  var source = item?.source ?? 'Етикетка';
  var verified = item?.verified ?? true;
  Product? saved;

  double? number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(item == null ? 'Новий точний продукт' : 'Картка продукту'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Назва *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: brand,
                decoration: const InputDecoration(labelText: 'Бренд'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: variant,
                decoration: const InputDecoration(
                  labelText: 'Варіант / смак / сорт',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: barcode,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Штрихкод'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: package,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Вага пачки, г',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: kcal,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'ккал / 100 г *',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MacroField(controller: protein, label: 'Білки'),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _MacroField(controller: fat, label: 'Жири'),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _MacroField(controller: carbs, label: 'Вугл.'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: source,
                decoration: const InputDecoration(labelText: 'Джерело'),
                items: const [
                  DropdownMenuItem(value: 'Етикетка', child: Text('Етикетка')),
                  DropdownMenuItem(
                    value: 'AI з етикетки',
                    child: Text('AI з етикетки'),
                  ),
                  DropdownMenuItem(value: 'Інтернет', child: Text('Інтернет')),
                  DropdownMenuItem(value: 'Вручну', child: Text('Вручну')),
                ],
                onChanged: (value) =>
                    setDialogState(() => source = value ?? source),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Я перевірив дані'),
                value: verified,
                onChanged: (value) => setDialogState(() => verified = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () {
              final calories = number(kcal);
              if (name.text.trim().isEmpty ||
                  calories == null ||
                  calories <= 0) {
                return;
              }
              saved = Product(
                id: item?.id ?? store.id(),
                name: name.text.trim(),
                brand: brand.text.trim(),
                variant: variant.text.trim(),
                barcode: barcode.text.trim(),
                packageGrams: number(package),
                kcalPer100: calories,
                proteinPer100: number(protein) ?? 0,
                fatPer100: number(fat) ?? 0,
                carbsPer100: number(carbs) ?? 0,
                source: source,
                verified: verified,
              );
              store.upsertProduct(saved!);
              Navigator.pop(context);
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    ),
  );

  name.dispose();
  brand.dispose();
  variant.dispose();
  barcode.dispose();
  package.dispose();
  kcal.dispose();
  protein.dispose();
  fat.dispose();
  carbs.dispose();
  if (saved == null ||
      !store.aiSettings.configured ||
      !store.aiSettings.syncGoogleSheets) {
    return;
  }
  try {
    await AiService(store.aiSettings).syncProduct(saved!);
  } on AiServiceException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Продукт збережено локально. Sheets зараз недоступний.'),
      ),
    );
  }
}

class _MacroField extends StatelessWidget {
  const _MacroField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: '$label / 100 г'),
  );
}
