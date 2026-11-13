import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations_en.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:flutter_back_o_mat/baking/baking_labels.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';

RecipeData bakingRecipe() => RecipeData(
  name: 'Bread',
  ingredients: [RecipeIngredient(id: 1, name: 'Flour')],
  stages: [
    RecipeStage(id: 2, name: 'Sourdough', durationMin: 60, durationMax: 120),
    RecipeStage(id: 3, name: 'Soaker', durationMin: 30, durationMax: 45),
    RecipeStage(
      id: 4,
      name: 'Dough',
      durationMin: 15,
      durationMax: 30,
      ingredients: [IngredientReference(id: 2), IngredientReference(id: 3)],
    ),
  ],
);
void main() {
  final start = DateTime(2026, 11, 7, 8);
  BakingSession bake() =>
      BakingSession(recipeId: 7, recipe: bakingRecipe(), plannedStart: start);
  test(
    'parallel roots and dependency windows are anchored to the saved start',
    () {
      final session = bake();
      final schedule = session.schedule(start);
      expect(schedule[2]!.start, start);
      expect(schedule[3]!.start, start);
      expect(schedule[4]!.start, start.add(const Duration(hours: 1)));
      expect(schedule[4]!.earliestEnd, start.add(const Duration(minutes: 75)));
      expect(schedule[4]!.latestEnd, start.add(const Duration(minutes: 150)));
      expect(
        session.schedule(start.add(const Duration(days: 1)))[4]!.start,
        schedule[4]!.start,
      );
    },
  );
  test(
    'chosen durations and start overrides propagate to dependent stages',
    () {
      final session = bake();
      session.setDuration(2, 90);
      expect(
        session.schedule(start)[4]!.start,
        start.add(const Duration(minutes: 90)),
      );
      session.setStepStart(3, start.add(const Duration(hours: 2)));
      expect(
        session.schedule(start)[4]!.start,
        start.add(const Duration(minutes: 150)),
      );
      session.setStepStart(
        4,
        start,
      ); // dependency wins over an earlier manual choice
      expect(
        session.schedule(start)[4]!.start,
        start.add(const Duration(minutes: 150)),
      );
      expect(() => session.setDuration(2, 1), throwsArgumentError);
      expect(() => session.start(4, start), throwsStateError);
    },
  );
  test('running countdown survives serialization and clock jumps', () {
    final session = bake()..start(2, start);
    final reopened = BakingSession.fromJson(
      jsonDecode(jsonEncode(session.toJson())) as Map<String, dynamic>,
      id: 4,
    );
    expect(
      reopened.progress[2]!.remaining(start.add(const Duration(minutes: 20))),
      const Duration(minutes: 40),
    );
    expect(
      reopened.progress[2]!.remaining(start.add(const Duration(minutes: 65))),
      const Duration(minutes: -5),
    );
    expect(countdown(const Duration(minutes: -5)), '−00:05:00');
    expect(
      reopened.progress[2]!.status,
      BakeStepStatus.running,
    ); // expiration requires explicit completion
  });
  test('pause and resume persist without counting paused time', () {
    final session = bake()..start(2, start);
    session.pause(2, start.add(const Duration(minutes: 10)));
    final reopened = session.copy();
    final later = start.add(const Duration(hours: 3));
    expect(reopened.progress[2]!.remaining(later), const Duration(minutes: 50));
    reopened.resume(2, later);
    expect(
      reopened.progress[2]!.deadline,
      later.add(const Duration(minutes: 50)),
    );
    expect(
      reopened.progress[2]!.remaining(later.add(const Duration(minutes: 5))),
      const Duration(minutes: 45),
    );
    expect(() => reopened.setDuration(2, 100), throwsArgumentError);
  });
  test(
    'actual completion unlocks dependencies and updates finish estimates',
    () {
      final session = bake()
        ..start(2, start)
        ..start(3, start);
      session.complete(2, start.add(const Duration(minutes: 70)));
      expect(session.canStart(4), isFalse);
      session.complete(3, start.add(const Duration(minutes: 80)));
      expect(session.canStart(4), isTrue);
      expect(
        session.schedule(start)[4]!.start,
        start.add(const Duration(minutes: 80)),
      );
      session.start(4, start.add(const Duration(minutes: 85)));
      session.complete(4, start.add(const Duration(minutes: 105)));
      expect(session.status, BakeSessionStatus.completed);
      expect(
        session.completionWindow(start).earliestEnd,
        start.add(const Duration(minutes: 105)),
      );
      expect(
        session.completionWindow(start).latestEnd,
        start.add(const Duration(minutes: 105)),
      );
    },
  );
  test('recipe snapshot remains unchanged when the recipe is edited', () {
    final source = bakingRecipe();
    final session = BakingSession(
      recipeId: 7,
      recipe: source,
      plannedStart: start,
    );
    source.name = 'Edited';
    source.stages.first.durationMin = 999;
    expect(session.recipe.name, 'Bread');
    expect(session.recipe.stages.first.durationMin, 60);
    expect(
      () => BakingSession(
        recipeId: 8,
        recipe: RecipeData(name: 'Draft'),
        plannedStart: start,
      ),
      throwsFormatException,
    );
  });
  test(
    'moving a predecessor moves pending descendants but keeps parallel roots',
    () {
      final session = bake();
      final original = session.copy();
      session.setStepStart(2, start.add(const Duration(minutes: 90)));
      expect(
        session.schedule(start)[4]!.start,
        start.add(const Duration(minutes: 150)),
      );
      expect(session.schedule(start)[3]!.start, start);
      expect(session.changedStagesFrom(original, start), {2, 4});
    },
  );
  test('delaying a consumer keeps predecessors fixed and reports waiting past their maximum', () {
    final session = bake();
    session.setStepStart(4, start.add(const Duration(hours: 3)));
    final parentWindow = session.schedule(start)[2]!;
    expect(parentWindow.start, start);
    expect(parentWindow.end, start.add(const Duration(hours: 1)));
    final timing = session
        .dependencyTimings(start)
        .firstWhere((timing) => timing.predecessorId == 2);
    expect(timing.condition, BakeDependencyCondition.tooEarly);
    expect(timing.gap, const Duration(hours: 2));
    expect(timing.excess, const Duration(hours: 1));
  });
  test('waiting within flexibility and at its upper boundary does not raise a warning', () {
    final session = bake();
    session.setStepStart(4, start.add(const Duration(minutes: 100)));
    BakeDependencyTiming timing() => session
        .dependencyTimings(start)
        .firstWhere((timing) => timing.predecessorId == 2);
    expect(timing().condition, BakeDependencyCondition.waiting);
    expect(timing().needsReview, isFalse);
    session.setStepStart(4, start.add(const Duration(minutes: 120)));
    expect(timing().needsReview, isFalse);
    session.setStepStart(4, start.add(const Duration(minutes: 121)));
    expect(timing().condition, BakeDependencyCondition.tooEarly);
    expect(timing().excess, const Duration(minutes: 1));
  });
  test('an already running successor retains actual timestamps and gets a conflict', () {
    final session = bake();
    // Historical progress may predate a corrected plan. Never rewrite its facts.
    session.progress[4]!
      ..startedAt = start.add(const Duration(minutes: 60))
      ..deadline = start.add(const Duration(minutes: 75));
    final actualStart = session.progress[4]!.startedAt;
    final deadline = session.progress[4]!.deadline;
    session.setStepStart(2, start.add(const Duration(minutes: 90)));
    final timing = session
        .dependencyTimings(start)
        .firstWhere((timing) => timing.predecessorId == 2);
    expect(timing.condition, BakeDependencyCondition.conflict);
    expect(timing.gap, const Duration(minutes: -90));
    expect(session.schedule(start)[4]!.start, actualStart);
    expect(session.progress[4]!.deadline, deadline);
  });
  test('readiness diagnostics preserve paused time through completion and reopening', () {
    final session = bake()..start(2, start);
    session.pause(2, start.add(const Duration(minutes: 30)));
    session.resume(2, start.add(const Duration(minutes: 90)));
    session.complete(2, start.add(const Duration(minutes: 120)));
    session.setStepStart(4, start.add(const Duration(minutes: 150)));
    final reopened = session.copy();
    final timing = reopened
        .dependencyTimings(start)
        .firstWhere((timing) => timing.predecessorId == 2);
    expect(timing.readyUntil, start.add(const Duration(minutes: 180)));
    expect(timing.condition, BakeDependencyCondition.waiting);
    final oldJson = reopened.toJson();
    for (final step in oldJson['progress'] as List) {
      step.remove('completedReadyUntil');
    }
    expect(() => BakingSession.fromJson(oldJson), returnsNormally);
  });
  test(
    'dependency messages identify the right predecessor, consumer, and delay',
    () {
      final session = bake()
        ..setStepStart(4, start.add(const Duration(hours: 3)));
      final timing = session
          .dependencyTimings(start)
          .firstWhere((timing) => timing.predecessorId == 2);
      final text = dependencyTimingText(AppLocalizationsEn(), session, timing);
      expect(text, contains('Sourdough is ready 2 h before use in Dough'));
      expect(text, contains('exceeded by 1 h'));
    },
  );
}
