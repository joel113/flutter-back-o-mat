import 'package:flutter/material.dart';

import 'item_ingredients.dart';
import 'item_stages.dart';

class Item extends StatelessWidget {
  Item({required this.name, required this.ingredients, required this.stages})
      : super(key: ObjectKey(name));

  final String name;
  final List<ItemIngredients> ingredients;
  final List<ItemStages> stages;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: const Text(
              'Bergkruste',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'Sauerteigbrot mit Roggen und Dinkel',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Item.fromJson(Map<String, dynamic> json, {Key? key})
      : name = json['name'],
        ingredients = List<ItemIngredients>.from(json['ingredients']
            .map<ItemIngredients>((v) => ItemIngredients.fromJson(v))),
        stages = List<ItemStages>.from(
            json['stages'].map((v) => ItemStages.fromJson(v))),
        super(key: key);
}
