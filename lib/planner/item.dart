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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        children: <Widget>[
          const Expanded(
              child: CircleAvatar(
            backgroundColor: Colors.purple,
            child: Text("1"),
          )),
          Expanded(flex: 2, child: Text(name)),
          Expanded(
              flex: 3,
              child: Text(DateFormat('E HH:mm')
                  .format(DateTime.now().add(minDuration)))),
          const Icon(Icons.more_vert),
        ],
      ),
    );
  }
}
