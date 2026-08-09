import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:zrobleno/app_store.dart';
import 'package:zrobleno/main.dart';

void main() {
  testWidgets('Zrobleno opens the Today overview', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('uk');
    final store = await AppStore.load();

    await tester.pumpWidget(ZroblenoApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Сьогодні'), findsWidgets);
    expect(find.text('Ліки'), findsOneWidget);
    expect(find.text('Ранкові таблетки'), findsOneWidget);
    expect(find.text('Вечірні таблетки'), findsOneWidget);
  });
}
