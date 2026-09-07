/**
 * Zrobleno AI gateway for Google Apps Script.
 *
 * Script properties required before deployment:
 * - OPENAI_API_KEY
 * - APP_TOKEN
 * - SPREADSHEET_ID
 * Optional:
 * - OPENAI_MODEL (defaults to gpt-4o-mini)
 */

const OPENAI_RESPONSES_URL = 'https://api.openai.com/v1/responses';

function doGet() {
  return json_({
    ok: true,
    result: {
      message: 'Zrobleno AI gateway працює. Перевір підключення із застосунку.',
    },
  });
}

function doPost(event) {
  try {
    const body = parseBody_(event);
    authorize_(body.token);
    const action = String(body.action || '');
    let result;

    if (action === 'health') {
      result = health_();
    } else if (action === 'analyze_receipt') {
      result = analyzeReceipt_(body);
    } else if (action === 'analyze_label') {
      result = analyzeLabel_(body);
    } else if (action === 'chat') {
      result = chat_(body);
    } else if (action === 'sync') {
      result = sync_(body);
    } else {
      throw new Error('Невідома дія застосунку.');
    }

    return json_({ok: true, result: result});
  } catch (error) {
    console.error(error && error.stack ? error.stack : error);
    return json_({
      ok: false,
      error: cleanError_(error),
    });
  }
}

function health_() {
  const config = config_();
  if (!config.openAiKey) {
    throw new Error('У Script Properties немає OPENAI_API_KEY.');
  }
  if (!config.spreadsheetId) {
    throw new Error('У Script Properties немає SPREADSHEET_ID.');
  }
  const spreadsheet = SpreadsheetApp.openById(config.spreadsheetId);
  return {
    message: 'AI підключено. Google Sheets: «' + spreadsheet.getName() + '».',
    model: config.model,
  };
}

function analyzeReceipt_(body) {
  const image = imageInput_(body);
  const prompt = [
    'Проаналізуй фото касового чека. Читай лише те, що справді видно.',
    'Поверни магазин, дату у форматі YYYY-MM-DD, номер чека, спосіб оплати, код/штрихкод чека, валюту, суму та всі товарні позиції.',
    'raw_name — максимально точний рядок із чека. name — обережно розгорнута людська назва без вигаданих слів або брендів.',
    'Враховуй скорочення й сусідні рядки. Наприклад, «вермішель шв приг. негос. Куховар Сметана-цибуля 50г» — це вермішель швидкого приготування «Куховар», негостра, сметана-цибуля, 50 г, а не сметана 15%.',
    'Якщо над позицією надруковано «ШТРИХКОД» і цифри, поверни їх у barcode цієї позиції.',
    'consumer_type: human_food лише для їжі людини; pet для корму/товарів тварин; non_food для решти. Корм для котів ніколи не є human_food.',
    'Для кожної позиції визнач expense_category та конкретну subcategory: наприклад Їжа/Локшина швидкого приготування або Домашні тварини/Корм для котів.',
    'track_nutrition_default=true лише для human_food. Для pet і non_food завжди false, nutrition_source=none, nutrition_status=not_food.',
    'Для звичайних фруктів, овочів та інших однозначних продуктів дозволено nutrition_source=reference. Для брендованого або неоднозначного продукту без даних — nutrition_source=label і nutrition_status=needs_label.',
    'До needs_label додавай лише human_food з nutrition_source=label. Ніколи не проси етикетку корму для тварин або побутового товару.',
    'Не вигадуй калорійність. estimated_calories заповнюй лише коли відома маса придбаної кількості та є надійне значення; інакше null.',
    'Якщо символ або число нечіткі, зменш confidence і поясни це в note.',
    'Загальна category: єдина категорія всіх позицій або «Змішаний чек», якщо категорій кілька.',
  ].join('\n');
  return openAiStructured_(
    prompt,
    image,
    'receipt_scan',
    receiptSchema_(),
    2600
  );
}

