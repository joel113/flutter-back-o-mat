import 'package:flutter/material.dart';
import 'item.dart';

class BackomatReceipes extends StatefulWidget {
  const BackomatReceipes({Key? key}) : super(key: key);

  @override
  State<BackomatReceipes> createState() => _BackomatReceipesState();
}

class _BackomatReceipesState extends State<BackomatReceipes> {
  final _receipesList = <Item>[
    Item(
      name: 'Rezept 1',
      description: 'halt Rezept 1',
    ),
    Item(
      name: 'Rezept 2',
      description: 'halt Rezept 2',
    )
  ];

  void _addItem() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ListView(children: _receipesList.toList()));
  }

}