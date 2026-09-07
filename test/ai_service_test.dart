import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zrobleno/models.dart';
import 'package:zrobleno/services/ai_service.dart';

void main() {
  test('follows the Google Apps Script output redirect', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'POST') {
        return http.Response(
          '',
          302,
          headers: {
            'location':
                'https://script.googleusercontent.com/macros/echo?user_content_key=test',
          },
          request: request,
        );
      }
      return http.Response(
        jsonEncode({
          'ok': true,
          'result': {'message': 'AI підключено'},
        }),
        200,
        request: request,
      );
    });
    final service = AiService(
      AiSettings(
        endpoint: 'https://script.google.com/macros/s/deployment/exec',
        appToken: 'personal-token',
      ),
      client: client,
    );

    expect(await service.health(), 'AI підключено');
    expect(requests, hasLength(2));
    expect(requests.first.method, 'POST');
    expect(requests.last.method, 'GET');
    expect(requests.last.url.host, 'script.googleusercontent.com');
  });
}
