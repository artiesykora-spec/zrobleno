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

  String get displayName => [
    brand,
    name,
    variant,
  ].where((part) => part.trim().isNotEmpty).join(' · ');

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

class AiSettings {
  AiSettings({
    this.endpoint = '',
    this.appToken = '',
    this.syncGoogleSheets = true,
  });

  String endpoint;
  String appToken;
  bool syncGoogleSheets;

  bool get configured =>
      endpoint.trim().startsWith('https://') && appToken.trim().isNotEmpty;

  factory AiSettings.fromJson(Map<String, dynamic> json) => AiSettings(
    endpoint: json['endpoint'] as String? ?? '',
    appToken: json['appToken'] as String? ?? '',
    syncGoogleSheets: json['syncGoogleSheets'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'appToken': appToken,
    'syncGoogleSheets': syncGoogleSheets,
  };
}

class AssistantMessage {
  AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.date,
  });

  final String id;
  final String role;
  final String text;
  final DateTime date;

  bool get isUser => role == 'user';

  factory AssistantMessage.fromJson(Map<String, dynamic> json) =>
      AssistantMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        text: json['text'] as String,
        date: DateTime.parse(json['date'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'text': text,
    'date': date.toIso8601String(),
  };
}

class ReceiptLine {
  ReceiptLine({
    required this.name,
    required this.quantity,
    required this.totalPrice,
    required this.isFood,
    required this.nutritionStatus,
    required this.confidence,
    this.unitPrice,
    this.estimatedCalories,
  });

  final String name;
  final double quantity;
  final double? unitPrice;
  final double totalPrice;
  final bool isFood;
  final double? estimatedCalories;
  final String nutritionStatus;
  final double confidence;

  factory ReceiptLine.fromJson(Map<String, dynamic> json) => ReceiptLine(
    name: json['name'] as String? ?? 'Невідомий товар',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
    unitPrice: (json['unit_price'] as num?)?.toDouble(),
    totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
    isFood: json['is_food'] as bool? ?? false,
    estimatedCalories: (json['estimated_calories'] as num?)?.toDouble(),
    nutritionStatus: json['nutrition_status'] as String? ?? 'needs_label',
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    'is_food': isFood,
    'estimated_calories': estimatedCalories,
    'nutrition_status': nutritionStatus,
    'confidence': confidence,
  };
}

class ReceiptScanResult {
  ReceiptScanResult({
    required this.storeName,
    required this.currency,
    required this.total,
    required this.category,
    required this.items,
    required this.needsLabel,
    required this.note,
    required this.confidence,
    this.receiptDate,
  });

  final String storeName;
  final String? receiptDate;
  final String currency;
  final double total;
  final String category;
  final List<ReceiptLine> items;
  final List<String> needsLabel;
  final String note;
  final double confidence;

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) =>
      ReceiptScanResult(
        storeName: json['store_name'] as String? ?? 'Покупка',
        receiptDate: json['receipt_date'] as String?,
        currency: json['currency'] as String? ?? 'UAH',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        category: json['category'] as String? ?? 'Продукти',
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => ReceiptLine.fromJson(item as Map<String, dynamic>))
            .toList(),
        needsLabel: (json['needs_label'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
        note: json['note'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      );
}

class LabelScanResult {
  LabelScanResult({
    required this.name,
    required this.brand,
    required this.variant,
    required this.barcode,
    required this.sourceText,
    required this.missingFields,
    required this.note,
    required this.confidence,
    this.packageGrams,
    this.kcalPer100,
    this.proteinPer100,
    this.fatPer100,
    this.carbsPer100,
  });

  final String name;
  final String brand;
  final String variant;
  final String barcode;
  final double? packageGrams;
  final double? kcalPer100;
  final double? proteinPer100;
  final double? fatPer100;
  final double? carbsPer100;
  final String sourceText;
  final List<String> missingFields;
  final String note;
  final double confidence;

  bool get hasNutrition => kcalPer100 != null && kcalPer100! > 0;

  factory LabelScanResult.fromJson(Map<String, dynamic> json) =>
      LabelScanResult(
        name: json['name'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        variant: json['variant'] as String? ?? '',
        barcode: json['barcode'] as String? ?? '',
        packageGrams: (json['package_grams'] as num?)?.toDouble(),
        kcalPer100: (json['kcal_per_100'] as num?)?.toDouble(),
        proteinPer100: (json['protein_per_100'] as num?)?.toDouble(),
        fatPer100: (json['fat_per_100'] as num?)?.toDouble(),
        carbsPer100: (json['carbs_per_100'] as num?)?.toDouble(),
        sourceText: json['source_text'] as String? ?? '',
        missingFields: (json['missing_fields'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
        note: json['note'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      );
}

class AssistantAction {
  AssistantAction({
    required this.kind,
    required this.title,
    required this.name,
    required this.category,
    this.amount,
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
  });

  final String kind;
  final String title;
  final String name;
  final String category;
  final double? amount;
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;

  factory AssistantAction.fromJson(Map<String, dynamic> json) =>
      AssistantAction(
        kind: json['kind'] as String? ?? 'none',
        title: json['title'] as String? ?? '',
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble(),
        calories: (json['calories'] as num?)?.toDouble(),
        protein: (json['protein'] as num?)?.toDouble(),
        fat: (json['fat'] as num?)?.toDouble(),
        carbs: (json['carbs'] as num?)?.toDouble(),
      );
}

class AssistantReply {
  AssistantReply({
    required this.message,
    required this.actions,
    required this.quickReplies,
  });

  final String message;
  final List<AssistantAction> actions;
  final List<String> quickReplies;

  factory AssistantReply.fromJson(Map<String, dynamic> json) => AssistantReply(
    message:
        json['message'] as String? ??
        'Я не зміг сформувати відповідь. Спробуй ще раз.',
    actions: (json['actions'] as List<dynamic>? ?? const [])
        .map((item) => AssistantAction.fromJson(item as Map<String, dynamic>))
        .where((item) => item.kind != 'none')
        .toList(),
    quickReplies: (json['quick_replies'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(),
  );
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

List<T> decodeList<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw == null || raw.isEmpty) return [];
  return (jsonDecode(raw) as List<dynamic>)
      .map((item) => fromJson(item as Map<String, dynamic>))
      .toList();
}

Map<String, dynamic> decodeObject(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  return jsonDecode(raw) as Map<String, dynamic>;
}
