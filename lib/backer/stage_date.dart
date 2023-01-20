import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StageDate extends StatefulWidget {
  const StageDate(this.dateTime, {super.key, this.restorationId});

  final DateTime dateTime;
  final String? restorationId;

  @override
  State<StageDate> createState() => _StageDate();
}

class _StageDate extends State<StageDate> with RestorationMixin {
  @override
  String? get restorationId => widget.restorationId;

  late final RestorableDateTime _selectedDate = RestorableDateTime(widget.dateTime);

  late final RestorableRouteFuture<DateTime?> _restorableRouteFutureDate =
      RestorableRouteFuture<DateTime?>(
          onComplete: _selectDate,
          onPresent: (NavigatorState navigator, Object? arguments) {
            return navigator.restorablePush(
              _datePickerRoute,
              arguments: _selectedDate.value.millisecondsSinceEpoch,
            );
          });

  late final RestorableRouteFuture<DateTime?> _restorableRouteFutureTime =
      RestorableRouteFuture<DateTime?>(
          onComplete: _selectTime,
          onPresent: (NavigatorState navigator, Object? arguments) {
            return navigator.restorablePush(
              _timePickerRoute,
              arguments: _selectedDate.value.millisecondsSinceEpoch,
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

  static Route<DateTime> _timePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
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
              "${DateFormat("EE").format(_selectedDate.value)}. ${_selectedDate.value.day}. ${DateFormat("MMM").format(_selectedDate.value)}. ${_selectedDate.value.year}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 24),
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
              "${_selectedDate.value.hour}:${_selectedDate.value.minute}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 24),
            ),
          ),
          onPressed: () {
            _restorableRouteFutureTime.present();
          },
        )
      ],
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDate, 'selected_date');
    registerForRestoration(
        _restorableRouteFutureDate, 'date_picker_route_future');
    registerForRestoration(
        _restorableRouteFutureTime, 'time_picker_route_future');
  }

  void _selectDate(DateTime? newSelectedDate) {
    if (newSelectedDate != null) {
      setState(() {
        _selectedDate.value = newSelectedDate;
      });
    }
  }

  void _selectTime(DateTime? newSelectedTime) {
    if (newSelectedTime != null) {
      setState(() {
        _selectedDate.value = newSelectedTime;
      });
    }
  }
}
