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
  ReminderSettings reminders = ReminderSettings();
  GameState game = GameState();
  Set<String> rewardedActions = {};
  bool morningMedicine = false;
  bool eveningMedicine = false;
  String medicineDay = '';

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs)
      ..tasks = decodeList(prefs.getString('tasks'), TodoItem.fromJson)
      ..expenses = decodeList(prefs.getString('expenses'), Expense.fromJson)
      ..foods = decodeList(prefs.getString('foods'), FoodEntry.fromJson)
      ..products = decodeList(prefs.getString('products'), Product.fromJson)
      ..reminders = ReminderSettings.fromJson(
        decodeObject(prefs.getString('reminders')),
      )
      ..game = GameState.fromJson(decodeObject(prefs.getString('game')))
      ..rewardedActions =
          (prefs.getStringList('rewardedActions') ?? <String>[]).toSet()
      ..medicineDay = prefs.getString('medicineDay') ?? ''
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

  String get assistantMessage {
    final calories = foods
        .where((food) => isToday(food.date))
        .fold<double>(0, (sum, food) => sum + food.calories)
        .round();
    if (!morningMedicine && DateTime.now().hour >= reminders.morningHour) {
      return 'Доброго ранку! Таблетки ще чекають на свою галочку.';
    }
    if (calories == 0) {
      return 'Занесімо першу їжу — я почну рахувати день разом з тобою.';
    }
    return 'Сьогодні вже $calories ккал. Рухаємося спокійно, крок за кроком.';
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
      _prefs.setString('reminders', jsonEncode(reminders.toJson())),
      _prefs.setString('game', jsonEncode(game.toJson())),
      _prefs.setStringList('rewardedActions', rewardedActions.toList()),
      _prefs.setString('medicineDay', medicineDay),
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

  void updateReminderSettings(ReminderSettings value) {
    reminders = value;
    changed();
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

  void addFoodFromProduct(Product product, double grams) {
    final factor = grams / 100;
    foods.add(
      FoodEntry(
        id: id(),
        name: product.displayName,
        calories: product.kcalPer100 * factor,
        protein: product.proteinPer100 * factor,
        fat: product.fatPer100 * factor,
        carbs: product.carbsPer100 * factor,
        date: DateTime.now(),
        productId: product.id,
        amountGrams: grams,
      ),
    );
    _reward('food:${foods.last.id}', seeds: 1, xp: 3);
    changed();
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
