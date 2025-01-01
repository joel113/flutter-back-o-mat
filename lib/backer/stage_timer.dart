import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/backer/durationpicker/duration_picker_dialog.dart';
import 'package:flutter_back_o_mat/recipe/item_duration.dart';
import 'package:flutter_back_o_mat/util/restorable_duration.dart';

class StageTimer extends StatefulWidget {
  const StageTimer(this.itemDuration, {super.key});

  final ItemDuration itemDuration;

  @override
  State<StageTimer> createState() => _StageTimer();
}

class _StageTimer extends State<StageTimer> with RestorationMixin {
  Timer? timer;

  @override
  String get restorationId => 'home';

  late final RestorableDuration _selectedDuration =
      RestorableDuration(widget.itemDuration.lowerValue);

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDuration, 'selected_duration');
    registerForRestoration(
        _restorableRouteFutureDuration, 'restorable_route_future');
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_selectedDuration.value.inHours);
    final minutes = twoDigits(_selectedDuration.value.inMinutes.remainder(60));
    final seconds = twoDigits(_selectedDuration.value.inSeconds.remainder(60));
    return buildTimeCard(time: "$hours:$minutes:$seconds", header: 'Duration');
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) => addTime());
  }

  void addTime() {
    const addSeconds = 1;
    setState(() {
      final seconds = _selectedDuration.value.inSeconds + addSeconds;
      if (seconds < 0) {
        timer?.cancel();
      } else {
        _selectedDuration.value = Duration(seconds: seconds);
      }
    });
  }

  void _updateDuration(int? newDuration) {
    if (newDuration != null) {
      setState(() {
        _selectedDuration.value = Duration(seconds: newDuration);
      });
    }
  }

  late final RestorableRouteFuture<int?> _restorableRouteFutureDuration =
      RestorableRouteFuture<int?>(
          onPresent: (NavigatorState navigator, Object? arguments) {
            return navigator.restorablePush(
              _durationPickerRoute,
              arguments: arguments, // _newDuration.value,
            );
          },
          onComplete: _updateDuration);

  static Route<int> _durationPickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<int>(
        context: context,
        builder: (BuildContext context) {
          return DurationPickerDialog(
              initialDuration: Duration(seconds: arguments as int),
              title: "Change duration",
              confirmButtonText: "Ok",
              cancelButtonText: "Cancel");
        });
  }

  Widget buildTimeCard({required String time, required String header}) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              _restorableRouteFutureDuration.present(_selectedDuration.value.inSeconds);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.lightBlue[100],
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                time,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18),
              ),
            ),
          )
        ],
      );
}
