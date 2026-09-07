import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_store.dart';
import '../dialogs.dart';
import '../models.dart';
import '../theme.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final data = [...store.expenses]
            ..sort((a, b) => b.date.compareTo(a.date));
          final total = data.fold<double>(0, (sum, item) => sum + item.amount);
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton(
              onPressed: () => editExpense(context, store),
              child: const Icon(Icons.add),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 100),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: GradientTitle('Фінанси'),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25644C), Color(0xFF533A8C)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Загальні витрати', style: TextStyle(color: Colors.white70)),
                      Text('${total.toStringAsFixed(2)} ₴', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Історія', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (data.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Витрат поки немає', style: TextStyle(color: Colors.white54))),
                  ),
                ...data.map(
                  (expense) => Dismissible(
                    key: ValueKey(expense.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => store.deleteExpense(expense),
                    background: const Card(
                      color: Colors.red,
                      child: Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.all(20), child: Icon(Icons.delete))),
                    ),
                    child: Card(
                      child: ListTile(
                        onTap: () {
                          final receipt = store.receiptForExpense(expense.id);
                          if (receipt == null) {
                            editExpense(context, store, item: expense);
                          } else {
                            _showReceiptDetails(
                              context,
                              store,
                              expense,
                              receipt,
                            );
                          }
                        },
                        leading: const CircleAvatar(backgroundColor: Color(0x3343E69B), child: Icon(Icons.receipt_long, color: green)),
                        title: Text(expense.title),
                        subtitle: Text('${expense.category} • ${DateFormat('dd.MM.yyyy').format(expense.date)}'),
                        trailing: Text('-${expense.amount.toStringAsFixed(2)} ₴', style: const TextStyle(fontWeight: FontWeight.bold, color: orange)),
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

Future<void> _showReceiptDetails(
  BuildContext context,
  AppStore store,
  Expense expense,
  SavedReceipt savedReceipt,
) async {
  final receipt = savedReceipt.receipt;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .78,
      minChildSize: .45,
      maxChildSize: .94,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
        children: [
          Text(
            receipt.storeName,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            '${DateFormat('dd.MM.yyyy').format(expense.date)} · ${expense.amount.toStringAsFixed(2)} ₴ · ${expense.category}',
            style: const TextStyle(color: Colors.white60),
          ),
          if (receipt.receiptNumber.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'Чек № ${receipt.receiptNumber}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'ПОЗИЦІЇ ЧЕКА',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          ...receipt.items.map(
            (item) => Card(
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(
                  [
                    item.expenseCategory,
                    if (item.subcategory.isNotEmpty) item.subcategory,
                    if (item.consumerType == 'pet') 'для тварин',
                    if (item.trackNutrition) 'враховувати в харчуванні',
                  ].join(' · '),
                ),
                trailing: Text('${item.totalPrice.toStringAsFixed(2)} ₴'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              editExpense(context, store, item: expense);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Редагувати загальний запис'),
          ),
        ],
      ),
    ),
  );
}
