import 'dart:convert';

enum TaskPriority { low, medium, high }

class TodoItem {
  TodoItem({
    required this.id,
    required this.title,
    this.note = '',
    this.category = 'Особисте',
    this.priority = TaskPriority.medium,
    this.deadline,
    this.done = false,
  });

  final String id;
  String title;
  String note;
  String category;
  TaskPriority priority;
  DateTime? deadline;
  bool done;

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'] as String,
        title: json['title'] as String,
        note: json['note'] as String? ?? '',
        category: json['category'] as String? ?? 'Особисте',
        priority: TaskPriority.values[json['priority'] as int? ?? 1],
        deadline: json['deadline'] == null
            ? null
            : DateTime.parse(json['deadline'] as String),
        done: json['done'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'category': category,
        'priority': priority.index,
        'deadline': deadline?.toIso8601String(),
        'done': done,
      };
}

class Expense {
  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.receiptPath,
  });

  final String id;
  String title;
  double amount;
  String category;
  DateTime date;
  String? receiptPath;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        receiptPath: json['receiptPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'receiptPath': receiptPath,
      };
}

class FoodEntry {
  FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.date,
    this.productId,
    this.amountGrams,
  });

  final String id;
  String name;
  double calories;
  double protein;
  double fat;
  double carbs;
  DateTime date;
  String? productId;
  double? amountGrams;

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        productId: json['productId'] as String?,
        amountGrams: (json['amountGrams'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'date': date.toIso8601String(),
        'productId': productId,
        'amountGrams': amountGrams,
      };
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.kcalPer100,
    this.brand = '',
    this.variant = '',
    this.barcode = '',
    this.packageGrams,
    this.proteinPer100 = 0,
    this.fatPer100 = 0,
    this.carbsPer100 = 0,
    this.source = 'Етикетка',
    this.verified = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  String brand;
  String variant;
  String barcode;
  double? packageGrams;
  double kcalPer100;
  double proteinPer100;
  double fatPer100;
  double carbsPer100;
  String source;
  bool verified;
  DateTime updatedAt;

  String get displayName => [brand, name, variant]
      .where((part) => part.trim().isNotEmpty)
      .join(' · ');

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String? ?? '',
        variant: json['variant'] as String? ?? '',
        barcode: json['barcode'] as String? ?? '',
        packageGrams: (json['packageGrams'] as num?)?.toDouble(),
        kcalPer100: (json['kcalPer100'] as num).toDouble(),
        proteinPer100: (json['proteinPer100'] as num?)?.toDouble() ?? 0,
        fatPer100: (json['fatPer100'] as num?)?.toDouble() ?? 0,
        carbsPer100: (json['carbsPer100'] as num?)?.toDouble() ?? 0,
        source: json['source'] as String? ?? 'Етикетка',
        verified: json['verified'] as bool? ?? true,
        updatedAt: json['updatedAt'] == null
            ? DateTime.now()
            : DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'variant': variant,
        'barcode': barcode,
        'packageGrams': packageGrams,
        'kcalPer100': kcalPer100,
        'proteinPer100': proteinPer100,
        'fatPer100': fatPer100,
        'carbsPer100': carbsPer100,
        'source': source,
        'verified': verified,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class ReminderSettings {
  ReminderSettings({
    this.morningEnabled = true,
    this.morningHour = 8,
    this.morningMinute = 0,
    this.eveningEnabled = true,
    this.eveningHour = 21,
    this.eveningMinute = 0,
  });

  bool morningEnabled;
  int morningHour;
  int morningMinute;
  bool eveningEnabled;
  int eveningHour;
  int eveningMinute;

  factory ReminderSettings.fromJson(Map<String, dynamic> json) =>
      ReminderSettings(
        morningEnabled: json['morningEnabled'] as bool? ?? true,
        morningHour: json['morningHour'] as int? ?? 8,
        morningMinute: json['morningMinute'] as int? ?? 0,
        eveningEnabled: json['eveningEnabled'] as bool? ?? true,
        eveningHour: json['eveningHour'] as int? ?? 21,
        eveningMinute: json['eveningMinute'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'morningEnabled': morningEnabled,
        'morningHour': morningHour,
        'morningMinute': morningMinute,
        'eveningEnabled': eveningEnabled,
        'eveningHour': eveningHour,
        'eveningMinute': eveningMinute,
      };
}

class GameState {
  GameState({
    this.seeds = 12,
    this.xp = 0,
    this.nestLevel = 1,
    this.gardenLevel = 0,
    this.wolfMess = false,
  });

  int seeds;
  int xp;
  int nestLevel;
  int gardenLevel;
  bool wolfMess;

  int get birdStage {
    if (xp >= 160) return 3;
    if (xp >= 70) return 2;
    if (xp >= 25) return 1;
    return 0;
  }

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        seeds: json['seeds'] as int? ?? 12,
        xp: json['xp'] as int? ?? 0,
        nestLevel: json['nestLevel'] as int? ?? 1,
        gardenLevel: json['gardenLevel'] as int? ?? 0,
        wolfMess: json['wolfMess'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'seeds': seeds,
        'xp': xp,
        'nestLevel': nestLevel,
        'gardenLevel': gardenLevel,
        'wolfMess': wolfMess,
      };
}

String encodeList<T>(List<T> items, Map<String, dynamic> Function(T) map) =>
    jsonEncode(items.map(map).toList());

List<T> decodeList<T>(
  String? raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw == null || raw.isEmpty) return [];
  return (jsonDecode(raw) as List<dynamic>)
      .map((item) => fromJson(item as Map<String, dynamic>))
      .toList();
}

Map<String, dynamic> decodeObject(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  return jsonDecode(raw) as Map<String, dynamic>;
}
