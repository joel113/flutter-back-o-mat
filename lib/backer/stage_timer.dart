import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/backer/durationpicker/duration_picker_dialog.dart';
import 'package:flutter_back_o_mat/recipe/item_duration.dart';

class StageTimer extends StatefulWidget {
  const StageTimer(this.itemDuration, {Key? key}) : super(key: key);

  final ItemDuration itemDuration;

  @override
  State<StageTimer> createState() => _StageTimer();
}

class _StageTimer extends State<StageTimer> with RestorationMixin {
  Timer? timer;
  Duration duration = const Duration();

  @override
  String get restorationId => 'home';

  late final RestorableInt _newDuration = RestorableInt(0);

  late final RestorableRouteFuture<int?> _restorableRouteFutureDuration =
      RestorableRouteFuture<int?>(
          onPresent: (NavigatorState navigator, Object? arguments) {
            return navigator.restorablePush(
              _durationPickerRoute,
              arguments: _newDuration.value,
            );
          },
          onComplete: _selectDuration);

  static Route<int> _durationPickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<int>(
        context: context,
        builder: (BuildContext context) {
          return const DurationPickerDialog(
              initialDuration: Duration.zero,
              title: "Change duration",
              confirmButtonText: "Ok",
              cancelButtonText: "Cancel");
        });
  }

  @override
  Widget build(BuildContext context) {
    duration = widget.itemDuration.lowerValue;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return buildTimeCard(time: "$hours:$minutes:$seconds", header: 'Duration');
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) => addTime());
  }

  void addTime() {
    const addSeconds = 1;
    setState(() {
      final seconds = duration.inSeconds + addSeconds;
      if (seconds < 0) {
        timer?.cancel();
      } else {
        duration = Duration(seconds: seconds);
      }
    });
  }

  Widget buildTimeCard({required String time, required String header}) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              _restorableRouteFutureDuration.present();
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
                    fontSize: 24),
              ),
            ),
          )
        ],
      );

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_newDuration, 'new_duration');
    registerForRestoration(
        _restorableRouteFutureDuration, 'restorable_route_future');
  }

  void _selectDuration(int? newDuration) {
    if (newDuration != null) {
      setState(() {
        _newDuration.value = newDuration;
      });
    }
  }
}
