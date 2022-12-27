import 'package:flutter/material.dart';

class ItemIngredients extends StatelessWidget {
  ItemIngredients({
    required this.id,
    required this.amount,
    required this.unit,
    required this.condition,
    this.name,
  }) : super(key: ObjectKey(id));

  final int id;
  final String? name;
  final double? amount;
  final String? unit;
  final String? condition;

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  ItemIngredients.fromJson(Map<String, dynamic> json, {Key? key})
      : id = json['id'],
        name = json['name'],
        amount = json['amount'],
        unit = json['unit'],
        condition = json['condition'],
        super(key: key);
}
