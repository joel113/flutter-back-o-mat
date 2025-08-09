import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/recipe/item_duration.dart';
import 'package:flutter_back_o_mat/recipe/item_ingredients.dart';
import 'package:flutter_back_o_mat/recipe/item_temperature.dart';
import 'package:flutter_back_o_mat/util/json.dart';
import '../backer/stage_date.dart';
import '../backer/stage_timer.dart';

class ItemStage {
  const ItemStage({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.description,
    required this.initialItemDuration,
    this.temperature,
    this.initialStartTime,
    this.stages, // This might need to be re-evaluated based on its usage
    this.showTimer = false,
  });

  final int id;
  final String name;
  final ItemIngredients ingredients;
  final String description;
  final ItemDuration initialItemDuration;
  final ItemTemperature? temperature;
  final DateTime? initialStartTime;
  final List<ItemStage>? stages;
  final bool showTimer;

  static ItemStage fromJson(
      Map<dynamic, dynamic> ingredients, Map<String, dynamic> json,
      {bool showTimer = false}) {
    return ItemStage(
        id: json['id'],
        name: json['name'],
        ingredients: ItemIngredients.fromJson(
            Json.merge(ingredients, json['ingredients'])),
        description: json['description'],
        initialItemDuration: ItemDuration(
            initialLowerValue: deserializeDuration(
                json['duration']['unit'], json['duration']['lower value']),
            initialUpperValue: deserializeDuration(
                json['duration']['unit'], json['duration']['upper value'])),
        temperature: (json['temperature'] != null)
            ? ItemTemperature.fromJson(json['temperature'])
            : null,
        showTimer: showTimer);
  }

  static Duration deserializeDuration(String unit, int value) {
    if (unit == "hours") {
      return Duration(hours: value);
    } else {
      return Duration(minutes: value);
    }
  }
}

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

  DateTime _calculateStartTime(
      ItemStage currentStage, List<ItemStage> allStages) {
    DateTime startTime = DateTime.now();
    // This logic might need adjustment depending on how `currentStage.ingredients`
    // and `allStages` are structured and used.
    // The original calculateStartTime had a potential O(n^2) complexity.
    // Consider if this logic can be optimized or is still appropriate.
    for (ItemStage stage in allStages) {
      if (currentStage.ingredients.ingredients.containsKey(stage.id)) {
        DateTime stageStartTime = _calculateStartTime(stage, allStages);
        int newStartTime = stageStartTime.millisecondsSinceEpoch +
            stage.initialItemDuration.initialLowerValue.inMilliseconds;
        if (newStartTime > startTime.millisecondsSinceEpoch) {
          startTime = DateTime.fromMillisecondsSinceEpoch(newStartTime);
        }
      }
    }
    return startTime;
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
      children: stages.map((stage) {
        return TableRow(children: [
          TableCell(
              child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(stage.name))),
          TableCell(
              child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      stage.temperature != null
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: stage.temperature!)
                          : Container(),
                      stage.initialItemDuration
                    ],
                  ))),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: StageDate(
                initialDateTime: _calculateStartTime(stage, stages)),
          )),
          TableCell(
              child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Container(
                      alignment: Alignment.centerRight,
                      child: StageTimer(
                          initialItemDuration: stage.initialItemDuration))))
        ]);
      }).toList(),
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
        0: FixedColumnWidth(156),
        1: FlexColumnWidth(1),
        2: FixedColumnWidth(156), // Corrected from FlexColumnWidth(1) to FlexColumnWidth(156) based on previous context
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: stages.map((stage) {
        return TableRow(children: [
          Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(stage.name)),
          Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  stage.ingredients,
                  Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(stage.description))
                ],
              )),
          Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Column(
                children: [
                  stage.temperature != null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: stage.temperature!)
                      : Container(),
                  stage.initialItemDuration
                ],
              )),
        ]);
      }).toList(),
    );
  }

  static ItemStages fromJson(
      Map<dynamic, dynamic> baseIngredients, List<dynamic> json,
      {bool showTimer = false}) {
    // The 'stages' field within an ItemStage instance needs careful handling.
    // If it's meant to refer to the global list of stages, it can be passed directly.
    // If it's meant for something else, this logic might need to be different.
    List<ItemStage> parsedStages = [];
    parsedStages = json
        .map((e) =>
            ItemStage.fromJson(baseIngredients, e, showTimer: showTimer))
        .toList();

    // If ItemStage.stages was intended to be a circular reference to the main list,
    // we might need to update them after all are parsed, or adjust the ItemStage constructor.
    // For now, I'll assume ItemStage.stages can be the main list.
    List<ItemStage> finalStages = parsedStages.map((stage) => ItemStage(
        id: stage.id,
        name: stage.name,
        ingredients: stage.ingredients,
        description: stage.description,
        initialItemDuration: stage.initialItemDuration,
        temperature: stage.temperature,
        initialStartTime: stage.initialStartTime,
        stages: parsedStages, // Passing the full list of stages here
        showTimer: stage.showTimer
    )).toList(growable: false);


    return ItemStages(stages: finalStages, showTimer: showTimer);
  }
}