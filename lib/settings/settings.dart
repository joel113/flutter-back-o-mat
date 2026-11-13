import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../recipe/editor/scan_recipe.dart';
import '../theme/app_components.dart';

class AppSettings extends StatelessWidget {
  const AppSettings({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return AppPage(
      title: s.settings,
      subtitle: s.settingsSubtitle,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.document_scanner_outlined,
                color: colors.primary,
              ),
              title: Text(s.aiSettings),
              subtitle: Text(s.aiSettingsDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const AiSettings()),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.brightness_auto_outlined),
              title: Text(s.appearance),
              subtitle: Text(s.systemAppearance),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),
            Text(s.aboutApp, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: AppLogo(size: 56),
            ),
            const SizedBox(height: 12),
            Text(s.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(s.aboutDescription),
          ],
        ),
      ),
    );
  }
}
