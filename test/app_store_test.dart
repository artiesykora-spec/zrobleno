import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zrobleno/app_store.dart';

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
}
