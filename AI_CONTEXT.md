# Zrobleno — контекст для розробки

## Проєкт

- Репозиторій: `artiesykora-spec/zrobleno`
- Платформа: Flutter / Android, український інтерфейс
- Активна тестова гілка: `codex/-mvp-android-zrobleno`
- Користувач працює переважно з Android-телефона, тому інструкції мають бути короткими й покроковими.
- Поточна версія: `1.2.0+3`

## Поточна архітектура

- `lib/app_store.dart` — локальний стан і SharedPreferences.
- `lib/models.dart` — справи, витрати, їжа, продукти, AI-відповіді та стан гри.
- `lib/pages/scanner_page.dart` — реальний AI-аналіз чеків і харчових етикеток.
- `lib/pages/assistant_page.dart` — контекстний чат із діями, які користувач підтверджує вручну.
- `lib/pages/world_page.dart` — анімований pixel-art світ.
- `lib/widgets/pixel_bird.dart` — кадровий рендер PNG-атласів персонажів.
- `lib/services/ai_service.dart` — HTTPS-клієнт до особистого Apps Script.
- `backend/apps-script/Code.gs` — безпечний шлюз OpenAI + синхронізація Google Sheets.
- `assets/game/` — растрові 16-бітні атласи й фон; не SVG.

## Важливі правила продукту

1. Не видавати ручне введення за OCR або AI.
2. Не вбудовувати `OPENAI_API_KEY` в APK чи GitHub.
3. Не вигадувати калорії з чека: якщо етикетки немає, просити її фото.
4. Відрізняти «купив» від «з’їв».
5. Будь-який AI-запис їжі або витрати потребує підтвердження користувача.
6. Локальне збереження важливіше за мережу: збій Sheets не повинен втрачати запис.
7. Гра підтримує мотивацію без штрафів і скидання прогресу.

## AI-конфігурація

У Google Apps Script Script Properties потрібні:

- `OPENAI_API_KEY`
- `APP_TOKEN`
- `SPREADSHEET_ID`
- необов’язково `OPENAI_MODEL` (стандартно `gpt-4o-mini`)

У застосунок вводяться лише URL розгорнутого Apps Script (`/exec`) та `APP_TOKEN`. Ключ OpenAI залишається на серверній стороні.

## Перевірка перед релізом

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

GitHub Actions виконує ці кроки автоматично та публікує APK як artifact.
