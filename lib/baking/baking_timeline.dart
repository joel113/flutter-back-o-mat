import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../l10n/app_localizations.dart';
import '../recipe/data/recipe_data.dart';
import 'baking_labels.dart';
import 'baking_session.dart';
import '../theme/app_theme.dart';

/// A fixed scale during a gesture prevents the chart jumping under the pointer.
class BakingTimelineScale {
  const BakingTimelineScale({
    required this.start,
    required this.end,
    required this.width,
  });
  final DateTime start;
  final DateTime end;
  final double width;
  static const padding = 18.0;
  double get plotWidth => math.max(1, width - padding * 2);
  double x(DateTime date) =>
      padding +
      date.difference(start).inMilliseconds /
          end.difference(start).inMilliseconds *
          plotWidth;
  int minutesForPixels(double pixels) =>
      (pixels / plotWidth * end.difference(start).inMinutes).round();
  Rect bar(BakeWindow window, double height) => Rect.fromLTWH(
    x(window.start),
    height / 2 - 17,
    math.max(18, x(window.end) - x(window.start)),
    34,
  );

  factory BakingTimelineScale.fit(
    BakingSession session,
    DateTime now,
    double width, {
    double zoom = 1,
    double offset = 0,
  }) {
    final windows = session.schedule(now).values;
    var first = session.plannedStart;
    var last = first.add(const Duration(hours: 1));
    for (final window in windows) {
      if (window.start.isBefore(first)) first = window.start;
      if (window.end.isAfter(last)) last = window.end;
      if (window.latestEnd.isAfter(last)) last = window.latestEnd;
    }
    final span = math.max(60, last.difference(first).inMinutes);
    final paddedSpan = (span * 1.12).ceil();
    final visibleMinutes = math.max(15, (paddedSpan / zoom).round());
    final start = first.add(
      Duration(minutes: (offset * visibleMinutes).round()),
    );
    return BakingTimelineScale(
      start: start,
      end: start.add(Duration(minutes: visibleMinutes)),
      width: width,
    );
  }

  /// Keep time coordinates stable after edits; only explicit navigation changes them.
  BakingTimelineScale viewport({
    required double width,
    double zoom = 1,
    double offset = 0,
  }) {
    final minutes = math.max(
      15,
      (end.difference(start).inMinutes / zoom).round(),
    );
    final visibleStart = start.add(
      Duration(minutes: (offset * minutes).round()),
    );
    return BakingTimelineScale(
      start: visibleStart,
      end: visibleStart.add(Duration(minutes: minutes)),
      width: width,
    );
  }

  List<DateTime> get ticks {
    final minutes = end.difference(start).inMinutes;
    final desired = minutes / math.max(2, plotWidth / 105);
    const intervals = [
      1,
      5,
      15,
      30,
      60,
      120,
      240,
      360,
      720,
      1440,
      2880,
      10080,
      43200,
    ];
    final interval = intervals.firstWhere(
      (n) => n >= desired,
      orElse: () => (desired / 1440).ceil() * 1440,
    );
    final step = interval * Duration.millisecondsPerMinute;
    var epoch = (start.millisecondsSinceEpoch / step).ceil() * step;
    final result = <DateTime>[];
    while (epoch < end.millisecondsSinceEpoch) {
      result.add(DateTime.fromMillisecondsSinceEpoch(epoch));
      epoch += step;
    }
    return result;
  }
}

/// A drag is computed from the original snapshot, never accumulated rounding.
class BakingTimelineDrag {
  BakingTimelineDrag({
    required BakingSession session,
    required this.stageId,
    required this.resize,
    required this.now,
    required this.scale,
  }) : original = session.copy() {
    if (original.progress[stageId]!.status != BakeStepStatus.pending) {
      throw StateError('lockedStep');
    }
  }
  final BakingSession original;
  final int stageId;
  final bool resize;
  final DateTime now;
  final BakingTimelineScale scale;

  BakingSession preview(double pixels) {
    final result = original.copy();
    final delta = scale.minutesForPixels(pixels);
    if (resize) {
      final stage = result.recipe.stages.firstWhere((s) => s.id == stageId);
      result.setDuration(
        stageId,
        (original.progress[stageId]!.durationMinutes + delta).clamp(
          stage.durationMin!,
          stage.durationMax!,
        ),
      );
    } else {
      final oldStart = original.schedule(now)[stageId]!.start;
      result.setStepStart(stageId, oldStart.add(Duration(minutes: delta)));
      // Store the effective start, so a clamped gesture has no hidden offset.
      result.setStepStart(stageId, result.schedule(now)[stageId]!.start);
    }
    return result;
  }
}

