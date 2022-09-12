import 'package:flutter/material.dart';

class Item extends StatelessWidget {
  Item(
      {required this.name,
        required this.description})
      : super(key: ObjectKey(name));

  final String name;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: <Widget>[
          Expanded(flex: 1, child: Text(name)),
          Expanded(flex: 3, child: Text(description!)),
          const Icon(Icons.more_vert),
        ],
      ),
    );
  }
}
