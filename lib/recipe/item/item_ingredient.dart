import 'package:flutter/material.dart';

class ItemIngredient extends StatelessWidget {
  ItemIngredient({
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
    throw UnimplementedError();
  }

  TableRow buildRow(BuildContext context) {
    var row = TableRow(
      children: [
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text("${(amount != null) ? amount : "gesamt"} ${(unit != null) ? unit : ""} ${(condition != null) ? "zu $condition" : ""}"))),
        TableCell(child: Text("$name")),
      ],
    );
    return row;
  }

  ItemIngredient.fromJson(Map<String, dynamic> json, {super.key})
      : id = json['id'],
        name = json['name'],
        amount = json['amount'],
        unit = json['unit'],
        condition = json['condition'];
}
