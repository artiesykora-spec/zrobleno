# Zrobleno AI gateway

Google Apps Script виконує три задачі:

1. Тримає `OPENAI_API_KEY` поза Android APK.
2. Аналізує чек або етикетку через OpenAI Responses API з image input та Structured Outputs.
3. Записує лише підтверджені користувачем витрати, товари й їжу в Google Sheets. Повторний запис з тим самим ID оновлюється без дублювання.

## Script Properties

У **Project Settings → Script Properties** додайте:

- `OPENAI_API_KEY` — ключ OpenAI API;
- `APP_TOKEN` — довгий випадковий особистий пароль для Zrobleno;
- `SPREADSHEET_ID` — частина URL таблиці між `/d/` та `/edit`;
- `OPENAI_MODEL` — необов’язково, стандартно `gpt-4o-mini`.

Не вставляйте секрети в `Code.gs` і не комітьте їх у GitHub.

## Перший запуск

1. Створіть Apps Script проєкт.
2. Замініть `Code.gs` і `appsscript.json` файлами з цієї папки.
3. Додайте Script Properties.
4. Запустіть функцію `setupZroblenoSheets` і надайте дозволи.
5. **Deploy → New deployment → Web app**.
6. Execute as: **Me**. Who has access: **Anyone**.
7. Скопіюйте URL, який завершується на `/exec`.
8. У Zrobleno відкрийте **Налаштування → AI та Google Sheets**, вставте URL і значення `APP_TOKEN`, потім натисніть **Перевірити**.

Публічним є лише URL. Запити без правильного `APP_TOKEN` відхиляються, а ключ OpenAI залишається в Script Properties.

## Що перевірити

Після успішної кнопки **Перевірити**:

1. Сфотографуйте короткий чек і звірте магазин, суму та позиції.
2. Підтвердьте витрату й перевірте вкладки `Expenses` та `ReceiptItems`.
3. Сфотографуйте таблицю поживності й перевірте значення саме на 100 г.
4. Напишіть помічниці «Підсумуй мій день».

AI-виклики оплачуються у вашому OpenAI API акаунті. Модель за замовчуванням — економна `gpt-4o-mini`; за потреби її можна змінити через `OPENAI_MODEL` без перевипуску APK.
