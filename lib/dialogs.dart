import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_store.dart';
import 'models.dart';
import 'services/ai_service.dart';
import 'services/sound_service.dart';

Future<void> editTask(
  BuildContext context,
  AppStore store, [
  TodoItem? item,
]) async {
  final title = TextEditingController(text: item?.title);
  final note = TextEditingController(text: item?.note);
  var category = item?.category ?? 'Особисте';
  var priority = item?.priority ?? TaskPriority.medium;
  var deadline = item?.deadline;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(item == null ? 'Нове завдання' : 'Редагувати завдання'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Назва'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Нотатка'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Категорія'),
                items:
                    const ['Особисте', 'Робота', 'Дім', 'Здоров’я', 'Покупки']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) =>
                    setDialogState(() => category = value ?? category),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Пріоритет'),
                items: const [
                  DropdownMenuItem(
                    value: TaskPriority.low,
                    child: Text('Низький'),
                  ),
                  DropdownMenuItem(
                    value: TaskPriority.medium,
                    child: Text('Середній'),
                  ),
                  DropdownMenuItem(
                    value: TaskPriority.high,
                    child: Text('Високий'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => priority = value ?? priority),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  deadline == null
                      ? 'Без дедлайну'
                      : DateFormat('dd.MM.yyyy').format(deadline!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDate: deadline ?? DateTime.now(),
                  );
                  if (!context.mounted) return;
                  if (selected != null) {
                    setDialogState(() => deadline = selected);
                  }
                },
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
              if (title.text.trim().isEmpty) return;
              if (item == null) {
                store.tasks.add(
                  TodoItem(
                    id: store.id(),
                    title: title.text.trim(),
                    note: note.text.trim(),
                    category: category,
                    priority: priority,
                    deadline: deadline,
                  ),
                );
              } else {
                item
                  ..title = title.text.trim()
                  ..note = note.text.trim()
                  ..category = category
                  ..priority = priority
                  ..deadline = deadline;
              }
              store.changed(sound: AppSound.actionConfirm);
              Navigator.pop(context);
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    ),
  );

  title.dispose();
  note.dispose();
}

Future<void> editExpense(
  BuildContext context,
  AppStore store, {
  Expense? item,
  String? receiptPath,
}) async {
  final title = TextEditingController(text: item?.title ?? 'Покупка');
  final amount = TextEditingController(text: item?.amount.toStringAsFixed(2));
  var category = item?.category ?? 'Продукти';
  Expense? saved;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          item == null ? 'Підтвердьте витрату' : 'Редагувати витрату',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Опис'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Сума, ₴'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Категорія'),
              items:
                  const [
                        'Продукти',
                        'Транспорт',
                        'Дім',
                        'Здоров’я',
                        'Розваги',
                        'Інше',
                      ]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: (value) =>
                  setDialogState(() => category = value ?? category),
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
              final parsed = double.tryParse(
                amount.text.trim().replaceAll(',', '.'),
              );
              if (title.text.trim().isEmpty || parsed == null || parsed <= 0) {
                return;
              }
              if (item == null) {
                saved = Expense(
                  id: store.id(),
                  title: title.text.trim(),
                  amount: parsed,
                  category: category,
                  date: DateTime.now(),
                  receiptPath: receiptPath,
                );
                store.expenses.add(saved!);
              } else {
                item
                  ..title = title.text.trim()
                  ..amount = parsed
                  ..category = category;
                saved = item;
              }
              store.changed(sound: AppSound.actionConfirm);
              Navigator.pop(context);
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    ),
  );

  title.dispose();
  amount.dispose();
  if (!context.mounted) return;
  if (saved != null) await _syncExpense(context, store, saved!);
}

Future<void> editFood(
  BuildContext context,
  AppStore store, [
  FoodEntry? item,
]) async {
  final values = [
    TextEditingController(text: item?.name),
    TextEditingController(text: item?.calories.toString()),
    TextEditingController(text: item?.protein.toString()),
    TextEditingController(text: item?.fat.toString()),
    TextEditingController(text: item?.carbs.toString()),
  ];
  FoodEntry? saved;

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(item == null ? 'Додати їжу' : 'Редагувати їжу'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            values.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: values[index],
                keyboardType: index == 0
                    ? TextInputType.text
                    : const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: const [
                    'Назва',
                    'Калорії, ккал',
                    'Білки, г',
                    'Жири, г',
                    'Вуглеводи, г',
                  ][index],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          onPressed: () {
            double number(int index) =>
                double.tryParse(
                  values[index].text.trim().replaceAll(',', '.'),
                ) ??
                0;

            if (values.first.text.trim().isEmpty) return;
            if (item == null) {
              saved = FoodEntry(
                id: store.id(),
                name: values.first.text.trim(),
                calories: number(1),
                protein: number(2),
                fat: number(3),
                carbs: number(4),
                date: DateTime.now(),
              );
              store.foods.add(saved!);
            } else {
              item
                ..name = values.first.text.trim()
                ..calories = number(1)
                ..protein = number(2)
                ..fat = number(3)
                ..carbs = number(4);
              saved = item;
            }
            store.changed(sound: AppSound.actionConfirm);
            Navigator.pop(context);
          },
          child: const Text('Зберегти'),
        ),
      ],
    ),
  );

  for (final controller in values) {
    controller.dispose();
  }
  if (!context.mounted) return;
  if (saved != null) await _syncFood(context, store, saved!);
}

Future<void> _syncExpense(
  BuildContext context,
  AppStore store,
  Expense expense,
) async {
  if (!store.aiSettings.configured || !store.aiSettings.syncGoogleSheets) {
    return;
  }
  try {
    await AiService(store.aiSettings).syncExpense(expense);
  } on AiServiceException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Локально збережено. Google Sheets зараз недоступний.'),
      ),
    );
  }
}

Future<void> _syncFood(
  BuildContext context,
  AppStore store,
  FoodEntry food,
) async {
  if (!store.aiSettings.configured || !store.aiSettings.syncGoogleSheets) {
    return;
  }
  try {
    await AiService(store.aiSettings).syncFood(food);
  } on AiServiceException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Локально збережено. Google Sheets зараз недоступний.'),
      ),
    );
  }
}
