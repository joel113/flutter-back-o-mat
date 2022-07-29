import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(Backomat(worklistitems: [
    WorkListItem(
        step: 1,
        name: 'Sauerteig ansetzen',
        description: 'Sauerteig mit genügen Mehl ansetzen',
        start: DateTime.now().add(const Duration(hours: 2)),
        end: DateTime.now().add(const Duration(hours: 2))),
    WorkListItem(
        step: 2,
        name: 'Sauerteig ansetzen',
        description: 'Sauerteig mit genügen Mehl ansetzen',
        start: DateTime.now().add(const Duration(hours: 4)),
        end: DateTime.now().add(const Duration(hours: 4)))
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
      ),
    );
  }
}

class WorkListItem extends StatelessWidget {
  WorkListItem(
      {required this.step,
      required this.name,
      required this.description,
      required this.start,
      required this.end,
      this.predecessor})
      : super(key: ObjectKey(name));

  final int step;
  final String name;
  final String? description;
  final DateTime start;
  final DateTime end;
  final WorkListItem? predecessor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red,
        child: Text(step.toString()),
      ),
      title: Text("$name     ${DateFormat('E HH:mm').format(start)}"),
      subtitle: Text(description!),
      trailing: const Icon(Icons.more_vert),
    );
  }
}
