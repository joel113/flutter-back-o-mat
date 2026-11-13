import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'baking_session.dart';
import '../theme/app_components.dart';
import '../theme/app_theme.dart';

String sessionStatusText(AppLocalizations s, BakeSessionStatus status) =>
    switch (status) {
      BakeSessionStatus.planned => s.bakePlanned,
      BakeSessionStatus.active => s.bakeActive,
      BakeSessionStatus.completed => s.bakeCompleted,
    };
String stepStatusText(AppLocalizations s, BakeStepStatus status) =>
    switch (status) {
      BakeStepStatus.pending => s.stepPending,
      BakeStepStatus.running => s.stepRunning,
      BakeStepStatus.paused => s.stepPaused,
      BakeStepStatus.completed => s.stepCompleted,
    };
String bakeTime(BuildContext context, DateTime value) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .add_Hm()
        .format(value);
String bakeMinutes(int minutes) => [
  if (minutes >= 60) '${minutes ~/ 60} h',
  if (minutes % 60 != 0 || minutes == 0) '${minutes % 60} min',
].join(' ');

String bakeDurationRange(int minimum, int maximum) {
  if (minimum == maximum) return bakeMinutes(minimum);
  if (minimum % 60 == 0 && maximum % 60 == 0) {
    return '${minimum ~/ 60}–${maximum ~/ 60} h';
  }
  return '${bakeMinutes(minimum)} – ${bakeMinutes(maximum)}';
}

String countdown(Duration value) {
  final seconds = (value.inMilliseconds / 1000).ceil();
  final absolute = seconds.abs();
  String two(int v) => '$v'.padLeft(2, '0');
  return '${seconds < 0 ? '−' : ''}${two(absolute ~/ 3600)}:${two(absolute ~/ 60 % 60)}:${two(absolute % 60)}';
}

Future<DateTime?> pickBakeTime(BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(initial.year - 10),
    lastDate: DateTime(initial.year + 10),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String dependencyTimingText(
  AppLocalizations s,
  BakingSession session,
  BakeDependencyTiming timing,
) {
  final names = {
    for (final stage in session.recipe.stages) stage.id: stage.name,
  };
  final parent = names[timing.predecessorId]!;
  final child = names[timing.successorId]!;
  String length(Duration duration) => bakeMinutes(
    (duration.inMilliseconds.abs() / Duration.millisecondsPerMinute).ceil(),
  );
  return switch (timing.condition) {
    BakeDependencyCondition.synchronized => '',
    BakeDependencyCondition.waiting => s.dependencyWaiting(
      parent,
      child,
      length(timing.gap),
    ),
    BakeDependencyCondition.tooEarly => s.dependencyTooEarly(
      parent,
      child,
      length(timing.gap),
      length(timing.excess),
    ),
    BakeDependencyCondition.conflict => s.dependencyConflict(
      parent,
      child,
      length(timing.gap),
    ),
  };
}

Color bakeWarningColor(BuildContext context) =>
    AppSemanticColors.of(context).warning;

AppStatusTone sessionStatusTone(BakeSessionStatus status) => switch (status) {
  BakeSessionStatus.planned => AppStatusTone.neutral,
  BakeSessionStatus.active => AppStatusTone.active,
  BakeSessionStatus.completed => AppStatusTone.completed,
};
