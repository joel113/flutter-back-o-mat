import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Common units remain suggestions: imported and custom units stay editable.
class RecipeUnitInput extends StatefulWidget {
  const RecipeUnitInput({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<RecipeUnitInput> createState() => _RecipeUnitInputState();
}

class _RecipeUnitInputState extends State<RecipeUnitInput> {
  late final controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final units = [
      'g',
      'kg',
      'mg',
      'ml',
      'l',
      s.unitTeaspoon,
      s.unitTablespoon,
      s.unitPiece,
      s.unitPinch,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: s.unitLabel,
          suffixIcon: PopupMenuButton<String>(
            tooltip: s.chooseUnit,
            icon: const Icon(Icons.arrow_drop_down),
            itemBuilder: (_) => [
              for (final unit in units)
                PopupMenuItem(value: unit, child: Text(unit)),
            ],
            onSelected: (unit) {
              controller.text = unit;
              widget.onChanged(unit);
            },
          ),
        ),
      ),
    );
  }
}

/// Storage and scheduling use whole minutes regardless of the display unit.
class RecipeDurationInput extends StatefulWidget {
  const RecipeDurationInput({
    super.key,
    required this.label,
    required this.minutes,
    required this.onChanged,
  });
  final String label;
  final int? minutes;
  final ValueChanged<int?> onChanged;

  @override
  State<RecipeDurationInput> createState() => _RecipeDurationInputState();
}

class _RecipeDurationInputState extends State<RecipeDurationInput> {
  late int factor =
      widget.minutes != null && widget.minutes! > 0 && widget.minutes! % 60 == 0
      ? 60
      : 1;
  late final controller = TextEditingController(text: display(widget.minutes));
  final field = GlobalKey<FormFieldState<String>>();

  String display(int? minutes) => minutes == null
      ? ''
      : factor == 1
      ? '$minutes'
      : minutes % 60 == 0
      ? '${minutes ~/ 60}'
      : '${minutes / 60}';

  int? parse(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite || value < 0) return null;
    final minutes = value * factor;
    if (!minutes.isFinite || (minutes - minutes.round()).abs() > .0000001) {
      return null;
    }
    return minutes.round();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              key: field,
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: widget.label),
              validator: (value) =>
                  value == null || value.trim().isEmpty || parse(value) != null
                  ? null
                  : s.invalidDurationInput,
              onChanged: (value) => widget.onChanged(parse(value)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            child: InputDecorator(
              decoration: InputDecoration(labelText: s.timeUnit),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: factor,
                  isDense: true,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 1, child: Text(s.minutesUnit)),
                    DropdownMenuItem(value: 60, child: Text(s.hoursUnit)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    final minutes = parse(controller.text);
                    if (controller.text.trim().isNotEmpty && minutes == null) {
                      field.currentState!.validate();
                      return;
                    }
                    setState(() {
                      factor = value;
                      controller.text = display(minutes);
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
