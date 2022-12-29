import 'package:flutter/material.dart';

class ItemTemperature extends StatelessWidget {
  const ItemTemperature({Key? key, required this.lowerValue, required this.upperValue}) : super(key: key);

  final int lowerValue;
  final int upperValue;

  @override
  Widget build(BuildContext context) {
    if (lowerValue == upperValue) {
      return Text("$lowerValue C°");
    } else {
      return Text(
          "$upperValue bis $lowerValue °C}");
    }
  }

  ItemTemperature.fromJson(Map<String, dynamic> json, {Key? key})
      : lowerValue = json['lower value'],
        upperValue = json['upper value'], super(key: key);
}