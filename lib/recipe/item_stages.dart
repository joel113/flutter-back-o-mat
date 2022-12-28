import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/recipe/item_duration.dart';
import 'package:flutter_back_o_mat/recipe/item_ingredient.dart';

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
  final List<ItemIngredient> ingredients;
  final String description;
  final ItemDuration duration;
  final ItemTemperature? temperature;

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  ItemStages.fromJson(Map<String, dynamic> json, {Key? key})
      : id = json['id'],
        name = json['name'],
        ingredients = List<ItemIngredient>.from(json['ingredients']
            .map<ItemIngredient>((v) => ItemIngredient.fromJson(v))),
        description = json['description'],
        duration = ItemDuration.fromJson(json['duration']),
        temperature = (json['temperature'] != null)
            ? ItemTemperature.fromJson(json['temperature'])
            : null,
        super(key: key);
}
