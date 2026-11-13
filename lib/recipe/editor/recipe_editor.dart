import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/recipe_data.dart';
import '../data/recipe_repository.dart';
import 'recipe_image.dart';
import 'recipe_input.dart';
import 'recipe_messages.dart';
import 'recipe_notes.dart';
import 'recipe_preparations.dart';
import 'recipe_editor_section.dart';

class RecipeEditor extends StatefulWidget {
  const RecipeEditor({
    super.key,
    required this.recipe,
    this.id,
    this.notice,
    this.repository,
  });
  final RecipeData recipe;
  final int? id;
  final String? notice;
  final RecipeRepository? repository;
  @override
  State<RecipeEditor> createState() => _RecipeEditorState();
}

class _RecipeEditorState extends State<RecipeEditor> {
  late final RecipeData recipe = widget.recipe.copy();
  late final RecipeRepository repository =
      widget.repository ?? RecipeRepository();
  final form = GlobalKey<FormState>();
  late int nextId;
  late bool dirty =
      widget.id == null &&
      (recipe.name.isNotEmpty ||
          recipe.description.isNotEmpty ||
          recipe.ingredients.isNotEmpty ||
          recipe.stages.isNotEmpty ||
          recipe.notes.isNotEmpty ||
          recipe.preparations.isNotEmpty);

  String changeDescription = '';
  bool saving = false;
  String? error;
  String? coverPath;
  bool allowPop = false;

  @override
  void initState() {
    super.initState();
    nextId = recipe.nextId;
  }

