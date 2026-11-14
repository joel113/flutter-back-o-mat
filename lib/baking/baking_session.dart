import '../recipe/data/recipe_data.dart';
import 'baking_component.dart';

enum BakeStepStatus { pending, running, paused, completed }

enum BakeSessionStatus { planned, active, completed }

class BakeStepProgress {
  BakeStepProgress({
    required this.stageId,
    required this.durationMinutes,
    this.notBefore,
    this.startedAt,
    this.completedAt,
    this.deadline,
    this.pausedRemainingMs,
    this.completedReadyUntil,
  });
  final int stageId;
  int durationMinutes;
  DateTime? notBefore;
  DateTime? startedAt;
  DateTime? completedAt;
  DateTime? deadline;
  int? pausedRemainingMs;
  DateTime? completedReadyUntil;

  BakeStepStatus get status => completedAt != null
      ? BakeStepStatus.completed
      : pausedRemainingMs != null
      ? BakeStepStatus.paused
      : startedAt != null
      ? BakeStepStatus.running
      : BakeStepStatus.pending;
  Duration remaining(DateTime now) => completedAt != null
      ? Duration.zero
      : pausedRemainingMs != null
      ? Duration(milliseconds: pausedRemainingMs!)
      : deadline != null
      ? deadline!.difference(now)
      : Duration(minutes: durationMinutes);
  Map<String, dynamic> toJson() => {
    'stageId': stageId,
    'durationMinutes': durationMinutes,
    'notBefore': notBefore?.millisecondsSinceEpoch,
    'startedAt': startedAt?.millisecondsSinceEpoch,
    'completedAt': completedAt?.millisecondsSinceEpoch,
    'deadline': deadline?.millisecondsSinceEpoch,
    'pausedRemainingMs': pausedRemainingMs,
    'completedReadyUntil': completedReadyUntil?.millisecondsSinceEpoch,
  };
  factory BakeStepProgress.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) => json[key] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json[key] as int);
    return BakeStepProgress(
      stageId: json['stageId'] as int,
      durationMinutes: json['durationMinutes'] as int,
      notBefore: date('notBefore'),
      startedAt: date('startedAt'),
      completedAt: date('completedAt'),
      deadline: date('deadline'),
      pausedRemainingMs: json['pausedRemainingMs'] as int?,
      completedReadyUntil: date('completedReadyUntil'),
    );
  }
}

class BakeWindow {
  const BakeWindow({
    required this.start,
    required this.end,
    required this.earliestStart,
    required this.latestStart,
    required this.earliestEnd,
    required this.latestEnd,
  });
  final DateTime start;
  final DateTime end;
  final DateTime earliestStart;
  final DateTime latestStart;
  final DateTime earliestEnd;
  final DateTime latestEnd;
}

enum BakeDependencyCondition { synchronized, waiting, tooEarly, conflict }

/// Derived schedule diagnostics; these never rewrite actual progress or recipes.
class BakeDependencyTiming {
  const BakeDependencyTiming({
    required this.predecessorId,
    required this.successorId,
    required this.readyAt,
    required this.usedAt,
    required this.readyUntil,
  });
  final int predecessorId;
  final int successorId;
  final DateTime readyAt;
  final DateTime usedAt;
  final DateTime readyUntil;
  Duration get gap => usedAt.difference(readyAt);
  Duration get excess => usedAt.isAfter(readyUntil)
      ? usedAt.difference(readyUntil)
      : Duration.zero;
  BakeDependencyCondition get condition => usedAt.isBefore(readyAt)
      ? BakeDependencyCondition.conflict
      : usedAt.isAfter(readyUntil)
      ? BakeDependencyCondition.tooEarly
      : usedAt.isAfter(readyAt)
      ? BakeDependencyCondition.waiting
      : BakeDependencyCondition.synchronized;
  bool get needsReview =>
      condition == BakeDependencyCondition.tooEarly ||
      condition == BakeDependencyCondition.conflict;
  bool touches(int id) => predecessorId == id || successorId == id;
}