function analyzeLabel_(body) {
  const image = imageInput_(body);
  const prompt = [
    'Проаналізуй фото харчової етикетки українською або іншою мовою.',
    'Зчитай точну назву, бренд, варіант, штрихкод, вагу упаковки, калорійність і БЖВ саме на 100 г.',
    'Якщо етикетка дає кілоджоулі та кілокалорії, використовуй кілокалорії.',
    'Не плутай значення на порцію зі значенням на 100 г. Якщо можна точно перерахувати на 100 г — перерахуй і поясни в note.',
    'Невидимі або сумнівні значення повертай null і перелічуй у missing_fields. Не домислюй.',
    'source_text — короткий дослівний фрагмент таблиці, на якому базується результат.',
  ].join('\n');
  return openAiStructured_(
    prompt,
    image,
    'nutrition_label_scan',
    labelSchema_(),
    1800
  );
}

function chat_(body) {
  const message = String(body.message || '').trim();
  if (!message) throw new Error('Порожнє повідомлення.');
  const context = body.context || {};
  const history = Array.isArray(body.history) ? body.history.slice(-12) : [];
  const prompt = [
    'Ти — Синичка, україномовна помічниця всередині Zrobleno для дорослого користувача.',
    'Допомагай із денним планом харчування, калоріями, покупками, витратами та простими справами.',
    'Спілкуйся як розумний дорослий приятель: прямо, коротко, конкретно, без тону виховательки, сюсюкання, зменшувальних слів і дитсадкових похвал.',
    'Доречний сухий або трохи чорний гумор дозволений. Не маскуй прості речі евфемізмами: якщо Клякса залишила какашку, так і кажи.',
    'Не сором, не карай і не моралізуй.',
    'Відрізняй «купив» від «з’їв». Чек не означає, що весь продукт уже з’їдений.',
    'Коли точних даних про продукт немає, прямо скажи, що потрібне фото етикетки або вага порції.',
    'Не давай медичних діагнозів. Для небезпечних симптомів радь звернутися до лікаря.',
    'actions додавай лише як пропозиції, які користувач окремо підтвердить у застосунку.',
    'Для food action calories — загальна калорійність фактично з’їденої порції, не на 100 г.',
    'Якщо немає готової дії, поверни порожній масив actions.',
    '',
    'Поточні дані Zrobleno:',
    JSON.stringify(context),
    '',
    'Останні репліки:',
    JSON.stringify(history),
    '',
    'Нове повідомлення користувача:',
    message,
  ].join('\n');
  return openAiStructured_(
    prompt,
    null,
    'assistant_reply',
    assistantSchema_(),
    1400
  );
}

function openAiStructured_(prompt, image, schemaName, schema, maxTokens) {
  const config = config_();
  if (!config.openAiKey) {
    throw new Error('AI ще не налаштовано: відсутній OPENAI_API_KEY.');
  }

  const content = [{type: 'input_text', text: prompt}];
  if (image) content.push(image);
  const payload = {
    model: config.model,
    input: [{role: 'user', content: content}],
    max_output_tokens: maxTokens,
    text: {
      format: {
        type: 'json_schema',
        name: schemaName,
        strict: true,
        schema: schema,
      },
    },
  };

  const response = UrlFetchApp.fetch(OPENAI_RESPONSES_URL, {
    method: 'post',
    contentType: 'application/json',
    headers: {Authorization: 'Bearer ' + config.openAiKey},
    payload: JSON.stringify(payload),
    muteHttpExceptions: true,
  });
  const code = response.getResponseCode();
  const raw = response.getContentText();
  let decoded;
  try {
    decoded = JSON.parse(raw);
  } catch (error) {
    throw new Error('OpenAI повернув неочікувану відповідь (' + code + ').');
  }
  if (code < 200 || code >= 300) {
    const apiMessage = decoded && decoded.error && decoded.error.message;
    throw new Error('OpenAI: ' + (apiMessage || 'помилка ' + code));
  }
  const outputText = outputText_(decoded);
  if (!outputText) {
    throw new Error('OpenAI не повернув результат аналізу.');
  }
  try {
    return JSON.parse(outputText);
  } catch (error) {
    throw new Error('Не вдалося прочитати структуровану відповідь OpenAI.');
  }
}

function outputText_(response) {
  const output = Array.isArray(response.output) ? response.output : [];
  for (let i = 0; i < output.length; i += 1) {
    const item = output[i];
    if (!item || item.type !== 'message' || !Array.isArray(item.content)) {
      continue;
    }
    for (let j = 0; j < item.content.length; j += 1) {
      const content = item.content[j];
      if (content && content.type === 'output_text' && content.text) {
        return content.text;
      }
      if (content && content.type === 'refusal' && content.refusal) {
        throw new Error('OpenAI відмовився обробляти це зображення.');
      }
    }
  }
  return '';
}

