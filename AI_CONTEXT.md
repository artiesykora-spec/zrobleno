# Zrobleno — AI Context File 🤖

> **Призначення:** надати AI-асистенту (Claude, ChatGPT, Copilot) повний контекст про проєкт за один запит. Просто прикріпіть цей файл на початку розмови.

---

## 🎯 Quick Summary

- **Проєкт:** Zrobleno — todo/notes застосунок для Android та iOS
- **Фреймворк:** Flutter 3.44 + Dart
- **Стан:** v1.0.0 — робочий APK зібрано, працює на пристрої
- **Розробка:** GitHub Codespaces (хмарна IDE), без локального ПК
- **Користувач:** розробляє з мобільного телефону
- **Репозиторій:** github.com/artiesykora-spec/zrobleno

---

## 👤 Профіль користувача (важливо!)

- **Рівень:** початківець у Flutter/Dart
- **Інструменти:** тільки мобільний телефон (Android, Chrome browser)
- **IDE:** GitHub Codespaces у браузері
- **Мова спілкування:** українська
- **Стиль навчання:** покрокові інструкції зі скріншотами

### ❗ Як AI має відповідати:
1. Короткі повідомлення — мобільний екран маленький
2. Одна команда за раз
3. Точні інструкції — "натисніть це", "виберіть те"
4. Українською мовою
5. Просити скріншоти для перевірки
6. Не давати теорії — одразу до діла
7. Враховувати що Codespace перезапускається

---

## 🛠 Технічний стек

```yaml
dependencies:
  flutter: sdk: flutter
  flutter_localizations: sdk: flutter
  cupertino_icons: ^1.0.6
  sqflite: ^2.3.0
  path: ^1.9.0
  path_provider: ^2.1.2
  provider: ^6.1.1
  flutter_quill: ^11.5.1    # УВАГА: API змінився в 11.x
  intl: ^0.20.2             # НЕ ^0.19.0 — конфлікт!
  uuid: ^4.3.3
zrobleno/
├── lib/
│   ├── main.dart              # Entry + MultiProvider
│   ├── theme.dart             # AppTheme (#009688 teal)
│   ├── models/
│   │   ├── task.dart          # Task + TaskPriority
│   │   ├── category.dart
│   │   └── app_settings.dart
│   ├── services/
│   │   ├── database_service.dart
│   │   └── settings_service.dart
│   ├── providers/
│   │   ├── task_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── task_edit_screen.dart
│   │   ├── categories_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/
│       ├── task_tile.dart
│       └── filter_bar.dart
├── android/
└── pubspec.yaml
// ❌ Старий:
QuillSimpleToolbar(configurations: const QuillSimpleToolbarConfigurations(...))

// ✅ Новий:
QuillSimpleToolbar(config: const QuillSimpleToolbarConfig(...))
export JAVA_HOME=$HOME/jdk21
export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$HOME/flutter/bin
org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=512m
android.useAndroidX=true
android.enableJetifier=true
Text('#' + t)  // ✅
Text('#$t')    // ❌ конфлікт з bash
Document.fromJson(jsonDecode(json) as List)  // НЕ as List<dynamic>
export JAVA_HOME=$HOME/jdk21
export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$HOME/flutter/bin
flutter --version
cd /workspaces/zrobleno
flutter pub get
flutter build apk --release
flutter build appbundle --release
git add . && git commit -m "опис" && git push
cat > lib/file.dart << 'ENDOFFILE'
// код
ENDOFFILE
sed -i 's/old/new/g' lib/file.dart
static const Color seed = Color(0xFF009688); // Teal

static const _palette = [
  0xFF009688, 0xFF4CAF50, 0xFF2196F3, 0xFF9C27B0,
  0xFFFF9800, 0xFFF44336, 0xFF795548, 0xFF607D8B,
];

// Пріоритети:
// high   → Colors.red.shade400
// medium → Colors.orange.shade400
// low    → Colors.blue.shade300
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  plainDescription TEXT,
  isDone INTEGER NOT NULL,
  isPinned INTEGER NOT NULL,
  priority INTEGER NOT NULL,
  categoryId TEXT,
  tags TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
);

CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color INTEGER NOT NULL
);

CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
---

## Як зберегти:

**Спосіб 1: На GitHub** (рекомендую)
1. Зайдіть у репозиторій `zrobleno`
2. **+** → **Create new file**
3. Назва: `AI_CONTEXT.md`
4. Вставте текст вище
5. **Commit changes**

**Спосіб 2: На телефон**
Виділіть текст вище → копіювати → вставте у будь-який нотатник (Google Keep, Notes)

Готово? 📝
