import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models.dart';

class AiServiceException implements Exception {
  const AiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiService {
  AiService(this.settings, {http.Client? client}) : _client = client;

  final AiSettings settings;
  final http.Client? _client;

  Future<String> health() async {
    final result = await _post('health');
    return result['message'] as String? ?? 'AI підключено';
  }

  Future<ReceiptScanResult> analyzeReceipt(String imagePath) async {
    final result = await _analyzeImage('analyze_receipt', imagePath);
    return ReceiptScanResult.fromJson(result);
  }

  Future<LabelScanResult> analyzeLabel(String imagePath) async {
    final result = await _analyzeImage('analyze_label', imagePath);
    return LabelScanResult.fromJson(result);
  }

  Future<AssistantReply> chat({
    required String message,
    required Map<String, dynamic> context,
    required List<AssistantMessage> history,
  }) async {
    final result = await _post('chat', {
      'message': message,
      'context': context,
      'history': history
          .skip(history.length > 12 ? history.length - 12 : 0)
          .map((item) => {'role': item.role, 'text': item.text})
          .toList(),
    });
    return AssistantReply.fromJson(result);
  }

  Future<void> syncExpense(
    Expense expense, {
    ReceiptScanResult? receipt,
  }) async {
    if (!settings.syncGoogleSheets) return;
    await _post('sync', {
      'event_type': 'expense',
      'record': expense.toJson(),
      'receipt': receipt == null
          ? null
          : {
              'store_name': receipt.storeName,
              'receipt_date': receipt.receiptDate,
              'currency': receipt.currency,
              'total': receipt.total,
              'items': receipt.items.map((item) => item.toJson()).toList(),
              'needs_label': receipt.needsLabel,
              'confidence': receipt.confidence,
            },
    });
  }

  Future<void> syncProduct(Product product) async {
    if (!settings.syncGoogleSheets) return;
    await _post('sync', {'event_type': 'product', 'record': product.toJson()});
  }

  Future<void> syncFood(FoodEntry food) async {
    if (!settings.syncGoogleSheets) return;
    await _post('sync', {'event_type': 'food', 'record': food.toJson()});
  }

  Future<Map<String, dynamic>> _analyzeImage(
    String action,
    String imagePath,
  ) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const AiServiceException('Фото не знайдено на телефоні.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 12 * 1024 * 1024) {
      throw const AiServiceException(
        'Фото завелике. Спробуй зробити знімок трохи ближче.',
      );
    }
    return _post(action, {
      'image_base64': base64Encode(bytes),
      'mime_type': _mimeType(imagePath),
    });
  }

  Future<Map<String, dynamic>> _post(
    String action, [
    Map<String, dynamic> payload = const {},
  ]) async {
    if (!settings.configured) {
      throw const AiServiceException('Спочатку підключи AI у налаштуваннях.');
    }

    final endpoint = Uri.parse(settings.endpoint.trim());
    final encodedBody = jsonEncode({
      'token': settings.appToken.trim(),
      'action': action,
      ...payload,
    });
    final client = _client ?? http.Client();
    late http.Response response;
    try {
      response = await client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json; charset=utf-8'},
            body: encodedBody,
          )
          .timeout(const Duration(seconds: 75));

      // Google Apps Script executes doPost, then returns its JSON through a
      // one-time 302/303 URL on script.googleusercontent.com. Dart does not
      // automatically follow POST redirects that change to GET.
      if (response.statusCode == 302 || response.statusCode == 303) {
        final location = response.headers['location'];
        if (location == null || location.trim().isEmpty) {
          throw const AiServiceException(
            'AI-сервер повернув перенаправлення без адреси.',
          );
        }
        final redirectUri = endpoint.resolve(location);
        if (redirectUri.scheme != 'https') {
          throw const AiServiceException(
            'AI-сервер повернув небезпечну адресу перенаправлення.',
          );
        }
        response = await client
            .get(redirectUri)
            .timeout(const Duration(seconds: 75));
      }
    } on TimeoutException {
      throw const AiServiceException(
        'AI відповідає надто довго. Перевір інтернет і спробуй ще раз.',
      );
    } on SocketException {
      throw const AiServiceException(
        'Немає з’єднання з сервером. Перевір інтернет.',
      );
    } on FormatException {
      throw const AiServiceException('Неправильна адреса AI-сервера.');
    } on http.ClientException {
      throw const AiServiceException('Не вдалося з’єднатися з AI-сервером.');
    } finally {
      if (_client == null) client.close();
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw AiServiceException(
        'Сервер повернув незрозумілу відповідь (${response.statusCode}).',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['ok'] != true) {
      throw AiServiceException(
        decoded['error'] as String? ??
            'Помилка AI-сервера (${response.statusCode}).',
      );
    }

    final result = decoded['result'];
    if (result is Map<String, dynamic>) return result;
    return <String, dynamic>{};
  }

  String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
