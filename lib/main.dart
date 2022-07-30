import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(Backomat(worklistitems: [
    WorkListItem(
        name: 'Sauerteig auffrischen',
        description: 'Sauerteig auffrischen',
        minDuration: const Duration(hours: 8),
        maxDuration: const Duration(hours: 10)),
    WorkListItem(
        name: 'Sauerteig Stufe 1',
        description: 'Sauerteig Stufe 1',
        minDuration: const Duration(hours: 12),
        maxDuration: const Duration(hours: 16)),
    WorkListItem(
        name: 'Sauerteig Stufe 3',
        description: 'Sauerteig Stufe 3',
        minDuration: const Duration(hours: 2),
        maxDuration: const Duration(hours: 2)),
    WorkListItem(
        name: 'Brühstück',
        description: 'Brühstück',
        minDuration: const Duration(hours: 8),
        maxDuration: const Duration(hours: 16)),
    WorkListItem(
        name: 'Hauptteig',
        description: 'Hauptteig',
        minDuration: const Duration(hours: 1),
        maxDuration: const Duration(hours: 1)),
    WorkListItem(
        name: 'Stückgare',
        description: 'Stückgare',
        minDuration: const Duration(minutes: 45),
        maxDuration: const Duration(minutes: 45)),
    WorkListItem(
        name: 'Backen',
        description: 'Backen',
        minDuration: const Duration(hours: 1),
        maxDuration: const Duration(hours: 1))
  ]));
}

class Backomat extends StatefulWidget {
  const Backomat({required this.worklistitems, super.key});

  final List<WorkListItem> worklistitems;

  @override
  State<Backomat> createState() => _WorkListState();
}

class _WorkListState extends State<Backomat> {
  final _workList = <WorkListItem>{};

  void _addWorkListItem() {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backomat',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Backomat'),
        ),
        body: ListView(children: widget.worklistitems.toList()),
        floatingActionButton: FloatingActionButton(
          onPressed: _addWorkListItem,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}

class WorkListItem extends StatelessWidget {
  WorkListItem(
      {required this.name,
      required this.description,
      required this.minDuration,
      required this.maxDuration,
      this.predecessor})
      : super(key: ObjectKey(name));

  final String name;
  final String? description;
  final Duration minDuration;
  final Duration maxDuration;
  final WorkListItem? predecessor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.red,
        child: Text("?"),
      ),
      title: Text(
          "$name     ${DateFormat('E HH:mm').format(DateTime.now().add(minDuration))}"),
      subtitle: Text(description!),
      trailing: const Icon(Icons.more_vert),
    );
  }
}
