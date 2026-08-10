import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../services/ai_service.dart';
import '../theme.dart';
import '../widgets/pixel_bird.dart';
import 'settings_page.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({required this.store, super.key});

  final AppStore store;

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  bool sending = false;
  List<AssistantAction> pendingActions = [];
  List<String> quickReplies = const [
    'Що мені ще можна з’їсти?',
    'Підсумуй мій день',
    'Чи вкладаюся я в калорії?',
  ];

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? preset]) async {
    final text = (preset ?? input.text).trim();
    if (text.isEmpty || sending) return;
    if (!widget.store.aiSettings.configured) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SettingsPage(store: widget.store),
        ),
      );
      if (!mounted || !widget.store.aiSettings.configured) return;
    }

    final history = List<AssistantMessage>.from(widget.store.assistantMessages);
    input.clear();
    widget.store.addAssistantMessage('user', text);
    setState(() {
      sending = true;
      pendingActions = [];
    });
    _scrollToBottom();

    try {
      final reply = await AiService(widget.store.aiSettings).chat(
        message: text,
        context: widget.store.assistantContext,
        history: history,
      );
      widget.store.addAssistantMessage('assistant', reply.message);
      if (!mounted) return;
      setState(() {
        pendingActions = reply.actions;
        if (reply.quickReplies.isNotEmpty) {
          quickReplies = reply.quickReplies;
        }
      });
    } on AiServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => sending = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> applyAction(AssistantAction action) async {
    widget.store.applyAssistantAction(action);
    setState(() => pendingActions.remove(action));
    final service = AiService(widget.store.aiSettings);
    try {
      if (action.kind == 'food' && widget.store.foods.isNotEmpty) {
        await service.syncFood(widget.store.foods.last);
      } else if (action.kind == 'expense' && widget.store.expenses.isNotEmpty) {
        await service.syncExpense(widget.store.expenses.last);
      }
    } on AiServiceException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Локально збережено. Google Sheets синхронізуємо пізніше.',
          ),
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Додано до сьогоднішніх даних.')),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Синичка-помічниця'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Очистити діалог',
            onPressed: widget.store.assistantMessages.isEmpty
                ? null
                : _confirmClear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          IconButton(
            tooltip: 'Налаштування AI',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SettingsPage(store: widget.store),
              ),
            ),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Column(
        children: [
          _DayStatus(store: widget.store),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
              children: [
                if (widget.store.assistantMessages.isEmpty) const _Welcome(),
                ...widget.store.assistantMessages.map(
                  (message) => _MessageBubble(message: message),
                ),
                if (sending)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _TypingBubble(),
                  ),
                if (pendingActions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...pendingActions.map(
                    (action) => _ActionCard(
                      action: action,
                      onApply: () => applyAction(action),
                    ),
                  ),
                ],
                if (!sending && quickReplies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: quickReplies
                        .take(4)
                        .map(
                          (text) => ActionChip(
                            label: Text(text),
                            onPressed: () => send(text),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Наприклад: я з’їв 30 г арахісу…',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                      ),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Надіслати',
                    onPressed: sending ? null : send,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _confirmClear() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистити діалог?'),
        content: const Text(
          'Записи їжі та витрат залишаться. Зникне лише історія розмови.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ні'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Очистити'),
          ),
        ],
      ),
    );
    if (clear == true) widget.store.clearAssistantMessages();
  }
}

class _DayStatus extends StatelessWidget {
  const _DayStatus({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final remaining = store.remainingCalories.round();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: const LinearGradient(
          colors: [Color(0xFF1C3D33), Color(0xFF302253)],
        ),
      ),
      child: Row(
        children: [
          const PixelBird(size: 54),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.todayCalories.round()} / ${store.dailyCalorieGoal} ккал',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  remaining >= 0
                      ? 'Залишок на сьогодні: приблизно $remaining ккал'
                      : 'Понад орієнтир на ${remaining.abs()} ккал',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          PixelBird(size: 96, playful: true),
          SizedBox(height: 8),
          Text(
            'Я бачу твої записи в Zrobleno і можу допомогти спланувати день.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Напиши, що вже їв, що хочеш приготувати або яку покупку розібрати. Нічого не додаю без твого підтвердження.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, height: 1.35),
          ),
        ],
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 305),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: message.isUser
            ? const Color(0xFF245D49)
            : const Color(0xFF202027),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(17),
          topRight: const Radius.circular(17),
          bottomLeft: Radius.circular(message.isUser ? 17 : 4),
          bottomRight: Radius.circular(message.isUser ? 4 : 17),
        ),
        border: Border.all(
          color: message.isUser
              ? const Color(0xFF3C8E70)
              : const Color(0xFF363641),
        ),
      ),
      child: Text(message.text, style: const TextStyle(height: 1.35)),
    ),
  );
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 5),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF202027),
      borderRadius: BorderRadius.circular(17),
    ),
    child: const SizedBox(
      width: 42,
      child: LinearProgressIndicator(minHeight: 3),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.onApply});

  final AssistantAction action;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final value = action.kind == 'food'
        ? '${action.calories?.round() ?? 0} ккал'
        : '${action.amount?.toStringAsFixed(2) ?? '0'} ₴';
    return Card(
      color: const Color(0xFF1A2C26),
      child: ListTile(
        leading: Icon(
          action.kind == 'food' ? Icons.restaurant : Icons.payments_outlined,
          color: green,
        ),
        title: Text(action.title.isEmpty ? action.name : action.title),
        subtitle: Text('${action.name} · $value'),
        trailing: FilledButton(onPressed: onApply, child: const Text('Додати')),
      ),
    );
  }
}
