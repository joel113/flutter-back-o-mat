import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_repository.dart';
import 'package:flutter_back_o_mat/baking/baking_composer.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:flutter_back_o_mat/baking/baking_repository.dart';
import 'package:flutter_back_o_mat/baking/baking_timeline.dart';

import 'recipe_test_database.dart';
import 'baking_session_test.dart' show bakingRecipe;

RecipeData starterRecipe() => RecipeData(
  name: 'Refresh starter',
  ingredients: [
    RecipeIngredient(id: 1, name: 'Starter', amount: 10, unit: 'g'),
  ],
  stages: [
    RecipeStage(
      id: 2,
      name: 'Mix refresh',
      durationMin: 5,
      durationMax: 5,
      ingredients: [IngredientReference(id: 1)],
    ),
    RecipeStage(
      id: 3,
      name: 'Ripen refresh',
      durationMin: 60,
      durationMax: 120,
      ingredients: [IngredientReference(id: 2)],
    ),
  ],
  notes: [RecipeNote(title: 'Warm', body: 'Keep warm')],
);

void main() {
  test(
    'links survive copies and revisions; imported local IDs never bind',
    () async {
      final db = await recipeTestDatabase();
      addTearDown(db.close);
      final repo = RecipeRepository(database: () async => db);
      final preparation = await repo.save(starterRecipe());
      final root = bakingRecipe()
        ..preparations.add(
          RecipePreparation(recipeId: preparation, stageId: 4),
        );
      final id = await repo.save(root);
      final original = (await repo.revisions(id)).single;
      final copy = root.copy();
      copy.preparations.single.stageId = 2;
      expect(root.preparations.single.stageId, 4);
      await repo.save(copy, id: id);
      await repo.restore(id, original.id);
      expect((await repo.load(id)).preparations.single.stageId, 4);
      final variant = await repo.createVariant(id, 'Alternative');
      expect(
        (await repo.load(variant)).preparations.single.recipeId,
        preparation,
      );
      final imported = RecipeImport.parse(jsonEncode(root.toJson())).single;
      expect(imported.preparations, isEmpty);
      expect(imported.importedPreparationsRemoved, isTrue);
      expect(
        RecipeData.fromExternalJson({
          'name': 'Unsafe',
          'preparations': 'invalid',
        }).preparations,
        isEmpty,
      );
      expect(RecipeData.fromJson({'name': 'Old'}).preparations, isEmpty);
    },
  );

  test('self, cycles, duplicates, missing recipes and removed consuming steps are rejected atomically', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final a = await repo.save(bakingRecipe());
    final b = await repo.save(starterRecipe());
    for (final target in [a, 999]) {
      final invalid = bakingRecipe()
        ..preparations.add(RecipePreparation(recipeId: target, stageId: 4));
      await expectLater(repo.save(invalid, id: a), throwsFormatException);
    }
    final valid = bakingRecipe()
      ..preparations.add(RecipePreparation(recipeId: b, stageId: 4));
    await repo.save(valid, id: a);
    final cycle = starterRecipe()
      ..preparations.add(RecipePreparation(recipeId: a, stageId: 2));
    await expectLater(repo.save(cycle, id: b), throwsFormatException);
    final invalid = valid.copy()
      ..preparations.add(RecipePreparation(recipeId: b, stageId: 2));
    await expectLater(repo.save(invalid, id: a), throwsFormatException);
    valid.stages.removeWhere((s) => s.id == 4);
    await expectLater(repo.save(valid, id: a), throwsFormatException);
    expect((await repo.load(a)).preparations.single.stageId, 4);
    expect((await repo.load(b)).preparations, isEmpty);
  });

  test('composition remaps colliding IDs, gates only consumers, and freezes source notes', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final source = await repo.save(starterRecipe());
    final sourceFamily = (await repo.loadRecord(source)).family!;
    await repo.saveSharedNotes(sourceFamily.id, [
      RecipeNote(title: 'Jar', body: 'Clean jar'),
    ]);
    final id = await repo.save(
      bakingRecipe()
        ..preparations.add(RecipePreparation(recipeId: source, stageId: 4)),
    );
    final root = await repo.loadRecord(id);
    final composition = await BakingComposer(repo).resolve(root, {source});
    final prep = composition.components.first,
        main = composition.components.last;
    final now = DateTime(2026, 11, 13, 8);
    final bake = BakingSession(
      recipeId: id,
      recipe: composition.recipe,
      plannedStart: now,
      components: composition.components,
      extraDependencies: composition.dependencies,
    );
    final consumer = main.ids[4]!,
        prepMix = prep.ids[2]!,
        prepRipen = prep.ids[3]!;
    expect(bake.recipe.validate(), isEmpty);
    expect(
      bake.recipe.ingredients.map((i) => i.id).toSet().length,
      bake.recipe.ingredients.length,
    );
    expect(
      bake.recipe.stages.map((s) => s.id).toSet().length,
      bake.recipe.stages.length,
    );
    expect(bake.dependencies(consumer), contains(prepRipen));
    expect(
      bake.recipe.stages
          .firstWhere((s) => s.id == consumer)
          .ingredients
          .map((r) => r.id),
      isNot(contains(prepRipen)),
    );
    expect(bake.canStart(main.ids[2]!), isTrue);
    expect(bake.canStart(prepMix), isTrue);
    expect(bake.schedule(now)[main.ids[2]!]!.start, now);
    expect(
      bake.schedule(now)[consumer]!.start,
      now.add(const Duration(minutes: 65)),
    );
    bake.start(main.ids[2]!, now);
    bake.complete(main.ids[2]!, now);
    bake.start(main.ids[3]!, now);
    bake.complete(main.ids[3]!, now);
    expect(bake.canStart(consumer), isFalse);
    bake.start(prepMix, now);
    bake.complete(prepMix, now.add(const Duration(minutes: 5)));
    bake.start(prepRipen, now.add(const Duration(minutes: 5)));
    bake.pause(prepRipen, now.add(const Duration(minutes: 10)));
    final roundTrip = BakingSession.fromJson(
      jsonDecode(jsonEncode(bake.toJson())) as Map<String, dynamic>,
    );
    expect(roundTrip.progress[prepRipen]!.status, BakeStepStatus.paused);
    roundTrip.resume(prepRipen, now.add(const Duration(minutes: 20)));
    roundTrip.complete(prepRipen, now.add(const Duration(minutes: 90)));
    expect(roundTrip.canStart(consumer), isTrue);
    expect(
      roundTrip.schedule(now.add(const Duration(minutes: 90)))[consumer]!.start,
      now.add(const Duration(minutes: 90)),
    );
    final saved = await BakingRepository(database: () async => db)
        .save(roundTrip);
    await repo.save(RecipeData(name: 'Changed source'), id: source);
    await repo.saveSharedNotes(sourceFamily.id, []);
    final reopened = await BakingRepository(database: () async => db)
        .load(saved.id!);
    expect(reopened.components.first.recipe.notes.single.body, 'Keep warm');
    expect(reopened.components.first.sharedNotes.single.body, 'Clean jar');
    expect(reopened.dependencies(consumer), contains(prepRipen));
  });

  test('several selected preparations feed one step; direct-only composition omits nested recipes', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final nested = await repo.save(starterRecipe());
    final source = await repo.save(
      starterRecipe()
        ..preparations.add(RecipePreparation(recipeId: nested, stageId: 2)),
    );
    final second = await repo.save(starterRecipe());
    final id = await repo.save(
      bakingRecipe()
        ..preparations.addAll([
          RecipePreparation(recipeId: source, stageId: 4),
          RecipePreparation(recipeId: second, stageId: 4),
        ]),
    );
    final record = await repo.loadRecord(id);
    final composer = BakingComposer(repo);
    final none = await composer.resolve(record, {});
    expect(
      none.recipe.stages.map((s) => s.id),
      record.recipe.stages.map((s) => s.id),
    );
    expect(none.recipe.preparations, isEmpty);
    expect(none.components, isEmpty);
    final all = await composer.resolve(record, {source, second});
    expect(all.components.map((c) => c.recipeId), [source, second, id]);
    expect(all.dependencies[all.components.last.ids[4]]!.length, 2);
    final only = await composer.resolve(record, {second});
    expect(only.components.length, 2);
    await expectLater(
      composer.resolve(record, {nested}),
      throwsFormatException,
    );
    final options = await composer.options(record.recipe);
    expect(options.first.record!.recipe.preparations, isNotEmpty);
  });

  test('draft and missing preparation choices remain unavailable without blocking a skipped preparation', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final draft = await repo.save(RecipeData(name: 'Draft starter'));
    final id = await repo.save(
      bakingRecipe()
        ..preparations.add(RecipePreparation(recipeId: draft, stageId: 4)),
    );
    final root = await repo.loadRecord(id);
    expect(
      (await BakingComposer(repo).options(root.recipe)).single.available,
      isFalse,
    );
    expect(
      (await BakingComposer(repo).resolve(root, {})).recipe.bakingReady,
      isTrue,
    );
    await expectLater(
      BakingComposer(repo).resolve(root, {draft}),
      throwsFormatException,
    );
    final missing = root.recipe.copy()..preparations.single.stageId = 2;
    missing.preparations
      ..clear()
      ..add(RecipePreparation(recipeId: 999, stageId: 2));
    expect(
      (await BakingComposer(repo).options(missing)).single.available,
      isFalse,
    );
  });

  test('independent preparation progress is not reused and resuming preserves composition', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final bakes = BakingRepository(database: () async => db);
    final source = await repo.save(starterRecipe());
    final now = DateTime(2026);
    final independent = await bakes.openForRecipe(source, starterRecipe(), now);
    independent.start(2, now);
    independent.complete(2, now);
    independent.start(3, now);
    independent.complete(3, now);
    await bakes.save(independent);
    final id = await repo.save(
      bakingRecipe()
        ..preparations.add(RecipePreparation(recipeId: source, stageId: 4)),
    );
    final composition = await BakingComposer(repo)
        .resolve(await repo.loadRecord(id), {source});
    final created = await bakes.openForRecipe(
      id,
      composition.recipe,
      now,
      components: composition.components,
      extraDependencies: composition.dependencies,
    );
    final prepMix = created.components.first.ids[2]!;
    expect(created.progress[prepMix]!.status, BakeStepStatus.pending);
    final resumed = await bakes.openForRecipe(
      id,
      bakingRecipe(),
      now.add(const Duration(days: 1)),
    );
    expect(resumed.id, created.id);
    expect(resumed.components.length, 2);
    expect(resumed.extraDependencies, created.extraDependencies);
  });

  test('dependency diagnostics and drag previews include cross-recipe edges, legacy sessions remain readable', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final source = await repo.save(starterRecipe());
    final root = await repo.save(
      bakingRecipe()
        ..preparations.add(RecipePreparation(recipeId: source, stageId: 4)),
    );
    final compiled = await BakingComposer(repo)
        .resolve(await repo.loadRecord(root), {source});
    final now = DateTime(2026);
    final bake = BakingSession(
      recipeId: root,
      recipe: compiled.recipe,
      plannedStart: now,
      components: compiled.components,
      extraDependencies: compiled.dependencies,
    );
    final prep = compiled.components.first, main = compiled.components.last;
    final scale = BakingTimelineScale(
      start: now,
      end: now.add(const Duration(hours: 4)),
      width: 516,
    );
    final changed = BakingTimelineDrag(
      session: bake,
      stageId: prep.ids[2]!,
      resize: false,
      now: now,
      scale: scale,
    ).preview(120);
    expect(changed.changedStagesFrom(bake, now), contains(main.ids[4]));
    expect(changed.changedStagesFrom(bake, now), isNot(contains(main.ids[2])));
    bake.setStepStart(main.ids[4]!, now.add(const Duration(hours: 4)));
    expect(
      bake
          .dependencyTimings(now)
          .any((t) => t.predecessorId == prep.ids[3] && t.needsReview),
      isTrue,
    );
    final legacy = BakingSession(
      recipeId: 1,
      recipe: bakingRecipe(),
      plannedStart: now,
    ).toJson();
    expect(BakingSession.fromJson(legacy).extraDependencies, isEmpty);
    final invalid = Map<String, dynamic>.of(bake.toJson())
      ..['extraDependencies'] = {
        '${prep.ids[2]}': [main.ids[4]],
      };
    expect(() => BakingSession.fromJson(invalid), throwsFormatException);
  });
}
