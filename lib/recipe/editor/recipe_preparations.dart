import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_components.dart';
import '../data/recipe_data.dart';
import '../data/recipe_family.dart';
import '../data/recipe_repository.dart';
import 'recipe_editor_section.dart';

class PreparationName extends StatefulWidget {
  const PreparationName({
    super.key,
    required this.id,
    required this.repository,
  });
  final int id;
  final RecipeRepository repository;
  @override
  State<PreparationName> createState() => _PreparationNameState();
}

class _PreparationNameState extends State<PreparationName> {
  late final record = widget.repository.loadRecord(widget.id);
  @override
  Widget build(BuildContext context) => FutureBuilder<RecipeRecord>(
    future: record,
    builder: (context, snapshot) => Text(
      snapshot.hasData
          ? '${snapshot.data!.family?.name ?? snapshot.data!.recipe.name}${snapshot.data!.variant == null ? '' : ' · ${snapshot.data!.variant!.name}'}'
          : '#${widget.id}${snapshot.hasError ? ' · ${AppLocalizations.of(context)!.preparationUnavailable}' : ''}',
    ),
  );
}

class RecipePreparationsFields extends StatefulWidget {
  const RecipePreparationsFields({
    super.key,
    required this.recipe,
    required this.repository,
    required this.onChanged,
    this.recipeId,
  });
  final RecipeData recipe;
  final RecipeRepository repository;
  final VoidCallback onChanged;
  final int? recipeId;
  @override
  State<RecipePreparationsFields> createState() =>
      _RecipePreparationsFieldsState();
}

class _RecipePreparationsFieldsState extends State<RecipePreparationsFields> {
  bool loading = false;
  String? error;
  Future<void> add() async {
    final s = AppLocalizations.of(context)!;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final candidates = <(int, String)>[];
      for (final entry in await widget.repository.listFamilyEntries()) {
        final family = await widget.repository.loadFamily(entry.familyId!);
        for (final variant in family.variants) {
          if (variant.id != widget.recipeId &&
              !widget.recipe.preparations.any(
                (p) => p.recipeId == variant.id,
              )) {
            candidates.add((variant.id, '${family.name} · ${variant.name}'));
          }
        }
      }
      if (!mounted) return;
      setState(() => loading = false);
      final id = await showDialog<int>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(s.choosePreparation),
          children: [
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.noPreparationCandidates),
              ),
            for (final candidate in candidates)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, candidate.$1),
                child: Text(candidate.$2),
              ),
          ],
        ),
      );
      if (id != null && mounted && widget.recipe.stages.isNotEmpty) {
        widget.recipe.preparations.add(
          RecipePreparation(
            recipeId: id,
            stageId: widget.recipe.stages.first.id,
          ),
        );
        widget.onChanged();
      }
    } catch (_) {
      if (mounted) setState(() => error = s.preparationLoadError);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return RecipeEditorSection(
      title: s.preparationsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          for (final link in widget.recipe.preparations)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              key: ObjectKey(link),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: PreparationName(
                            id: link.recipeId,
                            repository: widget.repository,
                          ),
                        ),
                        IconButton(
                          tooltip: s.remove,
                          onPressed: () {
                            widget.recipe.preparations.remove(link);
                            widget.onChanged();
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<int>(
                      key: ValueKey(
                        '${link.stageId}:${widget.recipe.stages.map((s) => s.id).join(',')}',
                      ),
                      initialValue:
                          widget.recipe.stages.any(
                            (stage) => stage.id == link.stageId,
                          )
                          ? link.stageId
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: s.preparationConsumer,
                      ),
                      items: [
                        for (final stage in widget.recipe.stages)
                          DropdownMenuItem(
                            value: stage.id,
                            child: Text(
                              stage.name.isEmpty ? '#${stage.id}' : stage.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      validator: (_) =>
                          widget.recipe.stages.any((s) => s.id == link.stageId)
                          ? null
                          : s.invalidPreparations,
                      onChanged: (id) {
                        if (id != null) {
                          link.stageId = id;
                          widget.onChanged();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (widget.recipe.stages.isEmpty) ...[
            Text(s.preparationAddStagesFirst),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: loading || widget.recipe.stages.isEmpty ? null : add,
            icon: const Icon(Icons.add_link),
            label: Text(s.addPreparation),
          ),
        ],
      ),
    );
  }
}

class RecipePreparationsSection extends StatelessWidget {
  const RecipePreparationsSection({
    super.key,
    required this.recipe,
    required this.repository,
    this.onEdit,
    this.onOpen,
  });
  final RecipeData recipe;
  final RecipeRepository repository;
  final VoidCallback? onEdit;
  final ValueChanged<int>? onOpen;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AppSurface(
      child: ExpansionTile(
        title: Text(s.preparationsLabel),
        leading: const Icon(Icons.account_tree_outlined),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          for (final link in recipe.preparations)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: PreparationName(id: link.recipeId, repository: repository),
              subtitle: Text(
                '${s.preparationConsumer}: ${recipe.stages.where((s) => s.id == link.stageId).firstOrNull?.name ?? '#${link.stageId}'}',
              ),
              trailing: onOpen == null
                  ? null
                  : IconButton(
                      tooltip: s.openPreparation,
                      onPressed: () => onOpen!(link.recipeId),
                      icon: const Icon(Icons.open_in_new),
                    ),
            ),
          if (onEdit != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(s.addPreparation),
              ),
            ),
        ],
      ),
    );
  }
}
