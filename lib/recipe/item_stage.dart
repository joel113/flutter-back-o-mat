import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/recipe/item_duration.dart';
import 'package:flutter_back_o_mat/recipe/item_ingredients.dart';

import '../util/json.dart';
import 'item_temperature.dart';

class ItemStage extends StatelessWidget {
  ItemStage(
      {required this.id,
      required this.name,
      required this.ingredients,
      required this.description,
      required this.duration,
      required this.temperature})
      : super(key: ObjectKey(id));

  final int id;
  final String name;
  final ItemIngredients ingredients;
  final String description;
  final ItemDuration duration;
  final ItemTemperature? temperature;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }

  TableRow buildRow(BuildContext context) {
    var row = TableRow(
      children: [
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(name))),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ingredients,
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(description))
                  ],
                ))),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Column(
                  children: [
                    temperature != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: temperature!)
                        : Container(),
                    duration
                  ],
                ))),
      ],
    );
    return row;
  }

  TableRow buildRowWithTimer(BuildContext context) {
    var row = TableRow(
      children: [
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(name))),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    temperature != null
                        ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: temperature!)
                        : Container(),
                    duration
                  ],
                ))),
        const TableCell(child: Text(""))
      ],
    );
    return row;
  }

  ItemStage.fromJson(
      Map<dynamic, dynamic> ingredients, Map<String, dynamic> json,
      {Key? key})
      : id = json['id'],
        name = json['name'],
        ingredients = ItemIngredients.fromJson(
            Json.merge(ingredients, json['ingredients'])),
        description = json['description'],
        duration = ItemDuration.fromJson(json['duration']),
        temperature = (json['temperature'] != null)
            ? ItemTemperature.fromJson(json['temperature'])
            : null,
        super(key: key);
}
