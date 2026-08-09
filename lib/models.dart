import 'dart:convert';

enum TaskPriority { low, medium, high }

class TodoItem {
  TodoItem({required this.id, required this.title, this.note = '', this.category = 'Особисте', this.priority = TaskPriority.medium, this.deadline, this.done = false});
  final String id;
  String title;
  String note;
  String category;
  TaskPriority priority;
  DateTime? deadline;
  bool done;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'note': note, 'category': category, 'priority': priority.index, 'deadline': deadline?.toIso8601String(), 'done': done};
  factory TodoItem.fromJson(Map<String, dynamic> j) => TodoItem(id: j['id'] as String, title: j['title'] as String, note: j['note'] as String? ?? '', category: j['category'] as String? ?? 'Особисте', priority: TaskPriority.values[j['priority'] as int? ?? 1], deadline: j['deadline'] == null ? null : DateTime.parse(j['deadline'] as String), done: j['done'] as bool? ?? false);
}

class Expense {
  Expense({required this.id, required this.title, required this.amount, required this.category, required this.date, this.receiptPath});
  final String id;
  String title;
  double amount;
  String category;
  DateTime date;
  String? receiptPath;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'amount': amount, 'category': category, 'date': date.toIso8601String(), 'receiptPath': receiptPath};
  factory Expense.fromJson(Map<String, dynamic> j) => Expense(id: j['id'] as String, title: j['title'] as String, amount: (j['amount'] as num).toDouble(), category: j['category'] as String, date: DateTime.parse(j['date'] as String), receiptPath: j['receiptPath'] as String?);
}

class FoodEntry {
  FoodEntry({required this.id, required this.name, required this.calories, required this.protein, required this.fat, required this.carbs, required this.date});
  final String id;
  String name;
  double calories, protein, fat, carbs;
  DateTime date;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'calories': calories, 'protein': protein, 'fat': fat, 'carbs': carbs, 'date': date.toIso8601String()};
  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(id: j['id'] as String, name: j['name'] as String, calories: (j['calories'] as num).toDouble(), protein: (j['protein'] as num).toDouble(), fat: (j['fat'] as num).toDouble(), carbs: (j['carbs'] as num).toDouble(), date: DateTime.parse(j['date'] as String));
}

String encodeList<T>(List<T> values, Map<String, dynamic> Function(T) convert) => jsonEncode(values.map(convert).toList());
List<T> decodeList<T>(String? raw, T Function(Map<String, dynamic>) convert) => raw == null ? [] : (jsonDecode(raw) as List).map((e) => convert(Map<String, dynamic>.from(e as Map))).toList();