class BakingSession {
  BakingSession({
    this.id,
    required this.recipeId,
    required RecipeData recipe,
    required this.plannedStart,
    Map<int, BakeStepProgress>? progress,
    this.familyName,
    this.variantName,
    List<RecipeNote> sharedNotes = const [],
    Map<int, Set<int>> extraDependencies = const {},
    List<BakingComponent> components = const [],
  }) : recipe = recipe.copy(),
       extraDependencies = {
         for (final e in extraDependencies.entries) e.key: Set.of(e.value),
       },
       components = components
           .map((c) => BakingComponent.fromJson(c.toJson()))
           .toList(),
       sharedNotes = sharedNotes.map((n) => n.copy()).toList(),
       progress =
           progress ??
           {
             for (final stage in recipe.stages)
               stage.id: BakeStepProgress(
                 stageId: stage.id,
                 durationMinutes: stage.durationMin ?? 0,
               ),
           } {
    if (!this.recipe.bakingReady ||
        this.progress.length != this.recipe.stages.length ||
        this.recipe.stages.any(
          (stage) => !this.progress.containsKey(stage.id),
        )) {
      throw const FormatException('invalidSession');
    }
    final positions = {
      for (var i = 0; i < this.recipe.stages.length; i++)
        this.recipe.stages[i].id: i,
    };
    for (final edge in this.extraDependencies.entries) {
      if (!positions.containsKey(edge.key) ||
          edge.value.any(
            (id) =>
                !positions.containsKey(id) ||
                positions[id]! >= positions[edge.key]!,
          )) {
        throw const FormatException('invalidDependencies');
      }
    }
    for (final stage in this.recipe.stages) {
      final step = this.progress[stage.id]!;
      if (step.stageId != stage.id ||
          step.durationMinutes < stage.durationMin! ||
          step.durationMinutes > stage.durationMax! ||
          step.startedAt == null &&
              (step.deadline != null ||
                  step.pausedRemainingMs != null ||
                  step.completedAt != null) ||
          step.startedAt != null &&
              step.completedAt == null &&
              step.pausedRemainingMs == null &&
              step.deadline == null ||
          step.pausedRemainingMs != null && step.deadline != null ||
          step.completedAt != null &&
              (step.deadline != null || step.pausedRemainingMs != null)) {
        throw const FormatException('invalidProgress');
      }
    }
  }
  int? id;
  final int recipeId;
  final RecipeData recipe;
  final Map<int, Set<int>> extraDependencies;
  final List<BakingComponent> components;
  BakingComponent? componentFor(int stageId) => components
      .where((c) => c.recipe.stages.any((s) => c.ids[s.id] == stageId))
      .firstOrNull;
  final String? familyName;
  final String? variantName;
  final List<RecipeNote> sharedNotes;
  DateTime plannedStart;
  final Map<int, BakeStepProgress> progress;
  BakeSessionStatus get status =>
      progress.values.every((p) => p.status == BakeStepStatus.completed)
      ? BakeSessionStatus.completed
      : progress.values.any((p) => p.startedAt != null)
      ? BakeSessionStatus.active
      : BakeSessionStatus.planned;

  Set<int> dependencies(int stageId) => {
    ...recipe.stages
        .firstWhere((s) => s.id == stageId)
        .ingredients
        .map((r) => r.id)
        .where(progress.containsKey),
    ...?extraDependencies[stageId],
  };
  bool canStart(int stageId) =>
      progress[stageId]!.status == BakeStepStatus.pending &&
      dependencies(stageId)
          .every((id) => progress[id]!.status == BakeStepStatus.completed);

  void start(int stageId, DateTime now) {
    if (!canStart(stageId)) throw StateError('blockedStep');
    final step = progress[stageId]!;
    step.startedAt = now;
    step.deadline = now.add(Duration(minutes: step.durationMinutes));
  }

