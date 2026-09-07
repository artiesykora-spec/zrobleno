import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zrobleno/app_store.dart';
import 'package:zrobleno/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('daily RPG quests persist and cannot be farmed twice', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    final startingSeeds = store.game.seeds;
    final startingXp = store.game.xp;

    store.toggleDailyQuest('focus', true, seeds: 3, xp: 5);
    expect(store.isDailyQuestDone('focus'), isTrue);
    expect(store.game.seeds, startingSeeds + 3);
    expect(store.game.xp, startingXp + 5);

    store.toggleDailyQuest('focus', false, seeds: 3, xp: 5);
    store.toggleDailyQuest('focus', true, seeds: 3, xp: 5);
    expect(store.game.seeds, startingSeeds + 3);
    expect(store.game.xp, startingXp + 5);
  });

  test('daily chest can only reward once', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    final startingSeeds = store.game.seeds;
    final startingXp = store.game.xp;

    store.claimDailyChest();
    store.claimDailyChest();

    expect(store.dailyChestClaimed, isTrue);
    expect(store.game.seeds, startingSeeds + 10);
    expect(store.game.xp, startingXp + 18);
  });

  test('sound preference defaults on and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();

    expect(store.soundEnabled, isTrue);
    store.updateSoundEnabled(false);
    await Future<void>.delayed(Duration.zero);

    final restored = await AppStore.load();
    expect(restored.soundEnabled, isFalse);
  });

  test('receipt draft survives leaving the scanner', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    final receipt = _testReceipt();

    store.savePendingReceipt(receipt, '/tmp/receipt.jpg');
    await Future<void>.delayed(Duration.zero);

    final restored = await AppStore.load();
    expect(restored.pendingReceipt?.storeName, 'Вигідна покупка');
    expect(restored.pendingReceipt?.items.single.barcode, '4820212460227');
    expect(restored.pendingReceiptPath, '/tmp/receipt.jpg');
  });

  test('confirmed receipt keeps every purchase line with its expense', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    final receipt = _testReceipt();
    final expense = Expense(
      id: 'expense-1',
      title: receipt.storeName,
      amount: receipt.total,
      category: 'Змішаний чек',
      date: DateTime(2026, 9, 7),
    );

    store.saveScannedExpense(expense, receipt);
    await Future<void>.delayed(Duration.zero);

    final restored = await AppStore.load();
    final saved = restored.receiptForExpense('expense-1');
    expect(saved, isNotNull);
    expect(saved!.receipt.items, hasLength(1));
    expect(saved.receipt.items.single.expenseCategory, 'Їжа');
  });
}

ReceiptScanResult _testReceipt() => ReceiptScanResult.fromJson({
  'store_name': 'Вигідна покупка',
  'receipt_date': '2026-09-07',
  'receipt_number': '21310011261',
  'payment_method': 'VISA',
  'receipt_code': '21310011261',
  'currency': 'UAH',
  'total': 26,
  'category': 'Їжа',
  'items': [
    {
      'name': 'Вермішель «Куховар», сметана-цибуля, 50 г',
      'raw_name': 'Вермішель шв приг.негос.Куховар Сметана-цибуля 50г',
      'quantity': 2,
      'unit_price': 13,
      'total_price': 26,
      'is_food': true,
      'estimated_calories': null,
      'nutrition_status': 'needs_label',
      'confidence': .8,
      'consumer_type': 'human_food',
      'expense_category': 'Їжа',
      'subcategory': 'Вермішель швидкого приготування',
      'barcode': '4820212460227',
      'track_nutrition_default': true,
      'nutrition_source': 'label',
    },
  ],
  'needs_label': ['Вермішель «Куховар», сметана-цибуля, 50 г'],
  'note': '',
  'confidence': .8,
});
