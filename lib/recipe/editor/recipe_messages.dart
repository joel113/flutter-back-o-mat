import '../../l10n/app_localizations.dart';
import '../data/recipe_data.dart';

String recipeIssueText(AppLocalizations strings, RecipeIssue issue) =>
    switch (issue) {
      RecipeIssue.preparations => strings.invalidPreparations,
      RecipeIssue.notes => strings.noteTitleRequired,
      RecipeIssue.name => strings.nameRequired,
      RecipeIssue.labels => strings.labelsRequired,
      RecipeIssue.references => strings.invalidReferences,
      RecipeIssue.quantity => strings.invalidQuantity,
      RecipeIssue.duration => strings.invalidDuration,
      RecipeIssue.temperature => strings.invalidTemperature,
    };