  /// Adopt the scheduled start for retrospective entry. Future plans still start
  /// at the actual current time when the user starts a step early.
  void startPlanned(int stageId, DateTime now) {
    if (!canStart(stageId)) throw StateError('blockedStep');
    final planned = schedule(now)[stageId]!.start;
    start(stageId, planned.isBefore(now) ? planned : now);
  }

  void pause(int stageId, DateTime now) {
    final step = progress[stageId]!;
    if (step.status != BakeStepStatus.running) throw StateError('notRunning');
    step.pausedRemainingMs = step.remaining(now).inMilliseconds;
    step.deadline = null;
  }

  void resume(int stageId, DateTime now) {
    final step = progress[stageId]!;
    if (step.status != BakeStepStatus.paused) throw StateError('notPaused');
    step.deadline = now.add(Duration(milliseconds: step.pausedRemainingMs!));
    step.pausedRemainingMs = null;
  }

  void complete(int stageId, DateTime now) {
    final step = progress[stageId]!;
    if (step.status != BakeStepStatus.running &&
        step.status != BakeStepStatus.paused) {
      throw StateError('notStarted');
    }
    final effectiveStart =
        (step.deadline ??
                now.add(Duration(milliseconds: step.pausedRemainingMs!)))
            .subtract(Duration(minutes: step.durationMinutes));
    final stage = recipe.stages.firstWhere((stage) => stage.id == stageId);
    final maximumEnd = effectiveStart.add(
      Duration(minutes: stage.durationMax!),
    );
    step.completedReadyUntil = maximumEnd.isAfter(now) ? maximumEnd : now;
    step.completedAt = now;
    step.pausedRemainingMs = null;
    step.deadline = null;
  }

  void setDuration(int stageId, int minutes) {
    final step = progress[stageId]!;
    final stage = recipe.stages.firstWhere((s) => s.id == stageId);
    if (step.status != BakeStepStatus.pending ||
        minutes < stage.durationMin! ||
        minutes > stage.durationMax!) {
      throw ArgumentError('durationRange');
    }
    step.durationMinutes = minutes;
  }

  void setStepStart(int stageId, DateTime start) {
    if (progress[stageId]!.status != BakeStepStatus.pending) {
      throw StateError('alreadyStarted');
    }
    progress[stageId]!.notBefore = start;
  }

  /// Recipe validation guarantees topological stage order. Roots run in parallel.
  /// Manual start choices are lower bounds; dependencies may move them later.
  Map<int, BakeWindow> schedule(DateTime now) {
    DateTime later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
    final result = <int, BakeWindow>{};
    for (final stage in recipe.stages) {
      final step = progress[stage.id]!;
      var start = later(plannedStart, step.notBefore ?? plannedStart);
      var earliest = start;
      var latest = start;
      for (final id in dependencies(stage.id)) {
        final parent = result[id]!;
        start = later(start, parent.end);
        earliest = later(earliest, parent.earliestEnd);
        latest = later(latest, parent.latestEnd);
      }
      var end = start.add(Duration(minutes: step.durationMinutes));
      var minEnd = earliest.add(Duration(minutes: stage.durationMin!));
      var maxEnd = latest.add(Duration(minutes: stage.durationMax!));
      if (step.startedAt != null) {
        start = step.startedAt!;
        earliest = start;
        latest = start;
        if (step.completedAt != null) {
          end = step.completedAt!;
          minEnd = end;
          maxEnd = end;
        } else {
          final projectedEnd = step.status == BakeStepStatus.paused
              ? now.add(Duration(milliseconds: step.pausedRemainingMs!))
              : step.deadline!;
          end = later(projectedEnd, now);
          final effectiveStart = projectedEnd.subtract(
            Duration(minutes: step.durationMinutes),
          );
          minEnd = later(
            effectiveStart.add(Duration(minutes: stage.durationMin!)),
            now,
          );
          maxEnd = later(
            effectiveStart.add(Duration(minutes: stage.durationMax!)),
            end,
          );
        }
      }
      result[stage.id] = BakeWindow(
        start: start,
        end: end,
        earliestStart: earliest,
        latestStart: latest,
        earliestEnd: minEnd,
        latestEnd: maxEnd,
      );
    }
    return result;
  }

