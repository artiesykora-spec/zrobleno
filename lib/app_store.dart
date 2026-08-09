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
  bool morningMedicine = false;
  bool eveningMedicine = false;
  String medicineDay = '';

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs)
      ..tasks = decodeList(prefs.getString('tasks'), TodoItem.fromJson)
      ..expenses = decodeList(prefs.getString('expenses'), Expense.fromJson)
      ..foods = decodeList(prefs.getString('foods'), FoodEntry.fromJson)
      ..medicineDay = prefs.getString('medicineDay') ?? ''
      ..morningMedicine = prefs.getBool('morningMedicine') ?? false
      ..eveningMedicine = prefs.getBool('eveningMedicine') ?? false;
    store._resetMedicineIfNeeded();
    return store;
  }

  String id() => _uuid.v4();
  String get todayKey { final n = DateTime.now(); return '${n.year}-${n.month}-${n.day}'; }
  bool isToday(DateTime value) { final n = DateTime.now(); return value.year == n.year && value.month == n.month && value.day == n.day; }
  void _resetMedicineIfNeeded() { if (medicineDay != todayKey) { medicineDay = todayKey; morningMedicine = eveningMedicine = false; _save(); } }
  Future<void> _save() async {
    await Future.wait([
      _prefs.setString('tasks', encodeList(tasks, (e) => e.toJson())),
      _prefs.setString('expenses', encodeList(expenses, (e) => e.toJson())),
      _prefs.setString('foods', encodeList(foods, (e) => e.toJson())),
      _prefs.setString('medicineDay', medicineDay),
      _prefs.setBool('morningMedicine', morningMedicine),
      _prefs.setBool('eveningMedicine', eveningMedicine),
    ]);
  }
  void changed() { _save(); notifyListeners(); }
  void deleteTask(TodoItem value) { tasks.remove(value); changed(); }
  void deleteExpense(Expense value) { expenses.remove(value); changed(); }
  void deleteFood(FoodEntry value) { foods.remove(value); changed(); }
  void toggleMedicine(bool morning, bool value) { if (morning) { morningMedicine = value; } else { eveningMedicine = value; } changed(); }
}