class TimelineAxis extends StatelessWidget {
  const TimelineAxis({super.key, required this.scale});
  final BakingTimelineScale scale;
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return SizedBox(
      height: 64,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 6,
              child: Text(
                AppLocalizations.of(context)!.timelineTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final tick in scale.ticks)
              Positioned(
                left: scale.x(tick) - 42,
                top: 34,
                width: 84,
                child: Text(
                  DateFormat('EEE HH:mm', locale).format(tick),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TimelineStage extends StatelessWidget {
  const TimelineStage({
    super.key,
    required this.stage,
    required this.session,
    required this.window,
    required this.scale,
    required this.selected,
    this.affected = false,
    this.timingWarning = '',
    this.timingDescription = '',
    this.hasTimingConflict = false,
    required this.enabled,
    required this.onSelect,
    required this.onMoveStart,
    required this.onResizeStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
    required this.onEditStart,
    required this.onEditDuration,
  });
  final RecipeStage stage;
  final BakingSession session;
  final BakeWindow window;
  final BakingTimelineScale scale;
  final bool selected;
  final bool affected;
  final String timingWarning;
  final String timingDescription;
  final bool hasTimingConflict;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onMoveStart;
  final VoidCallback onResizeStart;
  final ValueChanged<double> onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;
  final VoidCallback onEditStart;
  final VoidCallback onEditDuration;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final status = session.progress[stage.id]!.status;
    final editable = enabled && status == BakeStepStatus.pending;
    final flexible = stage.durationMin != stage.durationMax;
    final colors = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final color = switch (status) {
      BakeStepStatus.completed => semantic.completed,
      BakeStepStatus.paused => semantic.paused,
      _ => semantic.running,
    };
    final minutes = session.progress[stage.id]!.durationMinutes;
    final tooltip =
        '${stage.name}\n${bakeTime(context, window.start)} → ${bakeTime(context, window.end)}\n$minutes min (${stage.durationMin}–${stage.durationMax} min)\n${editable ? s.timelineDragHint : s.timelineLocked}${affected ? '\n${s.timelineAffected}' : ''}${timingDescription.isEmpty ? '' : '\n$timingDescription'}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final rect = scale.bar(window, constraints.maxHeight);
        return ClipRect(
          child: CustomPaint(
            painter: _TimelineGrid(scale, colors.outlineVariant),
            child: Stack(
              children: [
                if (editable && flexible && selected)
                  Positioned(
                    key: ValueKey('timeline-range-${stage.id}'),
                    left: scale.x(
                      window.start.add(Duration(minutes: stage.durationMin!)),
                    ),
                    top: rect.bottom + 5,
                    width: math.max(
                      1,
                      scale.x(
                            window.start.add(
                              Duration(minutes: stage.durationMax!),
                            ),
                          ) -
                          scale.x(
                            window.start.add(
                              Duration(minutes: stage.durationMin!),
                            ),
                          ),
                    ),
                    height: 10,
                    child: CustomPaint(painter: _TimelineRangeGuide(color)),
                  ),
                Positioned.fromRect(
                  rect: rect,
                  child: Tooltip(
                    message: tooltip,
                    child: Semantics(
                      selected: selected,
                      label: tooltip,
                      child: MouseRegion(
                        cursor: editable
                            ? SystemMouseCursors.grab
                            : SystemMouseCursors.click,
                        child: GestureDetector(
                          key: ValueKey('timeline-bar-${stage.id}'),
                          behavior: HitTestBehavior.opaque,
                          onTap: onSelect,
                          onDoubleTap: editable ? onEditStart : null,
                          onHorizontalDragStart: editable
                              ? (_) => onMoveStart()
                              : null,
                          onHorizontalDragUpdate: editable
                              ? (details) => onUpdate(details.delta.dx)
                              : null,
                          onHorizontalDragEnd: editable ? (_) => onEnd() : null,
                          onHorizontalDragCancel: editable ? onCancel : null,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: timingWarning.isNotEmpty
                                    ? (hasTimingConflict
                                          ? colors.error
                                          : bakeWarningColor(context))
                                    : selected
                                    ? colors.onSurface
                                    : color,
                                width:
                                    selected ||
                                        affected ||
                                        timingWarning.isNotEmpty
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  stage.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (editable && flexible)
                  Positioned(
                    left: rect.right - 8,
                    top: rect.top - 5,
                    width: 28,
                    height: rect.height + 10,
                    child: Tooltip(
                      message: s.timelineResizeHint,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        child: GestureDetector(
                          key: ValueKey('timeline-resize-${stage.id}'),
                          behavior: HitTestBehavior.opaque,
                          onTap: onEditDuration,
                          onHorizontalDragStart: (_) => onResizeStart(),
                          onHorizontalDragUpdate: (details) =>
                              onUpdate(details.delta.dx),
                          onHorizontalDragEnd: (_) => onEnd(),
                          onHorizontalDragCancel: onCancel,
                          child: Center(
                            child: Container(
                              width: 12,
                              height: 26,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                border: Border.all(color: color, width: 1.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.drag_indicator,
                                size: 10,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimelineRangeGuide extends CustomPainter {
  const _TimelineRangeGuide(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .65)
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    canvas.drawLine(Offset(0, 1), Offset(0, size.height - 1), paint);
    canvas.drawLine(
      Offset(size.width, 1),
      Offset(size.width, size.height - 1),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TimelineRangeGuide oldDelegate) =>
      color != oldDelegate.color;
}

class _TimelineGrid extends CustomPainter {
  _TimelineGrid(this.scale, this.color);
  final BakingTimelineScale scale;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .25)
      ..strokeWidth = 1;
    for (final tick in scale.ticks) {
      final x = scale.x(tick);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_TimelineGrid oldDelegate) => true;
}

/// Painted after Table layout; shared cells determine row heights for both views.
class TimelineDependencies extends CustomPainter {
  TimelineDependencies({
    required this.session,
    required this.scale,
    required this.now,
    required this.rowKeys,
    required this.surfaceKey,
    required this.color,
    required this.selectedId,
    this.affectedStages = const {},
    required this.warningColor,
    required this.errorColor,
    required this.surfaceColor,
  });
  final BakingSession session;
  final BakingTimelineScale scale;
  final DateTime now;
  final Map<int, GlobalKey> rowKeys;
  final GlobalKey surfaceKey;
  final Color color;
  final int? selectedId;
  final Set<int> affectedStages;
  final Color warningColor;
  final Color errorColor;
  final Color surfaceColor;
  @override
  void paint(Canvas canvas, Size size) {
    final surface = surfaceKey.currentContext?.findRenderObject();
    if (surface is! RenderBox || !surface.hasSize) return;
    final windows = session.schedule(now);
    final timings = {
      for (final timing in session.dependencyTimings(now))
        (timing.predecessorId, timing.successorId): timing,
    };
    Rect? bar(int id) {
      final row = rowKeys[id]?.currentContext?.findRenderObject();
      if (row is! RenderBox || !row.hasSize) return null;
      final origin = surface.globalToLocal(row.localToGlobal(Offset.zero));
      return scale.bar(windows[id]!, row.size.height).shift(origin);
    }

    final first = rowKeys.values.firstOrNull?.currentContext
        ?.findRenderObject();
    if (first is! RenderBox || !first.hasSize) return;
    final origin = surface.globalToLocal(first.localToGlobal(Offset.zero));
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(origin.dx, origin.dy, scale.width, size.height - origin.dy),
    );
    for (final stage in session.recipe.stages) {
      for (final parent in session.dependencies(stage.id)) {
        final from = bar(parent);
        final to = bar(stage.id);
        if (from == null || to == null) continue;
        final timing = timings[(parent, stage.id)]!;
        final highlighted =
            selectedId == stage.id ||
            selectedId == parent ||
            affectedStages.contains(stage.id) ||
            affectedStages.contains(parent);
        final edgeColor = switch (timing.condition) {
          BakeDependencyCondition.conflict => errorColor,
          BakeDependencyCondition.tooEarly => warningColor,
          _ => color.withValues(alpha: highlighted ? .9 : .35),
        };
        final paint = Paint()
          ..color = edgeColor
          ..strokeWidth = highlighted || timing.needsReview ? 2 : 1.2
          ..style = PaintingStyle.stroke;
        final start = from.centerRight;
        final end = to.centerLeft;
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(start.dx + 9, start.dy)
          ..lineTo(start.dx + 9, end.dy - 26)
          ..lineTo(end.dx - 9, end.dy - 26)
          ..lineTo(end.dx - 9, end.dy)
          ..lineTo(end.dx - 2, end.dy);
        if (timing.condition == BakeDependencyCondition.synchronized) {
          canvas.drawPath(path, paint);
        } else {
          for (final metric in path.computeMetrics()) {
            for (double distance = 0; distance < metric.length; distance += 9) {
              canvas.drawPath(
                metric.extractPath(
                  distance,
                  math.min(distance + 5, metric.length),
                ),
                paint,
              );
            }
          }
        }
        if (timing.needsReview) {
          final marker = Offset(end.dx - 9, end.dy - 26);
          canvas.drawCircle(marker, 7, Paint()..color = edgeColor);
          final label = TextPainter(
            text: TextSpan(
              text: '!',
              style: TextStyle(
                color: surfaceColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(
            canvas,
            marker - Offset(label.width / 2, label.height / 2),
          );
        }
        canvas.drawPath(
          Path()
            ..moveTo(end.dx - 7, end.dy - 4)
            ..lineTo(end.dx - 2, end.dy)
            ..lineTo(end.dx - 7, end.dy + 4),
          paint,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TimelineDependencies oldDelegate) => true;
}