function sync_(body) {
  const eventType = String(body.event_type || '');
  const record = body.record || {};
  const config = config_();
  if (!config.spreadsheetId) {
    throw new Error('Google Sheets ще не налаштовано.');
  }
  const lock = LockService.getScriptLock();
  lock.waitLock(15000);
  try {
    const spreadsheet = SpreadsheetApp.openById(config.spreadsheetId);
    ensureSheets_(spreadsheet);
    const now = new Date();
    if (eventType === 'expense') {
      upsert_(spreadsheet, 'Expenses', 2, record.id, [
        now,
        record.id || '',
        record.date || '',
        record.title || '',
        numberOrBlank_(record.amount),
        record.category || '',
        record.receiptPath || '',
        body.receipt ? body.receipt.store_name || '' : '',
        body.receipt ? numberOrBlank_(body.receipt.total) : '',
        body.receipt ? body.receipt.currency || '' : '',
        body.receipt ? JSON.stringify(body.receipt.needs_label || []) : '',
        body.receipt ? body.receipt.receipt_number || '' : '',
        body.receipt ? body.receipt.payment_method || '' : '',
        body.receipt ? body.receipt.receipt_code || '' : '',
      ]);
      if (body.receipt) {
        deleteRowsById_(spreadsheet, 'ReceiptItems', 2, record.id);
        const items = Array.isArray(body.receipt.items)
          ? body.receipt.items
          : [];
        items.forEach(function (item) {
          append_(spreadsheet, 'ReceiptItems', [
            now,
            record.id || '',
            item.name || '',
            item.raw_name || '',
            numberOrBlank_(item.quantity),
            numberOrBlank_(item.unit_price),
            numberOrBlank_(item.total_price),
            item.is_food === true,
            numberOrBlank_(item.estimated_calories),
            item.nutrition_status || '',
            numberOrBlank_(item.confidence),
            item.consumer_type || '',
            item.expense_category || '',
            item.subcategory || '',
            item.barcode || '',
            item.track_nutrition_default === true,
            item.nutrition_source || '',
          ]);
        });
      }
    } else if (eventType === 'product') {
      upsert_(spreadsheet, 'Products', 2, record.id, [
        now,
        record.id || '',
        record.brand || '',
        record.name || '',
        record.variant || '',
        record.barcode || '',
        numberOrBlank_(record.packageGrams),
        numberOrBlank_(record.kcalPer100),
        numberOrBlank_(record.proteinPer100),
        numberOrBlank_(record.fatPer100),
        numberOrBlank_(record.carbsPer100),
        record.source || '',
        record.verified === true,
      ]);
    } else if (eventType === 'food') {
      upsert_(spreadsheet, 'Food', 2, record.id, [
        now,
        record.id || '',
        record.date || '',
        record.name || '',
        numberOrBlank_(record.amountGrams),
        numberOrBlank_(record.calories),
        numberOrBlank_(record.protein),
        numberOrBlank_(record.fat),
        numberOrBlank_(record.carbs),
        record.productId || '',
      ]);
    } else {
      throw new Error('Непідтримуваний тип синхронізації.');
    }
    return {saved: true, event_type: eventType};
  } finally {
    lock.releaseLock();
  }
}

function setupZroblenoSheets() {
  const config = config_();
  if (!config.spreadsheetId) {
    throw new Error('Спочатку додай SPREADSHEET_ID у Script Properties.');
  }
  const spreadsheet = SpreadsheetApp.openById(config.spreadsheetId);
  ensureSheets_(spreadsheet);
  spreadsheet.getSheets().forEach(function (sheet) {
    sheet.setFrozenRows(1);
    if (sheet.getLastColumn() > 0) {
      sheet.getRange(1, 1, 1, sheet.getLastColumn())
        .setFontWeight('bold')
        .setBackground('#18352b')
        .setFontColor('#ffffff');
      sheet.autoResizeColumns(1, sheet.getLastColumn());
    }
  });
  return spreadsheet.getUrl();
}

