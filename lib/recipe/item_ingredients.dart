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
  final double amount;
  final String unit;
  final String condition;

  @override
  Widget build(BuildContext context) {
    // TODO: implement
  }
}
