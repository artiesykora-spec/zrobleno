import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_store.dart';
import '../models.dart';
import '../services/ai_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'settings_page.dart';

enum _ScanKind { receipt, label }

const _receiptCategories = [
  'Їжа',
  'Домашні тварини',
  'Побут',
  'Здоров’я',
  'Транспорт',
  'Одяг',
  'Розваги',
  'Інше',
];

class ScannerPage extends StatefulWidget {
  const ScannerPage({required this.store, required this.onSaved, super.key});

  final AppStore store;
  final VoidCallback onSaved;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  XFile? image;
  bool working = false;
  _ScanKind kind = _ScanKind.receipt;
  String workingText = '';

  Future<void> pick(ImageSource source) async {
    if (!widget.store.aiSettings.configured) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SettingsPage(store: widget.store),
        ),
      );
      if (!mounted || !widget.store.aiSettings.configured) return;
    }

    final selected = await ImagePicker().pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 2000,
    );
    if (selected == null || !mounted) return;
    setState(() {
      image = selected;
      working = true;
      workingText = kind == _ScanKind.receipt
          ? 'Читаю магазин, товари й суми…'
          : 'Читаю калорії та БЖВ з етикетки…';
    });

    try {
      final service = AiService(widget.store.aiSettings);
      if (kind == _ScanKind.receipt) {
        final result = await service.analyzeReceipt(selected.path);
        if (!mounted) return;
        widget.store.savePendingReceipt(result, selected.path);
        final saved = await _reviewReceipt(result, selected.path);
        if (saved && mounted) widget.onSaved();
      } else {
        final result = await service.analyzeLabel(selected.path);
        if (!mounted) return;
        await _reviewLabel(result);
      }
    } on AiServiceException catch (error) {
      SoundService.instance.play(AppSound.softError);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
        children: [
          const GradientTitle('AI-сканер'),
          const SizedBox(height: 8),
          const Text(
            'Фото справді аналізується: чек перетворюється на витрату й список товарів, а етикетка — на точну картку продукту.',
            style: TextStyle(color: Colors.white60, height: 1.4),
          ),
          const SizedBox(height: 18),
          if (widget.store.pendingReceipt != null) ...[
            _PendingReceiptCard(
              storeName: widget.store.pendingReceipt!.storeName,
              itemCount: widget.store.pendingReceipt!.items.length,
              onContinue: _continuePendingReceipt,
              onDiscard: _discardPendingReceipt,
            ),
            const SizedBox(height: 18),
          ],
          SegmentedButton<_ScanKind>(
            segments: const [
              ButtonSegment(
                value: _ScanKind.receipt,
                icon: Icon(Icons.receipt_long_outlined),
                label: Text('Чек'),
              ),
              ButtonSegment(
                value: _ScanKind.label,
                icon: Icon(Icons.local_fire_department_outlined),
                label: Text('Етикетка'),
              ),
            ],
            selected: {kind},
            onSelectionChanged:
                working ? null : (value) => setState(() => kind = value.first),
          ),
          const SizedBox(height: 18),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: panel,
              border: Border.all(
                color: image == null ? const Color(0xFF33333A) : green,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: image == null
                ? _EmptyScanner(kind: kind)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(image!.path), fit: BoxFit.cover),
                      if (working)
                        Container(
                          color: Colors.black.withValues(alpha: .72),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    workingText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: working ? null : () => pick(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                kind == _ScanKind.receipt
                    ? 'Сфотографувати чек'
                    : 'Сфотографувати етикетку',
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: working ? null : () => pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Padding(
              padding: EdgeInsets.all(15),
              child: Text('Обрати з галереї'),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                widget.store.aiSettings.configured
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: widget.store.aiSettings.configured ? green : orange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.store.aiSettings.configured
                      ? 'AI підключено. Перед збереженням ти перевіряєш результат.'
                      : 'AI ще не підключено — відкриються налаштування.',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ],
      );

  Future<void> _continuePendingReceipt() async {
    final receipt = widget.store.pendingReceipt;
    if (receipt == null) return;
    final saved = await _reviewReceipt(
      receipt,
      widget.store.pendingReceiptPath,
    );
    if (saved && mounted) widget.onSaved();
    if (mounted) setState(() {});
  }

  Future<void> _discardPendingReceipt() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити чернетку?'),
        content: const Text(
          'Розпізнаний чек і внесені виправлення буде втрачено.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Залишити'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    if (discard != true) return;
    widget.store.clearPendingReceipt();
    if (mounted) setState(() {});
  }

  Future<bool> _reviewReceipt(
    ReceiptScanResult result,
    String receiptPath,
  ) async {
    final title = TextEditingController(text: result.storeName);
    final amount = TextEditingController(
      text: result.total > 0 ? result.total.toStringAsFixed(2) : '',
    );
    final drafts = result.items.map(_ReceiptItemDraft.fromLine).toList();
    Expense? saved;
    ReceiptScanResult? reviewedReceipt;

    ReceiptScanResult buildReview() {
      final items = drafts.map((draft) => draft.toReceiptLine()).toList();
      final categories = items
          .map((item) => item.expenseCategory)
          .where((value) => value.isNotEmpty)
          .toSet();
      final receiptCategory = categories.length == 1
          ? categories.single
          : 'Змішаний чек';
      final needsLabel = items
          .where(
            (item) =>
                item.trackNutrition && item.nutritionSource == 'label',
          )
          .map((item) => item.name)
          .toList();
      return result.copyWith(
        storeName: title.text.trim(),
        total: double.tryParse(amount.text.trim().replaceAll(',', '.')),
        category: receiptCategory,
        items: items,
        needsLabel: needsLabel,
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            0,
            18,
            MediaQuery.viewInsetsOf(context).bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'AI прочитав чек',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _Confidence(value: result.confidence),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Перевір назви, призначення товарів і суму. Нечіткі скорочення можна виправити вручну.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Магазин / опис',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Сума, ₴'),
                ),
                if (result.receiptDate != null ||
                    result.receiptNumber.isNotEmpty ||
                    result.paymentMethod.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (result.receiptDate != null)
                        _ReceiptMetaChip(
                          icon: Icons.calendar_today_outlined,
                          text: result.receiptDate!,
                        ),
                      if (result.receiptNumber.isNotEmpty)
                        _ReceiptMetaChip(
                          icon: Icons.receipt_outlined,
                          text: 'Чек № ${result.receiptNumber}',
                        ),
                      if (result.paymentMethod.isNotEmpty)
                        _ReceiptMetaChip(
                          icon: Icons.credit_card_outlined,
                          text: result.paymentMethod,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Позиції · ${result.items.length}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                ...List.generate(
                  drafts.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReceiptItemEditor(
                      index: index,
                      draft: drafts[index],
                      onChanged: () => setSheetState(() {}),
                    ),
                  ),
                ),
                if (drafts.any(
                  (item) =>
                      item.trackNutrition && item.nutritionSource == 'label',
                )) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: orange.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: orange.withValues(alpha: .35)),
                    ),
                    child: const Text(
                      'Етикетка потрібна лише для позначених товарів із режимом «Фото етикетки». Корм для тварин і побутові товари в харчування не потрапляють.',
                      style: TextStyle(height: 1.35),
                    ),
                  ),
                ],
                if (result.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.note,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Відкласти й продовжити пізніше'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final parsed = double.tryParse(
                        amount.text.trim().replaceAll(',', '.'),
                      );
                      if (title.text.trim().isEmpty ||
                          parsed == null ||
                          parsed <= 0) {
                        return;
                      }
                      reviewedReceipt = buildReview();
                      saved = Expense(
                        id: widget.store.id(),
                        title: title.text.trim(),
                        amount: parsed,
                        category: reviewedReceipt!.category,
                        date:
                            DateTime.tryParse(result.receiptDate ?? '') ??
                            DateTime.now(),
                        receiptPath: receiptPath,
                      );
                      widget.store.saveScannedExpense(
                        saved!,
                        reviewedReceipt!,
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Padding(
                      padding: EdgeInsets.all(13),
                      child: Text('Підтвердити й зберегти'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == null) {
      final pending = buildReview();
      title.dispose();
      amount.dispose();
      widget.store.savePendingReceipt(pending, receiptPath);
      return false;
    }
    title.dispose();
    amount.dispose();
    try {
      await AiService(
        widget.store.aiSettings,
      ).syncExpense(saved!, receipt: reviewedReceipt);
    } on AiServiceException {
      SoundService.instance.play(AppSound.softError);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Витрату збережено локально. Sheets оновимо пізніше.'),
        ),
      );
    }
    return true;
  }

  Future<void> _reviewLabel(LabelScanResult result) async {
    final name = TextEditingController(text: result.name);
    final brand = TextEditingController(text: result.brand);
    final variant = TextEditingController(text: result.variant);
    final barcode = TextEditingController(text: result.barcode);
    final package = TextEditingController(
      text: result.packageGrams?.toStringAsFixed(0) ?? '',
    );
    final kcal = TextEditingController(
      text: result.kcalPer100?.toStringAsFixed(1) ?? '',
    );
    final protein = TextEditingController(
      text: result.proteinPer100?.toStringAsFixed(1) ?? '',
    );
    final fat = TextEditingController(
      text: result.fatPer100?.toStringAsFixed(1) ?? '',
    );
    final carbs = TextEditingController(
      text: result.carbsPer100?.toStringAsFixed(1) ?? '',
    );
    var verified = false;
    Product? saved;

    double? number(TextEditingController controller) =>
        double.tryParse(controller.text.trim().replaceAll(',', '.'));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            0,
            18,
            MediaQuery.viewInsetsOf(context).bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'AI прочитав етикетку',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _Confidence(value: result.confidence),
                  ],
                ),
                if (result.missingFields.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Не бачу: ${result.missingFields.join(', ')}. Можна дописати вручну або зробити інше фото.',
                    style: const TextStyle(color: orange, height: 1.35),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Назва *'),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: brand,
                        decoration: const InputDecoration(labelText: 'Бренд'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        controller: variant,
                        decoration: const InputDecoration(labelText: 'Варіант'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                TextField(
                  controller: barcode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Штрихкод'),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        controller: package,
                        label: 'Вага пачки, г',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _NumberField(
                        controller: kcal,
                        label: 'ккал / 100 г *',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(controller: protein, label: 'Білки'),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _NumberField(controller: fat, label: 'Жири'),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _NumberField(controller: carbs, label: 'Вугл.'),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Я звірив дані з фото'),
                  subtitle: const Text(
                    'AI може переплутати кому, порцію або значення на 100 г.',
                  ),
                  value: verified,
                  onChanged: (value) => setSheetState(() => verified = value),
                ),
                if (result.note.isNotEmpty)
                  Text(
                    result.note,
                    style: const TextStyle(color: Colors.white54),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final calories = number(kcal);
                      if (name.text.trim().isEmpty ||
                          calories == null ||
                          calories <= 0) {
                        return;
                      }
                      saved = Product(
                        id: widget.store.id(),
                        name: name.text.trim(),
                        brand: brand.text.trim(),
                        variant: variant.text.trim(),
                        barcode: barcode.text.trim(),
                        packageGrams: number(package),
                        kcalPer100: calories,
                        proteinPer100: number(protein) ?? 0,
                        fatPer100: number(fat) ?? 0,
                        carbsPer100: number(carbs) ?? 0,
                        source: 'AI з етикетки',
                        verified: verified,
                      );
                      widget.store.upsertProduct(saved!);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Padding(
                      padding: EdgeInsets.all(13),
                      child: Text('Зберегти картку продукту'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    for (final controller in [
      name,
      brand,
      variant,
      barcode,
      package,
      kcal,
      protein,
      fat,
      carbs,
    ]) {
      controller.dispose();
    }
    if (saved == null) return;
    try {
      await AiService(widget.store.aiSettings).syncProduct(saved!);
    } on AiServiceException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Продукт збережено локально. Sheets оновимо пізніше.'),
        ),
      );
    }
  }
}

class _PendingReceiptCard extends StatelessWidget {
  const _PendingReceiptCard({
    required this.storeName,
    required this.itemCount,
    required this.onContinue,
    required this.onDiscard,
  });

  final String storeName;
  final int itemCount;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) => Card(
    color: sunYellow.withValues(alpha: .13),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: sunYellow),
              SizedBox(width: 8),
              Text(
                'НЕЗАВЕРШЕНИЙ ЧЕК',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text('$storeName · $itemCount позицій'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onContinue,
                  child: const Text('Продовжити'),
                ),
              ),
              IconButton(
                tooltip: 'Видалити чернетку',
                onPressed: onDiscard,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ReceiptMetaChip extends StatelessWidget {
  const _ReceiptMetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: gameMint),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class _ReceiptItemDraft {
  _ReceiptItemDraft.fromLine(this.original)
    : name = original.name,
      consumerType = original.consumerType,
      expenseCategory = _receiptCategories.contains(original.expenseCategory)
          ? original.expenseCategory
          : 'Інше',
      subcategory = original.subcategory,
      barcode = original.barcode,
      trackNutrition = original.trackNutrition,
      nutritionSource = original.nutritionSource;

  final ReceiptLine original;
  String name;
  String consumerType;
  String expenseCategory;
  String subcategory;
  String barcode;
  bool trackNutrition;
  String nutritionSource;

  ReceiptLine toReceiptLine() => original.copyWith(
    name: name.trim().isEmpty ? original.name : name.trim(),
    consumerType: consumerType,
    expenseCategory: expenseCategory,
    subcategory: subcategory.trim(),
    barcode: barcode.trim(),
    trackNutrition: trackNutrition,
    nutritionSource: trackNutrition ? nutritionSource : 'none',
  );
}

class _ReceiptItemEditor extends StatelessWidget {
  const _ReceiptItemEditor({
    required this.index,
    required this.draft,
    required this.onChanged,
  });

  final int index;
  final _ReceiptItemDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: Colors.white.withValues(alpha: .045),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ПОЗИЦІЯ ${index + 1}',
                  style: const TextStyle(
                    color: gameMint,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${draft.original.totalPrice.toStringAsFixed(2)} ₴',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('receipt-name-$index-${draft.original.rawName}'),
            initialValue: draft.name,
            decoration: const InputDecoration(labelText: 'Назва товару'),
            onChanged: (value) => draft.name = value,
          ),
          if (draft.original.rawName.isNotEmpty &&
              draft.original.rawName != draft.name) ...[
            const SizedBox(height: 5),
            Text(
              'У чеку: ${draft.original.rawName}',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            initialValue: const [
              'human_food',
              'pet',
              'non_food',
            ].contains(draft.consumerType)
                ? draft.consumerType
                : 'non_food',
            decoration: const InputDecoration(labelText: 'Призначення'),
            items: const [
              DropdownMenuItem(
                value: 'human_food',
                child: Text('Їжа для мене'),
              ),
              DropdownMenuItem(
                value: 'pet',
                child: Text('Для котів / тварин'),
              ),
              DropdownMenuItem(
                value: 'non_food',
                child: Text('Не харчовий товар'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              draft.consumerType = value;
              if (value == 'pet') {
                draft.expenseCategory = 'Домашні тварини';
                draft.trackNutrition = false;
                draft.nutritionSource = 'none';
              } else if (value == 'human_food') {
                draft.expenseCategory = 'Їжа';
                draft.trackNutrition = true;
                if (draft.nutritionSource == 'none') {
                  draft.nutritionSource = 'label';
                }
              } else {
                draft.trackNutrition = false;
                draft.nutritionSource = 'none';
              }
              onChanged();
            },
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            initialValue: draft.expenseCategory,
            decoration: const InputDecoration(labelText: 'Категорія витрати'),
            items: _receiptCategories
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              draft.expenseCategory = value;
              onChanged();
            },
          ),
          const SizedBox(height: 9),
          TextFormField(
            initialValue: draft.subcategory,
            decoration: const InputDecoration(
              labelText: 'Підкатегорія',
              hintText: 'Напр. корм для котів, локшина, побутова хімія',
            ),
            onChanged: (value) => draft.subcategory = value,
          ),
          const SizedBox(height: 9),
          TextFormField(
            initialValue: draft.barcode,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Штрихкод товару',
              hintText: 'Якщо надрукований у чеку',
            ),
            onChanged: (value) => draft.barcode = value,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Рахувати у моєму харчуванні'),
            subtitle: Text(
              draft.consumerType == 'pet'
                  ? 'Корм для тварин за замовчуванням не рахується.'
                  : 'Увімкни лише для того, що фактично можеш з’їсти.',
            ),
            value: draft.trackNutrition,
            onChanged: (value) {
              draft.trackNutrition = value ?? false;
              if (!draft.trackNutrition) {
                draft.nutritionSource = 'none';
              } else if (draft.nutritionSource == 'none') {
                draft.nutritionSource = 'label';
              }
              onChanged();
            },
          ),
          if (draft.trackNutrition)
            DropdownButtonFormField<String>(
              initialValue: const [
                'known',
                'reference',
                'label',
              ].contains(draft.nutritionSource)
                  ? draft.nutritionSource
                  : 'label',
              decoration: const InputDecoration(
                labelText: 'Звідки уточнити калорійність',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'known',
                  child: Text('Уже відома з чека'),
                ),
                DropdownMenuItem(
                  value: 'reference',
                  child: Text('Довідкова оцінка AI'),
                ),
                DropdownMenuItem(
                  value: 'label',
                  child: Text('Фото етикетки'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                draft.nutritionSource = value;
                onChanged();
              },
            ),
        ],
      ),
    ),
  );
}

class _EmptyScanner extends StatelessWidget {
  const _EmptyScanner({required this.kind});

  final _ScanKind kind;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            kind == _ScanKind.receipt
                ? Icons.receipt_long_outlined
                : Icons.local_fire_department_outlined,
            size: 72,
            color: purple,
          ),
          const SizedBox(height: 14),
          Text(
            kind == _ScanKind.receipt
                ? 'Розмісти весь чек у кадрі'
                : 'Зніми таблицю калорій та БЖВ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            kind == _ScanKind.receipt
                ? 'Не обрізай підсумкову суму'
                : 'Фото має бути різким і без відблисків',
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      );
}

class _Confidence extends StatelessWidget {
  const _Confidence({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round().clamp(0, 100).toInt();
    final color = value >= .85
        ? green
        : value >= .62
            ? sunYellow
            : orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      );
}
