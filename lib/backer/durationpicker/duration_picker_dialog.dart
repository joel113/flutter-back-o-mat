import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class DurationPickerDialog extends StatefulWidget {
  final Duration initialDuration;
  final String? title;
  final String? confirmButtonText;
  final String? cancelButtonText;

  const DurationPickerDialog({
    super.key,
    this.initialDuration = Duration.zero,
    this.title,
    this.confirmButtonText,
    this.cancelButtonText,
  });

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late TextEditingController _hoursController;
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;

  late int _currentHours;
  late int _currentMinutes;
  late int _currentSeconds;

  @override
  void initState() {
    super.initState();
    _currentHours = widget.initialDuration.inHours;
    _currentMinutes = widget.initialDuration.inMinutes % 60;
    _currentSeconds = widget.initialDuration.inSeconds % 60;

    _hoursController = TextEditingController(text: _currentHours.toString());
    _minutesController = TextEditingController(text: _currentMinutes.toString());
    _secondsController = TextEditingController(text: _currentSeconds.toString());
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _updateDuration() {
    setState(() {
      _currentHours = int.tryParse(_hoursController.text) ?? 0;
      _currentMinutes = int.tryParse(_minutesController.text) ?? 0;
      _currentSeconds = int.tryParse(_secondsController.text) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title != null ? Text(widget.title!) : Text(AppLocalizations.of(context)!.durationPickerTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnitSelector(
                  label: 'Hours',
                  controller: _hoursController,
                  onChanged: _updateDuration,
                  min: 0,
                  max: 99
              ),
              const Text(":", style: TextStyle(fontSize: 24)),
              _buildTimeUnitSelector(
                label: 'Minutes',
                controller: _minutesController,
                onChanged: _updateDuration,
                min: 0,
                max: 59,
              ),
              const Text(":", style: TextStyle(fontSize: 24)),
              _buildTimeUnitSelector(
                label: 'Seconds',
                controller: _secondsController,
                onChanged: _updateDuration,
                min: 0,
                max: 59,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: Text(widget.cancelButtonText != null ? widget.cancelButtonText! : "Cancel"),
        ),
        TextButton(
          onPressed: () {
            final duration = Duration(
              hours: _currentHours,
              minutes: _currentMinutes,
              seconds: _currentSeconds,
            );
            Navigator.of(context).pop(duration.inSeconds);
          },
          child: Text(widget.confirmButtonText != null ? widget.confirmButtonText! : "Confirm"),
        ),
      ],
    );
  }


  Widget _buildTimeUnitSelector({
    required String label,
    required TextEditingController controller,
    required VoidCallback onChanged,
    required int min,
    required int max
  }) {
    return Row(
      children: [
        IconButton(
            onPressed: () {
              var currentValue = int.tryParse(controller.text) ?? 0;
              currentValue = currentValue -1;
              if(currentValue < min) {
                currentValue = min;
              }
              controller.text = currentValue.toString();
              onChanged();
            },
            icon: const Icon(Icons.remove)
        ),
        SizedBox(
          width: 50,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              final parsedValue = int.tryParse(value);
              if (parsedValue != null && parsedValue >= min && parsedValue <= max) {
                onChanged();
              } else {
                controller.text = min.toString();
                onChanged();
              }
            },
            decoration: InputDecoration(
              hintText: label.substring(0,1),
            ),
          ),
        ),
        IconButton(
            onPressed: (){
              var currentValue = int.tryParse(controller.text) ?? 0;
              currentValue = currentValue +1;
              if(currentValue > max) {
                currentValue = max;
              }
              controller.text = currentValue.toString();
              onChanged();
            },
            icon: const Icon(Icons.add)
        )
      ],
    );
  }
}