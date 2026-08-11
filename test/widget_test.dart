import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:zrobleno/app_store.dart';
import 'package:zrobleno/main.dart';

void main() {
  testWidgets('Zrobleno opens the game-styled daily quests', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('uk');
    final store = await AppStore.load();

    await tester.pumpWidget(ZroblenoApp(store: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('ZROBLENO'), findsOneWidget);
    expect(find.text('СВІТ СИНИЧКИ'), findsOneWidget);
    expect(find.text('ЩОДЕННІ ПРИГОДИ'), findsOneWidget);
    expect(find.text('Випити ранкові таблетки'), findsOneWidget);
    expect(find.text('Випити вечірні таблетки'), findsOneWidget);
  });
}
