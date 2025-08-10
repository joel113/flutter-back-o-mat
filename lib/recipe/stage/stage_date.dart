import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StageDate extends StatefulWidget {
  const StageDate({super.key, required this.initialDateTime});

  final DateTime initialDateTime;

  @override
  State<StageDate> createState() => _StageDate();
}

class _StageDate extends State<StageDate> with RestorationMixin {

  @override
  String get restorationId => 'stage_date';

  late final RestorableDateTime dateTime = RestorableDateTime(widget.initialDateTime);

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(dateTime, 'dateTime');
    registerForRestoration(
        _restorableRouteFutureDate, 'date_picker_route_future');
    registerForRestoration(
        _restorableRouteFutureTime, 'time_picker_route_future');
  }

  void _selectDate(DateTime? newDate) {
    if (newDate != null) {
      setState(() {
        dateTime.value = DateTime(
            newDate.year,
            newDate.month,
            newDate.day,
            dateTime.value.hour,
            dateTime.value.minute);
      });
    }
  }

  void _selectTime(TimeOfDay? newTime) {
    if (newTime != null) {
      setState(() {
        dateTime.value = DateTime(
            dateTime.value.year,
            dateTime.value.month,
            dateTime.value.day,
            newTime.hour,
            newTime.minute);
      });
    }
  }

  late final RestorableRouteFuture<DateTime?> _restorableRouteFutureDate =
      RestorableRouteFuture<DateTime?>(
          onComplete: _selectDate,
          onPresent: (NavigatorState navigator, Object? arguments) {
            return navigator.restorablePush(
              _datePickerRoute,
              arguments: dateTime.value.millisecondsSinceEpoch,
            );
          });

  late final RestorableRouteFuture<TimeOfDay?> _restorableRouteFutureTime =
      RestorableRouteFuture<TimeOfDay?>(
          onComplete: _selectTime,
          onPresent: (NavigatorState navigator, Object? arguments) {
            return navigator.restorablePush(
              _timePickerRoute,
              arguments: dateTime.value.millisecondsSinceEpoch,
            );
          });

  static Route<DateTime> _datePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return DatePickerDialog(
          restorationId: 'date_picker_dialog',
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          initialDate: DateTime.fromMillisecondsSinceEpoch(arguments! as int),
          firstDate: DateTime(DateTime.now().year - 1),
          lastDate: DateTime(DateTime.now().year + 1),
        );
      },
    );
  }

  static Route<TimeOfDay> _timePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return TimePickerDialog(
          restorationId: 'time_picker_dialog',
          initialTime: TimeOfDay.now(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.lightBlue[100],
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              "${DateFormat("EE").format(dateTime.value)}. ${dateTime.value.day}. ${DateFormat("MMM").format(dateTime.value)}. ${dateTime.value.year}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18),
            ),
          ),
          onPressed: () {
            _restorableRouteFutureDate.present();
          },
        ),
        TextButton(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.lightBlue[100],
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              "${DateFormat("HH").format(dateTime.value)}:${DateFormat("mm").format(dateTime.value)}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18),
            ),
          ),
          onPressed: () {
            _restorableRouteFutureTime.present();
          },
        )
      ],
    );
  }
}
