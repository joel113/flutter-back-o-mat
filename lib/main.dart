import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/util/db/db_recipe_importer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final importer = RecipeJsonImporter();
  await importer.importRecipesFromAssets();
  runApp(Backomat());
}

class Backomat extends StatelessWidget {
  const Backomat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppLocalizations.of(context)?.title,
      home: BackomatNavigation(),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''),
        Locale('de', ''),
      ],
    );
  }
}
