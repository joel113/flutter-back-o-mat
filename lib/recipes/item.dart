import 'package:flutter/material.dart';

import '../recipe/recipe.dart';

class Item extends StatelessWidget {
  Item({required this.image, required this.name, required this.description})
      : super(key: ObjectKey(name));

  final Image image;
  final String name;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: <Widget>[
          Expanded(child: Container(
              padding: const EdgeInsets.only(right: 10), child: image)),
          Expanded(flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(description!),
                ],
              )),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.pink),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Recipe())
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.aspect_ratio),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Recipe())
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.av_timer),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Recipe())
              );
            },
          ),
        ],
      ),
    );
  }

  void openMenu() {}
}
