import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'navigation.dart';

void main() => runApp(const Backomat());

class Backomat extends StatelessWidget {
  const Backomat({Key? key}) : super(key: key);

  static const String _title = 'Backomat';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
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
