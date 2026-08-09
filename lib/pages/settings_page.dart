import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.store, super.key});

  final AppStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ReminderSettings draft;

  @override
  void initState() {
    super.initState();
    final source = widget.store.reminders;
    draft = ReminderSettings(
      morningEnabled: source.morningEnabled,
      morningHour: source.morningHour,
      morningMinute: source.morningMinute,
      eveningEnabled: source.eveningEnabled,
      eveningHour: source.eveningHour,
      eveningMinute: source.eveningMinute,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Нагадування'),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const Text(
              'Ліки',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.wb_sunny_outlined, color: sunYellow),
                    title: const Text('Ранкове нагадування'),
                    subtitle: Text(_time(draft.morningHour, draft.morningMinute)),
                    value: draft.morningEnabled,
                    onChanged: (value) =>
                        setState(() => draft.morningEnabled = value),
                  ),
                  ListTile(
                    enabled: draft.morningEnabled,
                    title: const Text('Змінити час'),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => _pickTime(true),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.nights_stay_outlined, color: purple),
                    title: const Text('Вечірнє нагадування'),
                    subtitle: Text(_time(draft.eveningHour, draft.eveningMinute)),
                    value: draft.eveningEnabled,
                    onChanged: (value) =>
                        setState(() => draft.eveningEnabled = value),
                  ),
                  ListTile(
                    enabled: draft.eveningEnabled,
                    title: const Text('Змінити час'),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => _pickTime(false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Увімкнути й зберегти'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _test,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Надіслати тестове сповіщення'),
            ),
            const SizedBox(height: 18),
            const Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Icon(Icons.phone_android, color: orange),
                title: Text('Для Poco / Xiaomi'),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Якщо сповіщення запізнюються, дозволь Zrobleno автозапуск і роботу без обмеження батареї в налаштуваннях MIUI.',
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _pickTime(bool morning) async {
    final initial = TimeOfDay(
      hour: morning ? draft.morningHour : draft.eveningHour,
      minute: morning ? draft.morningMinute : draft.eveningMinute,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (!mounted || picked == null) return;
    setState(() {
      if (morning) {
        draft.morningHour = picked.hour;
        draft.morningMinute = picked.minute;
      } else {
        draft.eveningHour = picked.hour;
        draft.eveningMinute = picked.minute;
      }
    });
  }

  Future<void> _save() async {
    widget.store.updateReminderSettings(draft);
    final granted = await NotificationService.instance.requestPermission();
    await NotificationService.instance.sync(
      draft,
      morningTaken: widget.store.morningMedicine,
      eveningTaken: widget.store.eveningMedicine,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Нагадування збережено.'
              : 'Час збережено. Перевір дозвіл на сповіщення Android.',
        ),
      ),
    );
  }

  Future<void> _test() async {
    await NotificationService.instance.requestPermission();
    await NotificationService.instance.showTest();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Тестове сповіщення надіслано.')),
    );
  }

  String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
