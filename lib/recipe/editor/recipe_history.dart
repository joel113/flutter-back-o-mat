import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/recipe_data.dart';
import '../data/recipe_family.dart';
import '../data/recipe_repository.dart';
import 'recipe_view.dart';

class RecipeHistory extends StatefulWidget {
  const RecipeHistory({
    super.key,
    required this.ownerId,
    required this.repository,
    this.sharedNotes = false,
  });
  final int ownerId;
  final RecipeRepository repository;
  final bool sharedNotes;
  @override
  State<RecipeHistory> createState() => _RecipeHistoryState();
}

class _RecipeHistoryState extends State<RecipeHistory> {
  late Future<List<RecipeRevision>> revisions = read();
  Future<List<RecipeRevision>> read() => widget.repository.revisions(
    widget.ownerId,
    sharedNotes: widget.sharedNotes,
  );
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sharedNotes ? s.sharedNotesHistory : s.history),
      ),
      body: FutureBuilder<List<RecipeRevision>>(
        future: revisions,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.revisionLoadError),
                  TextButton(
                    onPressed: () => setState(() {
                      revisions = read();
                    }),
                    child: Text(s.retry),
                  ),
                ],
              ),
            );
          }
          final rows = snapshot.data!;
          if (rows.isEmpty) return Center(child: Text(s.noRevisions));
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final revision = rows[i];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  MaterialLocalizations.of(context)
                      .formatFullDate(revision.createdAt),
                ),
                subtitle: Text(
                  [
                    TimeOfDay.fromDateTime(revision.createdAt).format(context),
                    if (revision.description.isNotEmpty) revision.description,
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _RevisionPreview(
                        ownerId: widget.ownerId,
                        sharedNotes: widget.sharedNotes,
                        revision: revision,
                        repository: widget.repository,
                      ),
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      revisions = read();
                    });
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RevisionPreview extends StatefulWidget {
  const _RevisionPreview({
    required this.ownerId,
    required this.sharedNotes,
    required this.revision,
    required this.repository,
  });
  final int ownerId;
  final bool sharedNotes;
  final RecipeRevision revision;
  final RecipeRepository repository;
  @override
  State<_RevisionPreview> createState() => _RevisionPreviewState();
}

class _RevisionPreviewState extends State<_RevisionPreview> {
  bool busy = false;
  Future<void> restore() async {
    final s = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(s.restoreRevisionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.restoreRevision),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.repository.restore(
        widget.ownerId,
        widget.revision.id,
        sharedNotes: widget.sharedNotes,
        changeDescription: s.restoredRevision,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.saveError)));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final action = TextButton(
      onPressed: busy ? null : restore,
      child: Text(s.restoreRevision),
    );
    return PopScope(
      canPop: !busy,
      child: widget.sharedNotes
          ? Scaffold(
              appBar: AppBar(title: Text(s.revisionPreview), actions: [action]),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final note in RecipeRepository.decodeNotes(
                      widget.revision.content,
                    )) ...[
                      Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(note.body),
                      const SizedBox(height: 24),
                    ],
                    if (RecipeRepository.decodeNotes(widget.revision.content)
                        .isEmpty)
                      Text(s.noNotes),
                  ],
                ),
              ),
            )
          : RecipeView(
              id: widget.ownerId,
              preview: RecipeData.fromJson(
                jsonDecode(widget.revision.content) as Map<String, dynamic>,
              ),
              previewActions: [action],
            ),
    );
  }
}
