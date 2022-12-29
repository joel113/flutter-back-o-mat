import 'package:flutter/material.dart';

import '../util/dura.dart';

class ItemDuration extends StatelessWidget {
  const ItemDuration(
      {Key? key, required this.lowerValue, required this.upperValue})
      : super(key: key);

  final Duration lowerValue;
  final Duration upperValue;

  @override
  Widget build(BuildContext context) {
    if (lowerValue == upperValue) {
      return Text(Dura.stringify(lowerValue));
    } else {
      return Text(
          "${Dura.stringifyNoUnit(lowerValue)} bis ${Dura.stringify(upperValue)}");
    }
  }

  ItemDuration.fromJson(Map<String, dynamic> json, {Key? key})
      : lowerValue = deserializeDuration(json['unit'], json['lower value']),
        upperValue = deserializeDuration(json['unit'], json['upper value']),
        super(key: key);

  static Duration deserializeDuration(String unit, int value) {
    if (unit == "hours") {
      return Duration(hours: value);
    } else {
      return Duration(minutes: value);
    }
  }
}
