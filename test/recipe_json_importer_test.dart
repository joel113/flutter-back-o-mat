import 'package:flutter/services.dart';
import 'package:flutter_back_o_mat/util/db/db_recipe_importer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('imports with a binary asset manifest and no recipe assets', () async {
    final requestedAssets = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final asset = const StringCodec().decodeMessage(message)!;
      requestedAssets.add(asset);
      if (asset == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage({
          'assets/images/bread.jpg': [
            {'asset': 'assets/images/bread.jpg'},
          ],
        });
      }
      return null;
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));

    await RecipeJsonImporter().importRecipesFromAssets();

    expect(requestedAssets, ['AssetManifest.bin']);
  });
}
