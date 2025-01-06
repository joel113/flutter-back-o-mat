import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/recipe/item_duration.dart';
import 'package:flutter_back_o_mat/recipe/item_ingredients.dart';
import 'package:flutter_back_o_mat/util/restorable_duration.dart';

import '../backer/stage_date.dart';
import '../backer/stage_timer.dart';
import '../util/json.dart';
import '../util/restorable_nullable_datetime.dart';
import 'item_temperature.dart';

class ItemStage extends StatefulWidget {
  const ItemStage(
      {super.key,
      required this.id,
      required this.name,
      required this.ingredients,
      required this.description,
      required this.initialItemDuration,
      this.temperature,
      this.initialStartTime,
      this.stages,
      this.showTimer = false});

  final int id;
  final String name;
  final ItemIngredients ingredients;
  final String description;
  final ItemDuration initialItemDuration;
  final ItemTemperature? temperature;
  final DateTime? initialStartTime;
  final List<ItemStage>? stages;
  final bool showTimer;

  @override
  State<ItemStage> createState() => _ItemStage();

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

class _ItemStage extends State<ItemStage> with RestorationMixin {
  @override
  String get restorationId => 'home';

  late final RestorableDuration _selectedDuration =
      RestorableDuration(widget.initialItemDuration.initialLowerValue);
  late final RestorableNullableDateTime _selectedStartTime =
      RestorableNullableDateTime(widget.initialStartTime);

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDuration, 'selected_duration');
    registerForRestoration(_selectedStartTime, 'selected_start_time');
  }

  DateTime calculateStartTime(
      ItemIngredients ingredients, List<ItemStage> stages) {
    DateTime startTime = DateTime.now();
    for (ItemStage stage in stages) {
      if (ingredients.ingredients.containsKey(stage.id)) {
        // Recursive computation of the start time with complexity O(n^2)
        DateTime stageStartTime = calculateStartTime(stage.ingredients, stages);
        int newStartTime = stageStartTime.millisecondsSinceEpoch +
            stage.initialItemDuration.initialLowerValue.inMilliseconds;
        if (newStartTime > startTime.millisecondsSinceEpoch) {
          startTime = DateTime.fromMillisecondsSinceEpoch(newStartTime);
        }
      }
    }
    return startTime;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showTimer) {
      return buildWithTimer(context);
    } else {
      return buildWithoutTimer(context);
    }
  }

  Row buildWithTimer(BuildContext context) {
    var row = Row(
      children: [
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(widget.name))),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.temperature != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: widget.temperature!)
                        : Container(),
                    widget.initialItemDuration
                  ],
                ))),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: StageDate(
              initialDateTime:
                  calculateStartTime(widget.ingredients, widget.stages!)),
        )),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Container(
                    alignment: Alignment.centerRight,
                    child: StageTimer(
                        initialItemDuration: widget.initialItemDuration))))
      ],
    );
    return row;
  }

  Row buildWithoutTimer(BuildContext context) {
    var row = Row(
      children: [
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(widget.name))),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.ingredients,
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(widget.description))
                  ],
                ))),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Column(
                  children: [
                    widget.temperature != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: widget.temperature!)
                        : Container(),
                    widget.initialItemDuration
                  ],
                ))),
      ],
    );
    return row;
  }

  void _handleStartTimeChanged(DateTime newStartTime) {
    setState(() {
      //initialStartTime = newStartTime;
    });
  }

  void _handleDurationChanged(Duration newDuration) {
    setState(() {
      //initialItemDuration.initialLowerValue = newDuration;
    });
  }
}