  Future<bool> confirm(String text, String action) async {
    final s = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(text),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> leave() async {
    if (saving) return;
    final s = AppLocalizations.of(context)!;
    if (dirty && !await confirm(s.discardChanges, s.discard)) return;
    if (!mounted) return;
    setState(() => allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final s = AppLocalizations.of(context)!;
    final issues = recipe.validate();
    if (issues.isNotEmpty) {
      setState(
        () => error = issues.map((e) => recipeIssueText(s, e)).join('\n'),
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (await repository.hasDuplicateName(recipe.name, exceptId: widget.id)) {
        if (!mounted || !await confirm(s.duplicateName, s.saveAnother)) return;
      }
      if (coverPath != null) {
        recipe.image = await RecipeImage.copyCover(coverPath!);
        coverPath = null;
      }
      final id = await repository.save(
        recipe,
        id: widget.id,
        changeDescription: changeDescription,
      );
      if (!mounted) return;
      setState(() {
        dirty = false;
        allowPop = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, id);
      });
    } on FormatException {
      if (mounted) setState(() => error = s.invalidPreparations);
    } catch (_) {
      if (mounted) setState(() => error = s.saveError);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget text(
    String label,
    String initial,
    ValueChanged<String> change, {
    int lines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    key: ValueKey(label),
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      initialValue: initial,
      decoration: InputDecoration(labelText: label),
      maxLines: lines,
      onChanged: (v) => modify(() => change(v)),
      validator: validator,
    ),
  );

  Widget number(
    String label,
    num? value,
    ValueChanged<num?> change, {
    bool integer = false,
    bool signed = false,
    required String message,
  }) => text(
    label,
    value?.toString() ?? '',
    (v) {
      final normalized = v.trim().replaceAll(',', '.');
      change(integer ? int.tryParse(normalized) : double.tryParse(normalized));
    },
    validator: (v) {
      if (v == null || v.trim().isEmpty) return null;
      final normalized = v.trim().replaceAll(',', '.');
      final value = integer
          ? int.tryParse(normalized)
          : double.tryParse(normalized);
      return value == null || !value.isFinite || !signed && value < 0
          ? message
          : null;
    },
  );

  void modify(VoidCallback change) => setState(() {
    dirty = true;
    change();
  });

  Widget controls(
    int index,
    int length,
    VoidCallback up,
    VoidCallback down,
    VoidCallback remove,
  ) {
    final s = AppLocalizations.of(context)!;
    return Wrap(
      children: [
        IconButton(
          tooltip: s.moveUp,
          onPressed: index == 0 ? null : () => modify(up),
          icon: const Icon(Icons.arrow_upward),
        ),
        IconButton(
          tooltip: s.moveDown,
          onPressed: index == length - 1 ? null : () => modify(down),
          icon: const Icon(Icons.arrow_downward),
        ),
        IconButton(
          tooltip: s.remove,
          onPressed: () => modify(remove),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  void move<T>(List<T> list, int from, int to) {
    final item = list.removeAt(from);
    list.insert(to, item);
  }

  Future<void> cover() async {
    final s = AppLocalizations.of(context)!;
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            extensions: ['jpg', 'jpeg', 'png'],
            uniformTypeIdentifiers: ['public.jpeg', 'public.png'],
          ),
        ],
      );
      if (file != null && mounted) modify(() => coverPath = file.path);
    } catch (_) {
      if (mounted) setState(() => error = s.importError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return PopScope(
      canPop: allowPop || !dirty && !saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.id == null ? s.addRecipe : s.editRecipe),
          actions: [
            TextButton(
              key: const ValueKey('saveRecipe'),
              onPressed: saving ? null : save,
              child: Text(s.saveRecipe),
            ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: saving,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (saving) const LinearProgressIndicator(),
                      if (widget.notice != null) Text(widget.notice!),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      text(
                        s.recipeName,
                        recipe.name,
                        (v) => recipe.name = v,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? s.nameRequired
                            : null,
                      ),
                      text(
                        s.recipeDescription,
                        recipe.description,
                        (v) => recipe.description = v,
                        lines: 3,
                      ),
                      if (coverPath != null) Text(coverPath!.split('/').last),
                      if (recipe.image != null)
                        RecipeImage(image: recipe.image, height: 140),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: cover,
                            child: Text(s.chooseCover),
                          ),
                          if (recipe.image != null || coverPath != null)
                            TextButton(
                              onPressed: () => modify(() {
                                recipe.image = null;
                                coverPath = null;
                              }),
                              child: Text(s.removeCover),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      RecipeEditorSection(
                        title: s.ingredientsLabel,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < recipe.ingredients.length; i++)
                              ingredient(recipe.ingredients[i], i),
                            OutlinedButton.icon(
                              onPressed: () => modify(
                                () => recipe.ingredients.add(
                                  RecipeIngredient(id: nextId++),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(s.addIngredient),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      RecipeEditorSection(
                        title: s.stagesLabel,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < recipe.stages.length; i++)
                              stage(recipe.stages[i], i),
                            OutlinedButton.icon(
                              onPressed: () => modify(
                                () => recipe.stages.add(
                                  RecipeStage(id: nextId++),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(s.addStage),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      RecipePreparationsFields(
                        recipe: recipe,
                        recipeId: widget.id,
                        repository: repository,
                        onChanged: () => modify(() {}),
                      ),
                      const SizedBox(height: 24),
                      RecipeEditorSection(
                        title: s.variantNotes,
                        child: RecipeNotesFields(
                          notes: recipe.notes,
                          onChanged: () => modify(() {}),
                        ),
                      ),
                      if (widget.id != null) ...[
                        const SizedBox(height: 16),
                        text(
                          s.changeDescription,
                          changeDescription,
                          (v) => changeDescription = v,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(s.draftNotice),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: saving ? null : save,
                        child: Text(s.saveRecipe),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget ingredient(RecipeIngredient item, int index) {
    final s = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      key: ObjectKey(item),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            controls(
              index,
              recipe.ingredients.length,
              () => move(recipe.ingredients, index, index - 1),
              () => move(recipe.ingredients, index, index + 1),
              () => recipe.ingredients.removeAt(index),
            ),
            text(s.recipeName, item.name, (v) => item.name = v),
            number(
              s.amountLabel,
              item.amount,
              (v) => item.amount = v?.toDouble(),
              message: s.invalidQuantity,
            ),
            RecipeUnitInput(
              value: item.unit,
              onChanged: (v) => modify(() => item.unit = v),
            ),
            text(s.conditionLabel, item.condition, (v) => item.condition = v),
          ],
        ),
      ),
    );
  }

  Widget stage(RecipeStage item, int index) {
    final s = AppLocalizations.of(context)!;
    final options = <int, String>{
      for (final ingredient in recipe.ingredients)
        ingredient.id: ingredient.name,
      for (final stage in recipe.stages.take(index)) stage.id: stage.name,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      key: ObjectKey(item),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            controls(
              index,
              recipe.stages.length,
              () => move(recipe.stages, index, index - 1),
              () => move(recipe.stages, index, index + 1),
              () => recipe.stages.removeAt(index),
            ),
            text(s.recipeName, item.name, (v) => item.name = v),
            text(
              s.recipeDescription,
              item.description,
              (v) => item.description = v,
              lines: 3,
            ),
            RecipeDurationInput(
              key: const ValueKey('durationMin'),
              label: s.durationMinimum,
              minutes: item.durationMin,
              onChanged: (v) => modify(() => item.durationMin = v),
            ),
            RecipeDurationInput(
              key: const ValueKey('durationMax'),
              label: s.durationMaximum,
              minutes: item.durationMax,
              onChanged: (v) => modify(() => item.durationMax = v),
            ),
            number(
              s.temperatureMinLabel,
              item.temperatureMin,
              (v) => item.temperatureMin = v?.toInt(),
              integer: true,
              signed: true,
              message: s.invalidTemperature,
            ),
            number(
              s.temperatureMaxLabel,
              item.temperatureMax,
              (v) => item.temperatureMax = v?.toInt(),
              integer: true,
              signed: true,
              message: s.invalidTemperature,
            ),
            for (final ref in item.ingredients)
              Padding(
                key: ObjectKey(ref),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      key: ValueKey('${ref.id}:${options.keys.join(',')}'),
                      initialValue: options.containsKey(ref.id) ? ref.id : null,
                      decoration: InputDecoration(labelText: s.referenceLabel),
                      items: options.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.value.isEmpty ? '#${e.key}' : e.value,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) modify(() => ref.id = v);
                      },
                      validator: (_) => options.containsKey(ref.id)
                          ? null
                          : s.invalidReferences,
                    ),
                    number(
                      s.amountLabel,
                      ref.amount,
                      (v) => ref.amount = v?.toDouble(),
                      message: s.invalidQuantity,
                    ),
                    text(
                      s.conditionLabel,
                      ref.condition,
                      (v) => ref.condition = v,
                    ),
                    TextButton(
                      onPressed: () =>
                          modify(() => item.ingredients.remove(ref)),
                      child: Text(s.remove),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed:
                  options.keys.any(
                    (id) => !item.ingredients.any((ref) => ref.id == id),
                  )
                  ? () => modify(
                      () => item.ingredients.add(
                        IngredientReference(
                          id: options.keys.firstWhere(
                            (id) =>
                                !item.ingredients.any((ref) => ref.id == id),
                          ),
                        ),
                      ),
                    )
                  : null,
              icon: const Icon(Icons.add),
              label: Text(s.addReference),
            ),
          ],
        ),
      ),
    );
  }
}
