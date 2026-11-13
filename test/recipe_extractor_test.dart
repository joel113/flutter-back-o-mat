import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_extractor.dart';

class FakeTransport implements ScanTransport {
  Map<String, dynamic>? body;
  String? key;
  bool cancelled = false;
  ScanError? error;
  Map<String, dynamic> response = {
    'status': 'completed',
    'output': [
      {
        'type': 'message',
        'content': [
          {
            'type': 'output_text',
            'text': jsonEncode({
              'recipe': {'name': 'Bread'},
              'warnings': ['Missing times'],
            }),
          },
        ],
      },
    ],
  };
  @override
  Future<Map<String, dynamic>> send(
    Map<String, dynamic> body,
    String key,
  ) async {
    this.body = body;
    this.key = key;
    if (error != null) throw ScanFailure(error!);
    return response;
  }

  @override
  void cancel() => cancelled = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pdf = ScanDocument(
    'bread.pdf',
    Uint8List.fromList(utf8.encode('%PDF-example')),
  );
  final png = ScanDocument(
    'bread.png',
    Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
  );
  test(
    'PDF extraction sends strict schema and opens an incomplete draft',
    () async {
      final transport = FakeTransport();
      final result = await RecipeExtractor(transport: transport)
          .extract([pdf], ' personal-key ');
      expect(result.recipe.name, 'Bread');
      expect(result.recipe.bakingReady, isFalse);
      expect(result.warnings, ['Missing times']);
      expect(transport.key, 'personal-key');
      expect(transport.body!['store'], isFalse);
      expect(transport.body!['text']['format']['strict'], isTrue);
      expect(transport.body!['input'][0]['content'][1]['type'], 'input_file');
    },
  );
  test('ordered image inputs use vision and mixed input is rejected before sending', () async {
    final transport = FakeTransport();
    await RecipeExtractor(transport: transport).extract([png, png], 'key');
    expect(transport.body!['input'][0]['content'][1]['type'], 'input_image');
    final invalidTransport = FakeTransport();
    await expectLater(
      RecipeExtractor(transport: invalidTransport).extract([pdf, png], 'key'),
      throwsA(
        isA<ScanFailure>().having((e) => e.reason, 'reason', ScanError.file),
      ),
    );
    expect(invalidTransport.body, isNull);
  });
  test(
    'invalid signatures, empty and oversized selections are rejected',
    () async {
      for (final files in <List<ScanDocument>>[
        [],
        [ScanDocument('bad.png', Uint8List(10))],
        List.filled(11, png),
        [
          ScanDocument(
            'large.pdf',
            Uint8List.fromList([...pdf.bytes, ...Uint8List(20 * 1024 * 1024)]),
          ),
        ],
      ]) {
        await expectLater(
          RecipeExtractor(transport: FakeTransport()).extract(files, 'key'),
          throwsA(isA<ScanFailure>()),
        );
      }
    },
  );
  test(
    'auth, rate, network, refused and malformed output stay recoverable',
    () async {
      for (final error in [ScanError.auth, ScanError.rate, ScanError.network]) {
        final transport = FakeTransport()..error = error;
        await expectLater(
          RecipeExtractor(transport: transport).extract([pdf], 'key'),
          throwsA(isA<ScanFailure>().having((e) => e.reason, 'reason', error)),
        );
      }
      for (final response in <Map<String, dynamic>>[
        {'status': 'incomplete'},
        {
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'content': [
                {'type': 'refusal'},
              ],
            },
          ],
        },
        {'status': 'completed', 'output': []},
      ]) {
        expect(
          () => RecipeExtractor.parseResponse(response),
          throwsA(
            isA<ScanFailure>().having(
              (e) => e.reason,
              'reason',
              ScanError.output,
            ),
          ),
        );
      }
    },
  );
  test('cancel closes transport and prevents sending', () async {
    final transport = FakeTransport();
    final extractor = RecipeExtractor(transport: transport)..cancel();
    await expectLater(
      extractor.extract([pdf], 'key'),
      throwsA(isA<ScanFailure>()),
    );
    expect(transport.cancelled, isTrue);
    expect(transport.body, isNull);
  });
  test('API key store uses the native Keychain channel', () async {
    String? stored;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ApiKeyStore.channel, (call) async {
      switch (call.method) {
        case 'read':
          return stored;
        case 'write':
          stored = call.arguments as String;
          return null;
        case 'delete':
          stored = null;
          return null;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(ApiKeyStore.channel, null),
    );
    final store = ApiKeyStore();
    await store.write('personal-key');
    expect(await store.read(), 'personal-key');
    await store.delete();
    expect(await store.read(), isNull);
  });
}