function ensureSheets_(spreadsheet) {
  ensureSheet_(spreadsheet, 'Expenses', [
    'Synced at', 'ID', 'Date', 'Title', 'Amount', 'Category', 'Receipt path',
    'Store', 'Receipt total', 'Currency', 'Needs label', 'Receipt number',
    'Payment method', 'Receipt code / QR',
  ]);
  ensureSheet_(spreadsheet, 'ReceiptItems', [
    'Synced at', 'Expense ID', 'Item', 'Raw receipt text', 'Quantity',
    'Unit price', 'Total price', 'Is food', 'Estimated kcal',
    'Nutrition status', 'Confidence', 'Consumer type', 'Expense category',
    'Subcategory', 'Barcode', 'Track nutrition', 'Nutrition source',
  ]);
  ensureSheet_(spreadsheet, 'Products', [
    'Synced at', 'ID', 'Brand', 'Name', 'Variant', 'Barcode', 'Package g',
    'kcal / 100 g', 'Protein / 100 g', 'Fat / 100 g', 'Carbs / 100 g',
    'Source', 'Verified',
  ]);
  ensureSheet_(spreadsheet, 'Food', [
    'Synced at', 'ID', 'Date', 'Name', 'Amount g', 'Calories', 'Protein',
    'Fat', 'Carbs', 'Product ID',
  ]);
}

function ensureSheet_(spreadsheet, name, headers) {
  let sheet = spreadsheet.getSheetByName(name);
  if (!sheet) sheet = spreadsheet.insertSheet(name);
  sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  return sheet;
}

function append_(spreadsheet, sheetName, values) {
  spreadsheet.getSheetByName(sheetName).appendRow(values);
}

function upsert_(spreadsheet, sheetName, idColumn, id, values) {
  const sheet = spreadsheet.getSheetByName(sheetName);
  const stringId = String(id || '');
  if (stringId && sheet.getLastRow() > 1) {
    const match = sheet
      .getRange(2, idColumn, sheet.getLastRow() - 1, 1)
      .createTextFinder(stringId)
      .useRegularExpression(false)
      .matchEntireCell(true)
      .findNext();
    if (match) {
      sheet.getRange(match.getRow(), 1, 1, values.length).setValues([values]);
      return;
    }
  }
  sheet.appendRow(values);
}

function deleteRowsById_(spreadsheet, sheetName, idColumn, id) {
  const sheet = spreadsheet.getSheetByName(sheetName);
  const stringId = String(id || '');
  if (!stringId || sheet.getLastRow() <= 1) return;
  const values = sheet
    .getRange(2, idColumn, sheet.getLastRow() - 1, 1)
    .getDisplayValues();
  for (let index = values.length - 1; index >= 0; index -= 1) {
    if (values[index][0] === stringId) sheet.deleteRow(index + 2);
  }
}

function receiptSchema_() {
  return {
    type: 'object',
    additionalProperties: false,
    required: [
      'store_name', 'receipt_date', 'currency', 'total', 'category', 'items',
      'needs_label', 'note', 'confidence', 'receipt_number',
      'payment_method', 'receipt_code',
    ],
    properties: {
      store_name: {type: 'string'},
      receipt_date: {type: ['string', 'null']},
      currency: {type: 'string'},
      receipt_number: {type: 'string'},
      payment_method: {type: 'string'},
      receipt_code: {type: 'string'},
      total: {type: 'number'},
      category: {
        type: 'string',
        enum: [
          'Їжа', 'Домашні тварини', 'Побут', 'Здоров’я', 'Транспорт',
          'Одяг', 'Розваги', 'Інше', 'Змішаний чек'
        ],
      },
      items: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: [
            'name', 'raw_name', 'quantity', 'unit_price', 'total_price',
            'is_food', 'estimated_calories', 'nutrition_status', 'confidence',
            'consumer_type', 'expense_category', 'subcategory', 'barcode',
            'track_nutrition_default', 'nutrition_source',
          ],
          properties: {
            name: {type: 'string'},
            raw_name: {type: 'string'},
            quantity: {type: 'number'},
            unit_price: {type: ['number', 'null']},
            total_price: {type: 'number'},
            is_food: {type: 'boolean'},
            estimated_calories: {type: ['number', 'null']},
            nutrition_status: {
              type: 'string',
              enum: ['known', 'estimate', 'needs_label', 'not_food'],
            },
            confidence: {type: 'number'},
            consumer_type: {
              type: 'string',
              enum: ['human_food', 'pet', 'non_food'],
            },
            expense_category: {
              type: 'string',
              enum: [
                'Їжа', 'Домашні тварини', 'Побут', 'Здоров’я', 'Транспорт',
                'Одяг', 'Розваги', 'Інше'
              ],
            },
            subcategory: {type: 'string'},
            barcode: {type: 'string'},
            track_nutrition_default: {type: 'boolean'},
            nutrition_source: {
              type: 'string',
              enum: ['known', 'reference', 'label', 'none'],
            },
          },
        },
      },
      needs_label: {type: 'array', items: {type: 'string'}},
      note: {type: 'string'},
      confidence: {type: 'number'},
    },
  };
}

