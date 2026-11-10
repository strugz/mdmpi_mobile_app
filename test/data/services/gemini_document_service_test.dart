import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mdmpi_mobile_app/data/services/gemini_document_service.dart';

/// The Gemini call shared by the Logistics inventory scanner and the
/// Collection voucher scan.

String _reply(String text) => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text}
            ]
          }
        }
      ]
    });

void main() {
  final pdf = File('${Directory.systemTemp.path}/gemini_service_test.pdf');
  setUp(() async => pdf.writeAsBytes(utf8.encode('%PDF-1.4')));

  const env = {'AI_TOOLKIT_MODEL': 'gemini-test', 'AI_TOOLKIT_API_KEY': 'k'};

  test('sends the file and the prompt, key in the header, and reads the array',
      () async {
    late http.Request sent;
    final service = GeminiDocumentService(
      env: env,
      client: MockClient((req) async {
        sent = req;
        return http.Response(
            _reply('```json\n[{"Invoice No.": "700013390"}]\n```'), 200);
      }),
    );
    final r = await service.extractJsonArray(pdf, prompt: 'list the SIs');
    expect(r.value, [
      {'Invoice No.': '700013390'}
    ]);
    expect(sent.url.toString(), contains('models/gemini-test:generateContent'));
    expect(sent.url.queryParameters, isEmpty, reason: 'no key in the URL');
    expect(sent.headers['x-goog-api-key'], 'k');
    final parts = jsonDecode(sent.body)['contents'][0]['parts'] as List;
    expect(parts[0]['inlineData']['mimeType'], 'application/pdf');
    expect(parts[1]['text'], 'list the SIs');
  });

  test('missing configuration, a bad key and a server error say why',
      () async {
    expect(
        (await GeminiDocumentService(env: const {})
                .extractJsonArray(pdf, prompt: 'p'))
            .error,
        contains('AI configuration missing'));

    final badKey = GeminiDocumentService(
      env: env,
      client: MockClient((_) async => http.Response(
          jsonEncode({
            'error': {
              'details': [
                {'reason': 'API_KEY_INVALID'}
              ]
            }
          }),
          400)),
    );
    expect((await badKey.extractJsonArray(pdf, prompt: 'p')).error,
        contains('AI API key invalid'));

    final down = GeminiDocumentService(
        env: env, client: MockClient((_) async => http.Response('', 503)));
    expect((await down.extractJsonArray(pdf, prompt: 'p')).error,
        'AI service error: 503');
  });

  test('an answer with no array fails to parse', () async {
    final service = GeminiDocumentService(
        env: env,
        client: MockClient(
            (_) async => http.Response(_reply('Sorry, I cannot read it.'), 200)));
    expect((await service.extractJsonArray(pdf, prompt: 'p')).error,
        'Failed to parse AI response');
  });

  test('a missing file fails without a call', () async {
    final service = GeminiDocumentService(
        env: env,
        client: MockClient((_) async => fail('no request expected')));
    expect(
        (await service.extractJsonArray(File('nope.jpg'), prompt: 'p')).error,
        contains('File does not exist'));
  });

  test('array extraction', () {
    expect(GeminiDocumentService.parseJsonArray('[]'), isEmpty);
    expect(GeminiDocumentService.parseJsonArray('Here: [1, 2] done'), [1, 2]);
    expect(GeminiDocumentService.parseJsonArray('{"a": 1}'), isNull);
    expect(GeminiDocumentService.generatedText('not json'), 'not json');
  });
}
