import 'package:flutter/material.dart';

import 'item_stage.dart';

class ItemStages extends StatelessWidget {
  const ItemStages({super.key, required this.stages, this.showTimer = false});

  final List<ItemStage> stages;
  final bool showTimer;

  @override
  Widget build(BuildContext context) {
    if (showTimer) {
      return buildWithTimer(context);
    } else {
      return buildWithoutTimer(context);
    }
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
        2: FixedColumnWidth(330),
        3: FixedColumnWidth(150)
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (var value in stages) TableRow(children: [value])
      ],
    );
  }

  Widget buildWithoutTimer(BuildContext context) {
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
      children: [
        for (var value in stages) TableRow(children: [value])
      ],
    );
  }

  static ItemStages fromJson(
      Map<dynamic, dynamic> ingredients, List<dynamic> json,
      {bool showTimer = false}) {
    final stages = json.map((e) => ItemStage.fromJson(ingredients, e)).toList();
    return ItemStages(
        stages: stages
            .map((stage) => ItemStage(
                id: stage.id,
                name: stage.name,
                ingredients: stage.ingredients,
                description: stage.description,
                initialItemDuration: stage.initialItemDuration,
                temperature: stage.temperature,
                initialStartTime: stage.initialStartTime,
                stages: stages,
                showTimer: stage.showTimer))
            .toList(growable: false),
        showTimer: showTimer);
  }
}