  Set<int> changedStagesFrom(BakingSession original, DateTime now) {
    final before = original.schedule(now);
    final after = schedule(now);
    return {
      for (final id in progress.keys)
        if (before[id]?.start != after[id]!.start ||
            before[id]?.end != after[id]!.end)
          id,
    };
  }

  List<BakeDependencyTiming> dependencyTimings(DateTime now) {
    final windows = schedule(now);
    final stages = {for (final stage in recipe.stages) stage.id: stage};
    final result = <BakeDependencyTiming>[];
    for (final successor in recipe.stages) {
      for (final id in dependencies(successor.id)) {
        final parent = progress[id]!;
        final window = windows[id]!;
        // Running/paused deadlines include pauses, so their flexibility window
        // moves with the effective start. Completed stages retain actual times.
        final effectiveStart = switch (parent.status) {
          BakeStepStatus.running => parent.deadline!.subtract(
            Duration(minutes: parent.durationMinutes),
          ),
          BakeStepStatus.paused =>
            now
                .add(Duration(milliseconds: parent.pausedRemainingMs!))
                .subtract(Duration(minutes: parent.durationMinutes)),
          _ => window.start,
        };
        final maximumEnd =
            parent.completedReadyUntil ??
            effectiveStart.add(Duration(minutes: stages[id]!.durationMax!));
        final readyUntil = maximumEnd.isBefore(window.end)
            ? window.end
            : maximumEnd;
        result.add(
          BakeDependencyTiming(
            predecessorId: id,
            successorId: successor.id,
            readyAt: window.end,
            usedAt: windows[successor.id]!.start,
            readyUntil: readyUntil,
          ),
        );
      }
    }
    return result;
  }

  BakeWindow completionWindow(DateTime now) {
    final values = schedule(now).values;
    DateTime latest(Iterable<DateTime> dates) =>
        dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return BakeWindow(
      start: plannedStart,
      end: latest(values.map((w) => w.end)),
      earliestStart: plannedStart,
      latestStart: plannedStart,
      earliestEnd: latest(values.map((w) => w.earliestEnd)),
      latestEnd: latest(values.map((w) => w.latestEnd)),
    );
  }

  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    if (components.isNotEmpty)
      'components': components.map((c) => c.toJson()).toList(),
    if (extraDependencies.isNotEmpty)
      'extraDependencies': {
        for (final e in extraDependencies.entries) '${e.key}': e.value.toList(),
      },
    'familyName': familyName,
    'variantName': variantName,
    'sharedNotes': sharedNotes.map((n) => n.toJson()).toList(),
    'recipe': recipe.toJson(),
    'plannedStart': plannedStart.millisecondsSinceEpoch,
    'progress': progress.values.map((p) => p.toJson()).toList(),
  };
  factory BakingSession.fromJson(Map<String, dynamic> json, {int? id}) =>
      BakingSession(
        id: id,
        recipeId: json['recipeId'] as int,
        components: (json['components'] as List? ?? [])
            .map(
              (e) =>
                  BakingComponent.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
        extraDependencies: {
          for (final e in (json['extraDependencies'] as Map? ?? {}).entries)
            int.parse(e.key as String): (e.value as List).cast<int>().toSet(),
        },
        familyName: json['familyName'] as String?,
        variantName: json['variantName'] as String?,
        sharedNotes: (json['sharedNotes'] as List? ?? [])
            .map(
              (e) => RecipeNote.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
        recipe: RecipeData.fromJson(json['recipe'] as Map<String, dynamic>),
        plannedStart: DateTime.fromMillisecondsSinceEpoch(
          json['plannedStart'] as int,
        ),
        progress: {
          for (final raw in json['progress'] as List)
            (raw['stageId'] as int): BakeStepProgress.fromJson(
              raw as Map<String, dynamic>,
            ),
        },
      );
  BakingSession copy() => BakingSession.fromJson(toJson(), id: id);
}
