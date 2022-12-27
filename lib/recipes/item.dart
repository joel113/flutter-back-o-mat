import 'package:flutter/material.dart';

import '../recipe/recipe.dart';

class Item extends StatelessWidget {
  Item({required this.filename, required this.image, required this.name, required this.description})
      : super(key: ObjectKey(name));

  final String filename;
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
                  MaterialPageRoute(builder: (context) => BackometRecipe(filename: filename))
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.aspect_ratio),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BackometRecipe(filename: filename))
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.not_started_outlined),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BackometRecipe(filename: filename))
              );
            },
          ),
        ],
      ),
    );
  }
}
