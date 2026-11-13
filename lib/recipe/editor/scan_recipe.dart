import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/recipe_extractor.dart';
import 'recipe_editor.dart';

class ScanRecipe extends StatefulWidget {
  const ScanRecipe({super.key});
  @override
  State<ScanRecipe> createState() => _ScanRecipeState();
}

class _ScanRecipeState extends State<ScanRecipe> {
  final files = <XFile>[];
  RecipeExtractor? extractor;
  bool busy = false;
  String? error;
  int generation = 0;
  @override
  void dispose() {
    extractor?.cancel();
    super.dispose();
  }

  String message(ScanError reason) {
    final s = AppLocalizations.of(context)!;
    return switch (reason) {
      ScanError.auth => s.scanAuthError,
      ScanError.rate => s.scanRateError,
      ScanError.network => s.scanNetworkError,
      ScanError.output => s.scanOutputError,
      ScanError.file => s.scanFileError,
      ScanError.cancelled => s.cancel,
    };
  }

  Future<void> choose() async {
    try {
      final selected = await openFiles(
        acceptedTypeGroups: [
          const XTypeGroup(
            extensions: ['pdf', 'jpg', 'jpeg', 'png'],
            uniformTypeIdentifiers: [
              'com.adobe.pdf',
              'public.jpeg',
              'public.png',
            ],
          ),
        ],
      );
      if (selected.isEmpty || !mounted) return;
      if (selected.length > 10 ||
          selected.any((f) => f.name.toLowerCase().endsWith('.pdf')) &&
              selected.length != 1) {
        setState(() => error = message(ScanError.file));
        return;
      }
      setState(() {
        files
          ..clear()
          ..addAll(selected);
        error = null;
      });
    } catch (_) {
      if (mounted) setState(() => error = message(ScanError.file));
    }
  }

  Future<void> extract() async {
    final s = AppLocalizations.of(context)!;
    final token = ++generation;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final key = await ApiKeyStore().read();
      if (!mounted || token != generation) return;
      if (key == null || key.isEmpty) {
        setState(() => error = s.keyRequired);
        return;
      }
      final selectedFiles = List<XFile>.of(files);
      final documents = <ScanDocument>[];
      var total = 0;
      for (final file in selectedFiles) {
        total += await file.length();
        if (total > 20 * 1024 * 1024) throw const ScanFailure(ScanError.file);
        documents.add(ScanDocument(file.name, await file.readAsBytes()));
      }
      if (!mounted || token != generation) return;
      extractor = RecipeExtractor();
      final result = await extractor!.extract(documents, key);
      if (!mounted || token != generation) return;
      setState(() => busy = false);
      final id = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (context) => RecipeEditor(
            recipe: result.recipe,
            notice: [s.scanReview, ...result.warnings].join('\n'),
          ),
        ),
      );
      if (mounted && id != null) Navigator.pop(context, id);
    } on ScanFailure catch (failure) {
      if (mounted && token == generation) {
        setState(() => error = message(failure.reason));
      }
    } catch (_) {
      if (mounted && token == generation) setState(() => error = s.keyError);
    } finally {
      if (mounted && token == generation) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.scanRecipe)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(s.scanDisclosure),
              const SizedBox(height: 16),
              Text(s.scanLimits),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: busy ? null : choose,
                child: Text(s.chooseFiles),
              ),
              for (var i = 0; i < files.length; i++)
                ListTile(
                  title: Text(files[i].name),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: s.moveUp,
                        onPressed: busy || i == 0
                            ? null
                            : () => setState(() {
                                final file = files.removeAt(i);
                                files.insert(i - 1, file);
                              }),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: s.moveDown,
                        onPressed: busy || i == files.length - 1
                            ? null
                            : () => setState(() {
                                final file = files.removeAt(i);
                                files.insert(i + 1, file);
                              }),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      IconButton(
                        tooltip: s.remove,
                        onPressed: busy
                            ? null
                            : () => setState(() => files.removeAt(i)),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (busy) ...[
                const LinearProgressIndicator(),
                Text(s.scanBusy),
                TextButton(
                  onPressed: () {
                    generation++;
                    extractor?.cancel();
                    setState(() => busy = false);
                  },
                  child: Text(s.cancel),
                ),
              ] else
                FilledButton(
                  onPressed: files.isEmpty ? null : extract,
                  child: Text(s.extractRecipe),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AiSettings extends StatefulWidget {
  const AiSettings({super.key});
  @override
  State<AiSettings> createState() => _AiSettingsState();
}

class _AiSettingsState extends State<AiSettings> {
  final controller = TextEditingController();
  final store = ApiKeyStore();
  bool stored = false;
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final key = await store.read();
      if (mounted) setState(() => stored = key?.isNotEmpty ?? false);
    } catch (_) {
      if (mounted) {
        setState(() => error = AppLocalizations.of(context)!.keyError);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> change(bool remove) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (remove) {
        await store.delete();
      } else {
        await store.write(controller.text.trim());
      }
      controller.clear();
      if (mounted) setState(() => stored = !remove);
    } catch (_) {
      if (mounted) {
        setState(() => error = AppLocalizations.of(context)!.keyError);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.aiSettings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.aiSettingsDescription,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                if (busy) const LinearProgressIndicator(),
                if (stored)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(s.keyStored),
                  ),
                TextField(
                  controller: controller,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(labelText: s.apiKeyLabel),
                  onChanged: (_) => setState(() {}),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: busy || controller.text.trim().isEmpty
                          ? null
                          : () => change(false),
                      child: Text(s.saveKey),
                    ),
                    if (stored)
                      TextButton(
                        onPressed: busy ? null : () => change(true),
                        child: Text(s.deleteKey),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
