import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/navigation.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';
import 'package:flutter_back_o_mat/theme/app_theme.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_extractor.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_editor.dart';
import 'package:flutter_back_o_mat/recipe/editor/scan_recipe.dart';
import 'package:flutter_back_o_mat/settings/settings.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:flutter_back_o_mat/baking/baking_view.dart';
import 'package:flutter_back_o_mat/recipes/recipes.dart';
import 'package:flutter_back_o_mat/util/db/db.dart';

import 'recipe_editor_test.dart' show MemoryRecipes;
import 'baking_view_test.dart' show MemoryBakes;
import 'baking_session_test.dart' show bakingRecipe;

Widget styledApp(
  Widget home, {
  Locale locale = const Locale('en'),
  ThemeMode mode = ThemeMode.system,
}) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: mode,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);
void window(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget rootButton(String label, WidgetBuilder builder) => Scaffold(
  body: Builder(
    builder: (context) => TextButton(
      onPressed: () =>
          Navigator.push<void>(context, MaterialPageRoute(builder: builder)),
      child: Text(label),
    ),
  ),
);

void main() {
  test(
    'light and dark themes keep body, actions and timing warnings readable',
    () {
      double contrast(Color a, Color b) {
        final first = a.computeLuminance();
        final second = b.computeLuminance();
        return ((first > second ? first : second) + .05) /
            ((first < second ? first : second) + .05);
      }

      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final colors = theme.colorScheme;
        expect(
          contrast(colors.onSurface, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(colors.onSurfaceVariant, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(colors.primary, colors.onPrimary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(
            theme.extension<AppSemanticColors>()!.warning,
            colors.surface,
          ),
          greaterThanOrEqualTo(4.5),
        );
        final semantic = theme.extension<AppSemanticColors>()!;
        for (final color in [
          semantic.running,
          semantic.paused,
          semantic.completed,
        ]) {
          expect(contrast(color, colors.onPrimary), greaterThanOrEqualTo(4.5));
        }
        expect(
          contrast(colors.error, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );
  testWidgets('the application follows system brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(styledApp(const AppSettings()));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AppSettings))).brightness,
      Brightness.light,
    );
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AppSettings))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'desktop destinations retain editor routes, drafts and discard confirmation across resize',
    (tester) async {
      window(tester, 1400);
      final repository = MemoryRecipes();
      await tester.pumpWidget(
        styledApp(
          BackomatNavigation(
            recipesBuilder: (_) => rootButton(
              'Open editor',
              (_) => RecipeEditor(recipe: RecipeData(), repository: repository),
            ),
            plannerBuilder: (_) =>
                const Scaffold(body: Text('Planner overview')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Keep this draft',
      );
      await tester.tap(find.byKey(const ValueKey('nav-planner')));
      await tester.pumpAndSettle();
      expect(find.text('Planner overview'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-settings')));
      await tester.pumpAndSettle();
      expect(find.byType(AppSettings), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-recipes')));
      await tester.pumpAndSettle();
      expect(find.text('Keep this draft'), findsOneWidget);
      tester.view.physicalSize = const Size(700, 1000);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Keep this draft'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Keep this draft'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Open editor'), findsOneWidget);
      expect(repository.saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Settings opens AI-key management within the persistent app frame',
    (tester) async {
      window(tester, 1300);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        ApiKeyStore.channel,
        (_) async => null,
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(ApiKeyStore.channel, null),
      );
      await tester.pumpWidget(
        styledApp(
          BackomatNavigation(
            recipesBuilder: (_) =>
                const Scaffold(body: Text('Recipes overview')),
            plannerBuilder: (_) => const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AI scanning settings'));
      await tester.pumpAndSettle();
      expect(find.byType(AiSettings), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-recipes')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-recipes')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-settings')));
      await tester.pumpAndSettle();
      expect(find.byType(AiSettings), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AppSettings), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'hidden baking sections stop refreshes and resume accurate countdowns without new sessions',
    (tester) async {
      window(tester, 1800);
      final repository = MemoryBakes();
      var now = DateTime(2026, 11, 8, 8);
      final saved = await repository.save(
        BakingSession(recipeId: 7, recipe: bakingRecipe(), plannedStart: now),
      );
      await tester.pumpWidget(
        styledApp(
          BackomatNavigation(
            recipesBuilder: (_) => rootButton(
              'Open bake',
              (_) => BakingView(
                sessionId: saved.id!,
                repository: repository,
                clock: () => now,
              ),
            ),
            plannerBuilder: (_) =>
                const Scaffold(body: Text('Planner overview')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open bake'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-planner')));
      await tester.pumpAndSettle();
      now = now.add(const Duration(minutes: 10));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('01:00:00', skipOffstage: false), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-recipes')));
      await tester.pumpAndSettle();
      expect(find.text('00:50:00'), findsOneWidget);
      expect((await repository.list()).length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final locale in [const Locale('en'), const Locale('de')]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'narrow ${locale.languageCode} $mode screens do not overflow',
        (tester) async {
          window(tester, 390);
          await tester.pumpWidget(
            styledApp(
              BackomatNavigation(
                recipesBuilder: (_) => BackomatRecipes(
                  loadRecipes: () async => [
                    RecipeJsonEntry(
                      id: 1,
                      name: 'San Francisco Sourdough Bread aus Dinkel',
                      jsonData: '{"description":"Ein aromatisches Brot für den nächsten Backtag."}',
                      lastModified: DateTime(2026),
                    ),
                  ],
                ),
              ),
              locale: locale,
              mode: mode,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(NavigationBar), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('nav-settings')));
          await tester.pumpAndSettle();
          expect(find.byType(AppSettings), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'system back only affects the selected section and respects an editor draft',
    (tester) async {
      window(tester, 1400);
      final repository = MemoryRecipes();
      await tester.pumpWidget(
        styledApp(
          BackomatNavigation(
            recipesBuilder: (_) => rootButton(
              'Open editor',
              (_) => RecipeEditor(recipe: RecipeData(), repository: repository),
            ),
            plannerBuilder: (_) => rootButton(
              'Open planner detail',
              (_) => const Scaffold(body: Text('Planner detail')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Retained draft',
      );
      await tester.tap(find.byKey(const ValueKey('nav-planner')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open planner detail'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Open planner detail'), findsOneWidget);
      expect(find.text('Discard unsaved changes?'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('nav-recipes')));
      await tester.pumpAndSettle();
      expect(find.text('Retained draft'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Retained draft'), findsOneWidget);
      expect(repository.saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
