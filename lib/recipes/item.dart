import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/recipe/backer.dart';

import '../recipe/recipe.dart';

class Item extends StatelessWidget {
  Item(
      {required this.id,
      required this.image,
      required this.name,
      required this.description})
      : super(key: ObjectKey(name));

  final int id;
  final Image image;
  final String name;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          Expanded(
              child: Container(
                  padding: const EdgeInsets.only(right: 8), child: image)),
          Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(description!, style: const TextStyle(fontSize: 16)),
                ],
              )),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.pink),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          BackomatRecipe(id: id)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.aspect_ratio),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          BackomatRecipe(id: id)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.not_started_outlined),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          BackomatBacker(id: id)));
            },
          ),
        ],
      ),
    );
  }
}
