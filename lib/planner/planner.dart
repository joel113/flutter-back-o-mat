import 'package:flutter/material.dart';
import 'item.dart';

class BackomatPlanner extends StatefulWidget {
  const BackomatPlanner({Key? key}) : super(key: key);

  @override
  State<BackomatPlanner> createState() => _BackomatPlannerState();
}

class _BackomatPlannerState extends State<BackomatPlanner> {
  final _workList = <Item>[
    Item(
        name: 'Sauerteig auffrischen',
        description: 'Sauerteig auffrischen',
        minDuration: const Duration(hours: 8),
        maxDuration: const Duration(hours: 10)),
    Item(
        name: 'Sauerteig Stufe 1',
        description: 'Sauerteig Stufe 1',
        minDuration: const Duration(hours: 12),
        maxDuration: const Duration(hours: 16)),
    Item(
        name: 'Sauerteig Stufe 3',
        description: 'Sauerteig Stufe 3',
        minDuration: const Duration(hours: 2),
        maxDuration: const Duration(hours: 2)),
    Item(
        name: 'Brühstück',
        description: 'Brühstück',
        minDuration: const Duration(hours: 8),
        maxDuration: const Duration(hours: 16)),
    Item(
        name: 'Hauptteig',
        description: 'Hauptteig',
        minDuration: const Duration(hours: 1),
        maxDuration: const Duration(hours: 1)),
    Item(
        name: 'Stückgare',
        description: 'Stückgare',
        minDuration: const Duration(minutes: 45),
        maxDuration: const Duration(minutes: 45)),
    Item(
        name: 'Backen',
        description: 'Backen',
        minDuration: const Duration(hours: 1),
        maxDuration: const Duration(hours: 1))
  ];

  void _addItem() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _addItem,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ), // This trailing comma makes auto-formatting nicer for build methods.
        body: ListView(children: _workList.toList()));
  }
}
