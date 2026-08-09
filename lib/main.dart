import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_store.dart';
import 'home.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('uk');
  final store = await AppStore.load();
  runApp(ZroblenoApp(store: store));
}

class ZroblenoApp extends StatelessWidget {
  const ZroblenoApp({required this.store, super.key});
  final AppStore store;
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Zrobleno', debugShowCheckedModeBanner: false, theme: appTheme(), locale: const Locale('uk'),
    supportedLocales: const [Locale('uk')],
    localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    home: Home(store: store),
  );
}
