import 'package:flutter_test/flutter_test.dart';
import 'package:zrobleno/models.dart';

void main() {
  test('todo survives local JSON round trip', () {
    final input = TodoItem(
      id: '1',
      title: 'Зробити MVP',
      category: 'Робота',
      priority: TaskPriority.high,
      done: true,
    );
    final output = decodeList(
      encodeList([input], (item) => item.toJson()),
      TodoItem.fromJson,
    ).single;
    expect(output.title, 'Зробити MVP');
    expect(output.priority, TaskPriority.high);
    expect(output.done, isTrue);
  });

  test('expense amount survives local JSON round trip', () {
    final input = Expense(
      id: '1',
      title: 'Кава',
      amount: 75.5,
      category: 'Продукти',
      date: DateTime(2026),
    );
    final output = Expense.fromJson(input.toJson());
    expect(output.amount, 75.5);
    expect(output.category, 'Продукти');
  });

  test('exact product identity and nutrition survive round trip', () {
    final input = Product(
      id: 'cookie-1',
      name: 'Печиво',
      brand: 'Мій бренд',
      variant: 'Брауні',
      barcode: '482000000001',
      packageGrams: 180,
      kcalPer100: 431,
      proteinPer100: 6.2,
      fatPer100: 18.4,
      carbsPer100: 61,
      source: 'Етикетка',
      verified: true,
    );
    final output = Product.fromJson(input.toJson());
    expect(output.displayName, 'Мій бренд · Печиво · Брауні');
    expect(output.barcode, '482000000001');
    expect(output.kcalPer100, 431);
    expect(output.verified, isTrue);
  });

  test('AI settings require an HTTPS endpoint and personal token', () {
    expect(AiSettings().configured, isFalse);
    expect(
      AiSettings(
        endpoint: 'https://script.google.com/macros/s/example/exec',
        appToken: 'personal-token',
      ).configured,
      isTrue,
    );
  });

  test('receipt scan preserves line items and label requests', () {
    final result = ReceiptScanResult.fromJson({
      'store_name': 'Магазин',
      'receipt_date': '2026-08-10',
      'currency': 'UAH',
      'total': 151.4,
      'category': 'Продукти',
      'items': [
        {
          'name': 'Йогурт',
          'quantity': 2,
          'unit_price': 39.2,
          'total_price': 78.4,
          'is_food': true,
          'estimated_calories': null,
          'nutrition_status': 'needs_label',
          'confidence': .91,
        },
      ],
      'needs_label': ['Йогурт'],
      'note': 'Калорійність на чеку відсутня.',
      'confidence': .88,
    });

    expect(result.total, 151.4);
    expect(result.items.single.name, 'Йогурт');
    expect(result.items.single.estimatedCalories, isNull);
    expect(result.needsLabel, ['Йогурт']);
  });

  test('label scan accepts nullable nutrition fields without guessing', () {
    final result = LabelScanResult.fromJson({
      'name': 'Гранола',
      'brand': 'Тест',
      'variant': '',
      'barcode': '',
      'package_grams': 300,
      'kcal_per_100': 412,
      'protein_per_100': null,
      'fat_per_100': null,
      'carbs_per_100': null,
      'source_text': 'Енергетична цінність 412 ккал / 100 г',
      'missing_fields': ['Білки', 'Жири', 'Вуглеводи'],
      'note': '',
      'confidence': .96,
    });

    expect(result.hasNutrition, isTrue);
    expect(result.kcalPer100, 412);
    expect(result.proteinPer100, isNull);
    expect(result.missingFields, hasLength(3));
  });

  test('assistant response exposes only confirmable actions', () {
    final reply = AssistantReply.fromJson({
      'message': 'Можу додати яблуко після твого підтвердження.',
      'actions': [
        {
          'kind': 'food',
          'title': 'Додати перекус',
          'name': 'Яблуко',
          'category': '',
          'amount': null,
          'calories': 80,
          'protein': 0.4,
          'fat': 0.2,
          'carbs': 21,
        },
        {
          'kind': 'none',
          'title': '',
          'name': '',
          'category': '',
          'amount': null,
          'calories': null,
          'protein': null,
          'fat': null,
          'carbs': null,
        },
      ],
      'quick_replies': ['Так, додай'],
    });

    expect(reply.actions, hasLength(1));
    expect(reply.actions.single.kind, 'food');
    expect(reply.actions.single.calories, 80);
  });
}
