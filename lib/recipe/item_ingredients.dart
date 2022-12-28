import 'package:flutter/material.dart';

import 'item_ingredient.dart';

class ItemIngredients extends StatelessWidget {
  const ItemIngredients({Key? key, required this.ingredients})
      : super(key: key);

  final List<ItemIngredient> ingredients;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: const TableBorder(
        horizontalInside: BorderSide(
          width: 1,
          color: Colors.lightBlue,
          style: BorderStyle.solid,
        )
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(128),
        1: FlexColumnWidth(),
        2: FlexColumnWidth()
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [for (var value in ingredients) value.buildRow(context)],
    );
  }

  ItemIngredients.fromJson(List<dynamic> json, {Key? key})
      : ingredients = json.map((e) => ItemIngredient.fromJson(e)).toList(),
        super(key: key);
}