function labelSchema_() {
  return {
    type: 'object',
    additionalProperties: false,
    required: [
      'name', 'brand', 'variant', 'barcode', 'package_grams', 'kcal_per_100',
      'protein_per_100', 'fat_per_100', 'carbs_per_100', 'source_text',
      'missing_fields', 'note', 'confidence',
    ],
    properties: {
      name: {type: 'string'},
      brand: {type: 'string'},
      variant: {type: 'string'},
      barcode: {type: 'string'},
      package_grams: {type: ['number', 'null']},
      kcal_per_100: {type: ['number', 'null']},
      protein_per_100: {type: ['number', 'null']},
      fat_per_100: {type: ['number', 'null']},
      carbs_per_100: {type: ['number', 'null']},
      source_text: {type: 'string'},
      missing_fields: {type: 'array', items: {type: 'string'}},
      note: {type: 'string'},
      confidence: {type: 'number'},
    },
  };
}

function assistantSchema_() {
  return {
    type: 'object',
    additionalProperties: false,
    required: ['message', 'actions', 'quick_replies'],
    properties: {
      message: {type: 'string'},
      actions: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: [
            'kind', 'title', 'name', 'category', 'amount', 'calories',
            'protein', 'fat', 'carbs',
          ],
          properties: {
            kind: {type: 'string', enum: ['food', 'expense', 'none']},
            title: {type: 'string'},
            name: {type: 'string'},
            category: {type: 'string'},
            amount: {type: ['number', 'null']},
            calories: {type: ['number', 'null']},
            protein: {type: ['number', 'null']},
            fat: {type: ['number', 'null']},
            carbs: {type: ['number', 'null']},
          },
        },
      },
      quick_replies: {
        type: 'array',
        items: {type: 'string'},
      },
    },
  };
}

function imageInput_(body) {
  const base64 = String(body.image_base64 || '');
  if (!base64) throw new Error('Застосунок не передав фото.');
  const mimeType = String(body.mime_type || 'image/jpeg');
  if (['image/jpeg', 'image/png', 'image/webp'].indexOf(mimeType) === -1) {
    throw new Error('Непідтримуваний формат фото.');
  }
  return {
    type: 'input_image',
    image_url: 'data:' + mimeType + ';base64,' + base64,
    detail: 'high',
  };
}

function parseBody_(event) {
  if (!event || !event.postData || !event.postData.contents) {
    throw new Error('Порожній запит.');
  }
  try {
    return JSON.parse(event.postData.contents);
  } catch (error) {
    throw new Error('Запит має неправильний формат JSON.');
  }
}

function authorize_(token) {
  const expected = config_().appToken;
  if (!expected) throw new Error('У Script Properties немає APP_TOKEN.');
  if (String(token || '') !== expected) {
    throw new Error('Неправильний токен Zrobleno.');
  }
}

function config_() {
  const properties = PropertiesService.getScriptProperties();
  return {
    openAiKey: properties.getProperty('OPENAI_API_KEY') || '',
    appToken: properties.getProperty('APP_TOKEN') || '',
    spreadsheetId: properties.getProperty('SPREADSHEET_ID') || '',
    model: properties.getProperty('OPENAI_MODEL') || 'gpt-4o-mini',
  };
}

function numberOrBlank_(value) {
  return typeof value === 'number' && isFinite(value) ? value : '';
}

function cleanError_(error) {
  const message = error && error.message ? String(error.message) : String(error);
  return message.replace(/sk-[A-Za-z0-9_-]+/g, '[приховано]');
}

function json_(value) {
  return ContentService
    .createTextOutput(JSON.stringify(value))
    .setMimeType(ContentService.MimeType.JSON);
}
