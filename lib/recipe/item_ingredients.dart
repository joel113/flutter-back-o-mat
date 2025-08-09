import 'package:flutter/material.dart';

import 'item_ingredient.dart';

class ItemIngredients extends StatelessWidget {
  const ItemIngredients({super.key, required this.ingredients});

  final Map<int, ItemIngredient> ingredients;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: const TableBorder(
          horizontalInside: BorderSide(
        width: 1,
        color: Colors.lightBlue,
        style: BorderStyle.solid,
      )),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(128),
        1: FlexColumnWidth(),
        2: FlexColumnWidth()
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (var value in ingredients.entries) value.value.buildRow(context)
      ],
    );
  }

  ItemIngredients.fromJson(List<dynamic> json, {super.key})
      : ingredients = json
            .map((e) => ItemIngredient.fromJson(e))
            .map((e) => {e.id: e})
            .fold(<int, ItemIngredient>{},
                (previousValue, element) => {...previousValue, ...element});
}
