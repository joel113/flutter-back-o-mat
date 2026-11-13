import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/recipes/recipes.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';

void main() {
  testWidgets('recipe list opens the three recipe input methods', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BackomatRecipes(loadRecipes: () async => [])),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add recipe'), findsOneWidget);
    await tester.tap(find.text('Add recipe'));
    await tester.pumpAndSettle();
    expect(find.text('Enter manually'), findsOneWidget);
    expect(find.text('Import JSON'), findsOneWidget);
    expect(find.text('Scan photo or PDF'), findsOneWidget);
    await tester.tap(find.text('Enter manually'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
