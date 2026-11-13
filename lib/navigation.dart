import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'planner/planner.dart';
import 'recipes/recipes.dart';
import 'settings/settings.dart';
import 'theme/app_components.dart';
import 'theme/app_theme.dart';

class BackomatNavigation extends StatefulWidget {
  const BackomatNavigation({
    super.key,
    this.recipesBuilder,
    this.plannerBuilder,
    this.settingsBuilder,
  });
  final WidgetBuilder? recipesBuilder;
  final WidgetBuilder? plannerBuilder;
  final WidgetBuilder? settingsBuilder;
  @override
  State<BackomatNavigation> createState() => _BackomatNavigationState();
}

class _BackomatNavigationState extends State<BackomatNavigation> {
  int selectedIndex = 0;
  final visited = <int>{0};
  final heroes = List.generate(3, (_) => HeroController());
  final navigators = List.generate(3, (_) => GlobalKey<NavigatorState>());
  void select(int index) {
    if (selectedIndex == index) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      visited.add(index);
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final labels = [s.recipes, s.planer, s.settings];
    const ids = ['recipes', 'planner', 'settings'];
    const icons = [
      Icons.menu_book_outlined,
      Icons.event_note_outlined,
      Icons.tune,
    ];
    final builders = <WidgetBuilder>[
      widget.recipesBuilder ?? (_) => const BackomatRecipes(),
      widget.plannerBuilder ?? (_) => const BackomatPlanner(),
      widget.settingsBuilder ?? (_) => const AppSettings(),
    ];
    final colors = Theme.of(context).colorScheme;
    final accents =
        Theme.of(context).extension<AppNavigationColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppNavigationColors.dark
            : AppNavigationColors.light);
    final iconColors = [accents.recipes, accents.planner, accents.settings];
    Widget navigationIcon(int index) => Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: iconColors[index].withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icons[index], size: 21, color: iconColors[index]),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1000;
        return Scaffold(
          body: Row(
            children: [
              if (desktop)
                SizedBox(
                  width: 200,
                  child: Material(
                    color: colors.surfaceContainerLow,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: colors.outlineVariant),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                28,
                                12,
                                32,
                              ),
                              child: Row(
                                children: [
                                  const AppLogo(),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      s.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (var i = 0; i < 3; i++)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  6,
                                ),
                                child: ListTile(
                                  key: ValueKey('nav-${ids[i]}'),
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 3,
                                  ),
                                  selected: selectedIndex == i,
                                  selectedColor: colors.onPrimaryContainer,
                                  selectedTileColor: colors.primaryContainer,
                                  leading: navigationIcon(i),
                                  title: Text(
                                    labels[i],
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                  onTap: () => select(i),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                key: const ValueKey('section-content'),
                child: IndexedStack(
                  index: selectedIndex,
                  children: [
                    for (var i = 0; i < 3; i++)
                      visited.contains(i)
                          ? TickerMode(
                              enabled: selectedIndex == i,
                              child: ExcludeFocus(
                                excluding: selectedIndex != i,
                                child: NavigatorPopHandler<Object?>(
                                  enabled: selectedIndex == i,
                                  onPopWithResult: (_) {
                                    if (selectedIndex == i) {
                                      navigators[i].currentState!.maybePop();
                                    }
                                  },
                                  child: HeroControllerScope(
                                    controller: heroes[i],
                                    child: Navigator(
                                      key: navigators[i],
                                      onGenerateRoute: (settings) =>
                                          MaterialPageRoute<void>(
                                            settings: settings,
                                            builder: builders[i],
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: select,
                  destinations: [
                    for (var i = 0; i < 3; i++)
                      NavigationDestination(
                        key: ValueKey('nav-${ids[i]}'),
                        icon: navigationIcon(i),
                        label: labels[i],
                      ),
                  ],
                ),
        );
      },
    );
  }
}
