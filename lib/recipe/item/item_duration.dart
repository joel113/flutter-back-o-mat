import 'package:flutter/material.dart';

import '../../util/dura.dart';
import '../../util/restorable_duration.dart';

class ItemDuration extends StatefulWidget {
  const ItemDuration(
      {super.key,
      required this.initialLowerValue,
      required this.initialUpperValue});

  final Duration initialLowerValue;
  final Duration initialUpperValue;

  @override
  State<ItemDuration> createState() => _ItemDuration();
}

class _ItemDuration extends State<ItemDuration> with RestorationMixin {
  @override
  String get restorationId => 'home';

  late final RestorableDuration lowerValue =
      RestorableDuration(widget.initialLowerValue);
  late final RestorableDuration upperValue =
      RestorableDuration(widget.initialUpperValue);

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(lowerValue, 'lower_value');
    registerForRestoration(upperValue, "upper_value");
  }

  @override
  Widget build(BuildContext context) {
    if (lowerValue == upperValue) {
      return Text(Dura.stringify(lowerValue.value));
    } else {
      return Text(
          "${Dura.stringifyNoUnit(lowerValue.value)} bis ${Dura.stringify(upperValue.value)}");
    }
  }
}
