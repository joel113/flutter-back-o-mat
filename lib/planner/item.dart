import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Item extends StatelessWidget {
  Item(
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
  final Item? predecessor;

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
