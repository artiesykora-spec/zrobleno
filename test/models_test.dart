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
}
