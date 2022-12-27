import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/recipe/item_duration.dart';
import 'package:flutter_back_o_mat/recipe/item_ingredients.dart';

import 'item_temperature.dart';

class ItemStages extends StatelessWidget {
  ItemStages(
      {required this.id,
      required this.name,
      required this.ingredients,
      required this.description,
      required this.duration,
      required this.temperature})
      : super(key: ObjectKey(id));

  final int id;
  final String name;
  final List<ItemIngredients> ingredients;
  final String description;
  final ItemDuration duration;
  final ItemTemperature temperature;

  @override
  Widget build(BuildContext context) {
    // TODO: implement
  }
}
