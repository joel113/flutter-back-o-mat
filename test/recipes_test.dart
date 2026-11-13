import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';
import 'package:flutter_back_o_mat/recipes/recipes.dart';
import 'package:flutter_back_o_mat/util/db/db.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Future<List<RecipeJsonEntry>> Function() load) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: BackomatRecipes(loadRecipes: load)),
    );

RecipeJsonEntry entry(String json) => RecipeJsonEntry(
      id: 1,
      name: 'Bread',
      jsonData: json,
      lastModified: DateTime(2026),
    );

void main() {
  testWidgets('shows loading then empty state', (tester) async {
    final pending = Completer<List<RecipeJsonEntry>>();
    await tester.pumpWidget(app(() => pending.future));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No recipes yet.'), findsOneWidget);
  });

  testWidgets('completion after disposal does not update disposed state',
      (tester) async {
    final pending = Completer<List<RecipeJsonEntry>>();
    await tester.pumpWidget(app(() => pending.future));
    await tester.pumpWidget(const SizedBox());
    pending.complete([entry('{}')]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('database errors can be retried without duplicating rows',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(app(() async {
      if (attempts++ == 0) throw StateError('Database unavailable');
      return [entry('{}')];
    }));
    await tester.pumpAndSettle();
    expect(find.text('Could not load recipes.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Bread'), findsOneWidget);
    expect(find.byTooltip('Start baking'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid recipe JSON shows a recoverable error', (tester) async {
    await tester.pumpWidget(app(() async => [entry('invalid JSON')]));
    await tester.pumpAndSettle();
    expect(find.text('Could not load recipes.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing image asset has a fallback and description is optional',
      (tester) async {
    await tester.pumpWidget(
      app(() async => [entry('{"image":"does-not-exist.jpg"}')]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bread'), findsOneWidget);
    expect(find.byIcon(Icons.bakery_dining_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
