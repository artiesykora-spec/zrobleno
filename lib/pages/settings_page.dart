import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.store, super.key});

  final AppStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ReminderSettings draft;
  late final TextEditingController aiEndpoint;
  late final TextEditingController aiToken;
  late final TextEditingController calorieGoal;
  late bool syncGoogleSheets;
  bool testingAi = false;
  bool showToken = false;

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
    aiEndpoint = TextEditingController(text: widget.store.aiSettings.endpoint);
    aiToken = TextEditingController(text: widget.store.aiSettings.appToken);
    calorieGoal = TextEditingController(
      text: widget.store.dailyCalorieGoal.toString(),
    );
    syncGoogleSheets = widget.store.aiSettings.syncGoogleSheets;
  }

  @override
  void dispose() {
    aiEndpoint.dispose();
    aiToken.dispose();
    calorieGoal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Налаштування'),
      backgroundColor: Colors.transparent,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const Text(
          'AI та Google Sheets',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security_outlined, color: green),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Ключ OpenAI зберігається у Google Apps Script, а не всередині APK.',
                        style: TextStyle(height: 1.35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: aiEndpoint,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'URL вебзастосунку Apps Script',
                    hintText: 'https://script.google.com/macros/s/…/exec',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: aiToken,
                  obscureText: !showToken,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Особистий токен Zrobleno',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => showToken = !showToken),
                      icon: Icon(
                        showToken
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: calorieGoal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Моя денна ціль, ккал',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Записувати підтверджене в Google Sheets'),
                  subtitle: const Text(
                    'Чеки, продукти та їжа — тільки після твого підтвердження.',
                  ),
                  value: syncGoogleSheets,
                  onChanged: (value) =>
                      setState(() => syncGoogleSheets = value),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saveAi,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Зберегти'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: testingAi ? null : _testAi,
                        icon: testingAi
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.wifi_tethering),
                        label: const Text('Перевірити'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Звуки',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_rounded, color: gameMint),
                title: const Text('Звуки в застосунку'),
                subtitle: const Text(
                  'Квести, збереження, нагороди та ранковий ритуал.',
                ),
                value: widget.store.soundEnabled,
                onChanged: (value) => setState(
                  () => widget.store.updateSoundEnabled(value),
                ),
              ),
              ListTile(
                enabled: widget.store.soundEnabled,
                leading: const Icon(Icons.music_note_rounded, color: sunYellow),
                title: const Text('Прослухати звук нагороди'),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: widget.store.soundEnabled
                    ? () => SoundService.instance.play(AppSound.rewardUnlock)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ліки',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.wb_sunny_outlined,
                  color: sunYellow,
                ),
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
                secondary: const Icon(
                  Icons.nights_stay_outlined,
                  color: purple,
                ),
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
    SoundService.instance.play(AppSound.actionConfirm);
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

  void _saveAi() {
    final goal = int.tryParse(calorieGoal.text.trim());
    widget.store.updateAiSettings(
      AiSettings(
        endpoint: aiEndpoint.text.trim(),
        appToken: aiToken.text.trim(),
        syncGoogleSheets: syncGoogleSheets,
      ),
    );
    if (goal != null) widget.store.updateDailyCalorieGoal(goal);
    SoundService.instance.play(AppSound.actionConfirm);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Налаштування AI збережено.')));
  }

  Future<void> _testAi() async {
    _saveAi();
    if (!widget.store.aiSettings.configured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заповни URL і токен.')));
      return;
    }
    setState(() => testingAi = true);
    try {
      final message = await AiService(widget.store.aiSettings).health();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on AiServiceException catch (error) {
      SoundService.instance.play(AppSound.softError);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => testingAi = false);
    }
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
