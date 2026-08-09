import 'package:flutter_test/flutter_test.dart';
import 'package:zrobleno/models.dart';

void main() {
  test('todo survives local JSON round trip', () {
    final input = TodoItem(id: '1', title: 'Зробити MVP', category: 'Робота', priority: TaskPriority.high, done: true);
    final output = decodeList(encodeList([input], (e) => e.toJson()), TodoItem.fromJson).single;
    expect(output.title, 'Зробити MVP');
    expect(output.priority, TaskPriority.high);
    expect(output.done, isTrue);
  });

  test('expense amount survives local JSON round trip', () {
    final input = Expense(id: '1', title: 'Кава', amount: 75.5, category: 'Продукти', date: DateTime(2026));
    final output = Expense.fromJson(input.toJson());
    expect(output.amount, 75.5);
    expect(output.category, 'Продукти');
  });
}
