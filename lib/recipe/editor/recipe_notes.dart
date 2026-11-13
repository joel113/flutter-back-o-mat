import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_components.dart';
import '../data/recipe_data.dart';
import '../data/recipe_repository.dart';

class RecipeNotesFields extends StatelessWidget {
  const RecipeNotesFields({
    super.key,
    required this.notes,
    required this.onChanged,
  });
  final List<RecipeNote> notes;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < notes.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            key: ObjectKey(notes[i]),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: s.moveUp,
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: i == 0
                            ? null
                            : () {
                                final n = notes.removeAt(i);
                                notes.insert(i - 1, n);
                                onChanged();
                              },
                      ),
                      IconButton(
                        tooltip: s.moveDown,
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: i == notes.length - 1
                            ? null
                            : () {
                                final n = notes.removeAt(i);
                                notes.insert(i + 1, n);
                                onChanged();
                              },
                      ),
                      IconButton(
                        tooltip: s.remove,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          notes.removeAt(i);
                          onChanged();
                        },
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: notes[i].title,
                    decoration: InputDecoration(labelText: s.noteTitle),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? s.noteTitleRequired
                        : null,
                    onChanged: (v) {
                      notes[i].title = v;
                      onChanged();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: notes[i].body,
                    minLines: 3,
                    maxLines: null,
                    decoration: InputDecoration(labelText: s.noteBody),
                    onChanged: (v) {
                      notes[i].body = v;
                      onChanged();
                    },
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () {
            notes.add(RecipeNote());
            onChanged();
          },
          icon: const Icon(Icons.add),
          label: Text(s.addNote),
        ),
      ],
    );
  }
}

class RecipeNotesSection extends StatelessWidget {
  const RecipeNotesSection({
    super.key,
    required this.notes,
    this.shared = const [],
    this.onEditShared,
    this.onEditVariant,
    this.onSharedHistory,
    this.showShared = true,
  });
  final List<RecipeNote> notes;
  final List<RecipeNote> shared;
  final VoidCallback? onEditShared;
  final VoidCallback? onEditVariant;
  final VoidCallback? onSharedHistory;
  final bool showShared;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    Widget group(String label, List<RecipeNote> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (items.isEmpty) Text(s.noNotes),
        for (final n in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: Theme.of(context).textTheme.titleMedium),
                if (n.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SelectableText(n.body),
                ],
              ],
            ),
          ),
      ],
    );
    return AppSurface(
      child: ExpansionTile(
        title: Text(s.notesLabel),
        leading: const Icon(Icons.notes_outlined),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showShared) group(s.sharedNotes, shared),
          if (onEditShared != null || onSharedHistory != null)
            Wrap(
              spacing: 8,
              children: [
                if (onEditShared != null)
                  TextButton.icon(
                    onPressed: onEditShared,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(s.editSharedNotes),
                  ),
                if (onSharedHistory != null)
                  TextButton.icon(
                    onPressed: onSharedHistory,
                    icon: const Icon(Icons.history),
                    label: Text(s.sharedNotesHistory),
                  ),
              ],
            ),
          if (showShared) const SizedBox(height: 16),
          group(s.variantNotes, notes),
          if (onEditVariant != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onEditVariant,
                icon: const Icon(Icons.edit_outlined),
                label: Text(s.editRecipe),
              ),
            ),
        ],
      ),
    );
  }
}

class SharedNotesEditor extends StatefulWidget {
  const SharedNotesEditor({
    super.key,
    required this.familyId,
    required this.notes,
    required this.repository,
  });
  final int familyId;
  final List<RecipeNote> notes;
  final RecipeRepository repository;
  @override
  State<SharedNotesEditor> createState() => _SharedNotesEditorState();
}

class _SharedNotesEditorState extends State<SharedNotesEditor> {
  late final notes = widget.notes.map((n) => n.copy()).toList();
  final form = GlobalKey<FormState>();
  String description = '';
  bool dirty = false, busy = false, allowPop = false;
  String? error;

  Future<void> leave() async {
    if (busy) return;
    final s = AppLocalizations.of(context)!;
    if (dirty &&
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                content: Text(s.discardChanges),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(s.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(s.discard),
                  ),
                ],
              ),
            ) !=
            true) {
      return;
    }
    if (!mounted) return;
    setState(() => allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final s = AppLocalizations.of(context)!;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.saveSharedNotes(
        widget.familyId,
        notes,
        changeDescription: description,
      );
      if (!mounted) return;
      setState(() {
        allowPop = true;
        dirty = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } catch (_) {
      if (mounted) setState(() => error = s.saveError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return PopScope(
      canPop: allowPop || !dirty && !busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.sharedNotes),
          actions: [
            TextButton(onPressed: busy ? null : save, child: Text(s.saveNotes)),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: AbsorbPointer(
                absorbing: busy,
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (busy) const LinearProgressIndicator(),
                      if (error != null)
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      RecipeNotesFields(
                        notes: notes,
                        onChanged: () => setState(() => dirty = true),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: s.changeDescription,
                        ),
                        onChanged: (v) => setState(() {
                          description = v;
                          dirty = true;
                        }),
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
}
