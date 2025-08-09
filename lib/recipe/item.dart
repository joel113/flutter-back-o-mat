import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/recipe/item_ingredients.dart';

import '../util/json.dart';
import 'item_stages.dart';

class Item extends StatelessWidget {
  Item(
      {required this.image,
      required this.name,
      required this.description,
      required this.ingredients,
      required this.stages})
      : super(key: ObjectKey(name));

  final String image;
  final String name;
  final String description;
  final ItemIngredients ingredients;
  final ItemStages stages;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          Text(
            description,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Item.fromJson(Map<String, dynamic> json, {super.key, showTimer = false})
      : image = json['image'],
        name = json['name'],
        description = json['description'],
        ingredients = ItemIngredients.fromJson(json['ingredients']),
        stages = ItemStages.fromJson(
            Json.mapify(json['ingredients'], json['stages']), json['stages'],
            showTimer: showTimer);
}
