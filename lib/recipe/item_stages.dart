import 'package:flutter/material.dart';

import 'item_stage.dart';

class ItemStages extends StatelessWidget {
  const ItemStages({Key? key, required this.stages}) : super(key: key);

  final List<ItemStage> stages;

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
        2: FixedColumnWidth(156),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [for (var value in stages) value.buildRow(context)],
    );
  }

  Widget buildWithTimer(BuildContext context) {
    return Table(
      border: const TableBorder(
          horizontalInside: BorderSide(
            width: 1,
            color: Colors.lightBlue,
            style: BorderStyle.solid,
          )),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(156),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: FixedColumnWidth(192)
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [for (var value in stages) value.buildRowWithTimer(context, stages)],
    );
  }

  ItemStages.fromJson(
      Map<dynamic, dynamic> ingredients, List<dynamic> stages,
      {Key? key})
      : stages = stages.map((e) => ItemStage.fromJson(ingredients, e)).toList(),
        super(key: key);
}
