import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../recipe/data/recipe_data.dart';
import '../recipe/data/recipe_repository.dart';
import 'baking_composer.dart';

Future<Set<int>?> selectPreparations(
  BuildContext context,
  RecipeData recipe,
  RecipeRepository repository,
) {
  if (recipe.preparations.isEmpty) return Future.value(<int>{});
  return Navigator.push<Set<int>>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          PreparationSelection(recipe: recipe, repository: repository),
    ),
  );
}

class PreparationSelection extends StatefulWidget {
  const PreparationSelection({
    super.key,
    required this.recipe,
    required this.repository,
  });
  final RecipeData recipe;
  final RecipeRepository repository;
  @override
  State<PreparationSelection> createState() => _PreparationSelectionState();
}

class _PreparationSelectionState extends State<PreparationSelection> {
  late Future<List<PreparationOption>> options = read();
  final selected = <int>{};
  Future<List<PreparationOption>> read() =>
      BakingComposer(widget.repository).options(widget.recipe);
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.preparationsLabel)),
      body: FutureBuilder<List<PreparationOption>>(
        future: options,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.preparationLoadError),
                  TextButton(
                    onPressed: () => setState(() {
                      options = read();
                    }),
                    child: Text(s.retry),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.preparationChoiceHint),
                    const SizedBox(height: 12),
                    Text(s.preparationStartHint),
                    const SizedBox(height: 16),
                    for (final option in snapshot.data!)
                      CheckboxListTile(
                        key: ValueKey('preparation-${option.link.recipeId}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(option.label),
                        value: selected.contains(option.link.recipeId),
                        subtitle: Text(
                          [
                            '${s.preparationConsumer}: ${widget.recipe.stages.where((stage) => stage.id == option.link.stageId).firstOrNull?.name ?? '#${option.link.stageId}'}',
                            if (!option.available)
                              s.preparationUnavailable
                            else if (!selected.contains(option.link.recipeId))
                              s.preparationNotSelected,
                            if (option.record?.recipe.preparations.isNotEmpty ??
                                false)
                              s.preparationNestedHint,
                          ].join('\n'),
                        ),
                        onChanged: !option.available
                            ? null
                            : (value) => setState(() {
                                if (value == true) {
                                  selected.add(option.link.recipeId);
                                } else {
                                  selected.remove(option.link.recipeId);
                                }
                              }),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, Set<int>.of(selected)),
                      child: Text(s.continueBakingSetup),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
