import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

class AppStore extends ChangeNotifier {
  AppStore(this._prefs);

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  List<TodoItem> tasks = [];
  List<Expense> expenses = [];
  List<FoodEntry> foods = [];
  List<Product> products = [];
  List<AssistantMessage> assistantMessages = [];
  ReminderSettings reminders = ReminderSettings();
  AiSettings aiSettings = AiSettings();
  GameState game = GameState();
  Set<String> rewardedActions = {};
  Set<String> dailyQuestDone = {};
  bool morningMedicine = false;
  bool eveningMedicine = false;
  String medicineDay = '';
  int dailyCalorieGoal = 1850;

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs)
      ..tasks = decodeList(prefs.getString('tasks'), TodoItem.fromJson)
      ..expenses = decodeList(prefs.getString('expenses'), Expense.fromJson)
      ..foods = decodeList(prefs.getString('foods'), FoodEntry.fromJson)
      ..products = decodeList(prefs.getString('products'), Product.fromJson)
      ..assistantMessages = decodeList(
        prefs.getString('assistantMessages'),
        AssistantMessage.fromJson,
      )
      ..reminders = ReminderSettings.fromJson(
        decodeObject(prefs.getString('reminders')),
      )
      ..aiSettings = AiSettings.fromJson(
        decodeObject(prefs.getString('aiSettings')),
      )
      ..game = GameState.fromJson(decodeObject(prefs.getString('game')))
      ..rewardedActions = (prefs.getStringList('rewardedActions') ?? <String>[])
          .toSet()
      ..dailyQuestDone = (prefs.getStringList('dailyQuestDone') ?? <String>[])
          .toSet()
      ..medicineDay = prefs.getString('medicineDay') ?? ''
      ..dailyCalorieGoal = prefs.getInt('dailyCalorieGoal') ?? 1850
      ..morningMedicine = prefs.getBool('morningMedicine') ?? false
      ..eveningMedicine = prefs.getBool('eveningMedicine') ?? false;
    store._resetMedicineIfNeeded();
    return store;
  }

  String id() => _uuid.v4();

  String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  bool isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  List<FoodEntry> get todayFoods =>
      foods.where((food) => isToday(food.date)).toList();

  double get todayCalories =>
      todayFoods.fold<double>(0, (sum, food) => sum + food.calories);

  double get remainingCalories => dailyCalorieGoal - todayCalories;

  String get assistantMessage {
    final calories = todayCalories.round();
    if (!morningMedicine && DateTime.now().hour >= reminders.morningHour) {
      return 'Доброго ранку! Таблетки ще чекають на свою галочку.';
    }
    if (calories == 0) {
      return 'Занесімо першу їжу — я почну рахувати день разом з тобою.';
    }
    final remaining = remainingCalories.round();
    if (remaining >= 0) {
      return 'Сьогодні $calories ккал. До твоєї цілі ще приблизно $remaining ккал.';
    }
    return 'Сьогодні $calories ккал — на ${remaining.abs()} більше цілі. Без покарань: просто сплануймо наступний прийом їжі.';
  }

  Map<String, dynamic> get assistantContext {
    final todayExpenses = expenses.where((item) => isToday(item.date)).toList();
    final activeTasks = tasks.where((item) => !item.done).take(8).toList();
    return {
      'date': DateTime.now().toIso8601String(),
      'daily_calorie_goal': dailyCalorieGoal,
      'calories_consumed': todayCalories.round(),
      'calories_remaining': remainingCalories.round(),
      'foods_today': todayFoods
          .map(
            (food) => {
              'name': food.name,
              'calories': food.calories.round(),
              'grams': food.amountGrams,
            },
          )
          .toList(),
      'expenses_today': todayExpenses
          .map(
            (expense) => {
              'title': expense.title,
              'amount': expense.amount,
              'category': expense.category,
            },
          )
          .toList(),
      'active_tasks': activeTasks.map((task) => task.title).toList(),
      'medicine': {'morning': morningMedicine, 'evening': eveningMedicine},
      'known_products': products
          .take(30)
          .map(
            (product) => {
              'name': product.displayName,
              'kcal_per_100': product.kcalPer100,
            },
          )
          .toList(),
    };
  }

  void _resetMedicineIfNeeded() {
    if (medicineDay == todayKey) return;
    if (medicineDay.isNotEmpty && (!morningMedicine || !eveningMedicine)) {
      game.wolfMess = true;
    }
    medicineDay = todayKey;
    morningMedicine = false;
    eveningMedicine = false;
    _save();
  }

  Future<void> _save() async {
    await Future.wait([
      _prefs.setString('tasks', encodeList(tasks, (item) => item.toJson())),
      _prefs.setString(
        'expenses',
        encodeList(expenses, (item) => item.toJson()),
      ),
      _prefs.setString('foods', encodeList(foods, (item) => item.toJson())),
      _prefs.setString(
        'products',
        encodeList(products, (item) => item.toJson()),
      ),
      _prefs.setString(
        'assistantMessages',
        encodeList(assistantMessages, (item) => item.toJson()),
      ),
      _prefs.setString('reminders', jsonEncode(reminders.toJson())),
      _prefs.setString('aiSettings', jsonEncode(aiSettings.toJson())),
      _prefs.setString('game', jsonEncode(game.toJson())),
      _prefs.setStringList('rewardedActions', rewardedActions.toList()),
      _prefs.setStringList('dailyQuestDone', dailyQuestDone.toList()),
      _prefs.setString('medicineDay', medicineDay),
      _prefs.setInt('dailyCalorieGoal', dailyCalorieGoal),
      _prefs.setBool('morningMedicine', morningMedicine),
      _prefs.setBool('eveningMedicine', eveningMedicine),
    ]);
  }

  void changed() {
    _save();
    notifyListeners();
  }

  void _reward(String actionId, {int seeds = 2, int xp = 4}) {
    if (!rewardedActions.add(actionId)) return;
    game.seeds += seeds;
    game.xp += xp;
  }

  void toggleTask(TodoItem task, bool value) {
    task.done = value;
    if (value) _reward('task:${task.id}', seeds: 2, xp: 5);
    changed();
  }

  void deleteTask(TodoItem value) {
    tasks.remove(value);
    changed();
  }

  void deleteExpense(Expense value) {
    expenses.remove(value);
    changed();
  }

  void deleteFood(FoodEntry value) {
    foods.remove(value);
    changed();
  }

  void toggleMedicine(bool morning, bool value) {
    if (morning) {
      morningMedicine = value;
    } else {
      eveningMedicine = value;
    }
    if (value) {
      _reward(
        'medicine:$todayKey:${morning ? 'morning' : 'evening'}',
        seeds: 3,
        xp: 6,
      );
    }
    changed();
  }

  String _dailyQuestKey(String questId) => '$todayKey:$questId';

  bool isDailyQuestDone(String questId) =>
      dailyQuestDone.contains(_dailyQuestKey(questId));

  bool get dailyChestClaimed =>
      rewardedActions.contains('daily-chest:$todayKey');

  void toggleDailyQuest(
    String questId,
    bool value, {
    int seeds = 2,
    int xp = 4,
  }) {
    final key = _dailyQuestKey(questId);
    if (value) {
      dailyQuestDone.add(key);
      _reward('daily:$key', seeds: seeds, xp: xp);
    } else {
      dailyQuestDone.remove(key);
    }
    changed();
  }

  void triggerKlaksa() {
    game.wolfMess = true;
    changed();
  }

  void claimDailyChest() {
    _reward('daily-chest:$todayKey', seeds: 10, xp: 18);
    changed();
  }

  void updateReminderSettings(ReminderSettings value) {
    reminders = value;
    changed();
  }

  void updateAiSettings(AiSettings value) {
    aiSettings = value;
    changed();
  }

  void updateDailyCalorieGoal(int value) {
    dailyCalorieGoal = value.clamp(800, 5000).toInt();
    changed();
  }

  AssistantMessage addAssistantMessage(String role, String text) {
    final message = AssistantMessage(
      id: id(),
      role: role,
      text: text.trim(),
      date: DateTime.now(),
    );
    assistantMessages.add(message);
    if (assistantMessages.length > 40) {
      assistantMessages.removeRange(0, assistantMessages.length - 40);
    }
    changed();
    return message;
  }

  void clearAssistantMessages() {
    assistantMessages.clear();
    changed();
  }

  void applyAssistantAction(AssistantAction action) {
    if (action.kind == 'food' &&
        action.name.trim().isNotEmpty &&
        action.calories != null) {
      foods.add(
        FoodEntry(
          id: id(),
          name: action.name.trim(),
          calories: action.calories!,
          protein: action.protein ?? 0,
          fat: action.fat ?? 0,
          carbs: action.carbs ?? 0,
          date: DateTime.now(),
        ),
      );
      _reward('food:${foods.last.id}', seeds: 1, xp: 3);
      changed();
      return;
    }
    if (action.kind == 'expense' &&
        action.name.trim().isNotEmpty &&
        action.amount != null &&
        action.amount! > 0) {
      expenses.add(
        Expense(
          id: id(),
          title: action.name.trim(),
          amount: action.amount!,
          category: action.category.trim().isEmpty ? 'Інше' : action.category,
          date: DateTime.now(),
        ),
      );
      changed();
    }
  }

  void upsertProduct(Product product) {
    final index = products.indexWhere((item) => item.id == product.id);
    product.updatedAt = DateTime.now();
    if (index == -1) {
      products.add(product);
      _reward('product:${product.id}', seeds: 1, xp: 2);
    } else {
      products[index] = product;
    }
    changed();
  }

  void deleteProduct(Product product) {
    products.removeWhere((item) => item.id == product.id);
    changed();
  }

  FoodEntry addFoodFromProduct(Product product, double grams) {
    final factor = grams / 100;
    final food = FoodEntry(
      id: id(),
      name: product.displayName,
      calories: product.kcalPer100 * factor,
      protein: product.proteinPer100 * factor,
      fat: product.fatPer100 * factor,
      carbs: product.carbsPer100 * factor,
      date: DateTime.now(),
      productId: product.id,
      amountGrams: grams,
    );
    foods.add(food);
    _reward('food:${food.id}', seeds: 1, xp: 3);
    changed();
    return food;
  }

  int nestUpgradeCost() => 12 + game.nestLevel * 8;

  int gardenUpgradeCost() => 10 + game.gardenLevel * 10;

  bool upgradeNest() {
    final cost = nestUpgradeCost();
    if (game.seeds < cost || game.nestLevel >= 5) return false;
    game.seeds -= cost;
    game.nestLevel += 1;
    changed();
    return true;
  }

  bool upgradeGarden() {
    final cost = gardenUpgradeCost();
    if (game.seeds < cost || game.gardenLevel >= 5) return false;
    game.seeds -= cost;
    game.gardenLevel += 1;
    changed();
    return true;
  }

  void cleanWolfMess() {
    game.wolfMess = false;
    changed();
  }
}
