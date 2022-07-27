import 'package:flutter/material.dart';

void main() {
  runApp(const Backomat());
}

class Backomat extends StatelessWidget {
  const Backomat({super.key});

  void _addWorkListItem() {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backomat',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Backomat'),
        ),
        body: Center(
          child: WorkListItem(
              name: 'do something', start: DateTime.now(), end: DateTime.now()),
        ),
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
  WorkListItem({
    required this.name,
    required this.start,
    required this.end,
  }) : super(key: ObjectKey(name));

  final String name;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.red,
        child: Text("1"),
      ),
      title: Text(name + start.toIso8601String() + end.toIso8601String()),
    );
  }
}
