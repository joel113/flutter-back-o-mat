import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../recipe/backer.dart';
import '../recipe/recipe.dart';
import '../recipe/editor/recipe_image.dart';
import 'recipe_summary.dart';

class Item extends StatelessWidget {
  const Item({super.key, required this.recipe, this.onChanged});
  final RecipeSummary recipe;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return InkWell(
          onTap: () => Navigator.of(context)
              .push(
                MaterialPageRoute<void>(
                  builder: (_) => BackomatRecipe(id: recipe.id),
                ),
              )
              .then((_) => onChanged?.call()),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 20,
              vertical: 16,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: RecipeImage(
                    image: recipe.image,
                    width: compact ? 64 : 88,
                    height: compact ? 64 : 80,
                  ),
                ),
                SizedBox(width: compact ? 16 : 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (recipe.variantCount > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          strings.variantCount(recipe.variantCount),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                      if (recipe.description?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Text(
                          recipe.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: strings.startBaking,
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute<void>(
                          builder: (_) => BackomatBacker(id: recipe.id),
                        ),
                      )
                      .then((_) => onChanged?.call()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
