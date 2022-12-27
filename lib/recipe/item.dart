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
    // TODO: implement
  }
}