import 'package:flutter/material.dart';
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
    );
  }
}
