import 'dart:convert';

class RecipeNote {
  RecipeNote({this.title = '', this.body = ''});
  String title;
  String body;
  factory RecipeNote.fromJson(Map<String, dynamic> json) => RecipeNote(
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {'title': title, 'body': body};
  RecipeNote copy() => RecipeNote(title: title, body: body);
}

class RecipePreparation {
  RecipePreparation({required this.recipeId, required this.stageId});
  final int recipeId;
  int stageId;
  factory RecipePreparation.fromJson(Map<String, dynamic> json) =>
      RecipePreparation(
        recipeId: json['recipeId'] as int,
        stageId: json['stageId'] as int,
      );
  Map<String, dynamic> toJson() => {'recipeId': recipeId, 'stageId': stageId};
}

class RecipeData {
  RecipeData({
    this.name = '',
    this.description = '',
    this.image,
    List<RecipeIngredient>? ingredients,
    List<RecipeStage>? stages,
    List<RecipeNote>? notes,
    List<RecipePreparation>? preparations,
  }) : ingredients = ingredients ?? [],
       stages = stages ?? [],
       notes = notes ?? [],
       preparations = preparations ?? [];

  String name;
  String description;
  String? image;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStage> stages;
  final List<RecipeNote> notes;
  final List<RecipePreparation> preparations;
  bool importedPreparationsRemoved = false;

  factory RecipeData.fromJson(Map<String, dynamic> json) => RecipeData(
    preparations: (json['preparations'] as List? ?? [])
        .map(
          (e) =>
              RecipePreparation.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    image: json['image'] as String?,
    notes: (json['notes'] as List? ?? [])
        .map((e) => RecipeNote.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    ingredients: (json['ingredients'] as List? ?? [])
        .map(
          (e) => RecipeIngredient.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    stages: (json['stages'] as List? ?? [])
        .map((e) => RecipeStage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  factory RecipeData.fromExternalJson(Map<String, dynamic> json) {
    final safe = Map<String, dynamic>.of(json)..remove('preparations');
    return RecipeData.fromJson(safe)
      ..importedPreparationsRemoved =
          json.containsKey('preparations') &&
          json['preparations'] != null &&
          json['preparations'].toString() != '[]';
  }

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'description': description,
    'image': image,
    'notes': notes.map((e) => e.toJson()).toList(),
    if (preparations.isNotEmpty)
      'preparations': preparations.map((e) => e.toJson()).toList(),
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'stages': stages.map((e) => e.toJson()).toList(),
  };

  RecipeData copy() => RecipeData.fromJson(
    jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>,
  );
  int get nextId =>
      [
        ...ingredients.map((e) => e.id),
        ...stages.map((e) => e.id),
      ].fold(0, (a, b) => a > b ? a : b) +
      1;

  List<RecipeIssue> validate() {
    final issues = <RecipeIssue>{};
    if (preparations.map((p) => p.recipeId).toSet().length !=
            preparations.length ||
        preparations.any(
          (p) => p.recipeId <= 0 || !stages.any((s) => s.id == p.stageId),
        )) {
      issues.add(RecipeIssue.preparations);
    }
    if (notes.any((n) => n.title.trim().isEmpty)) issues.add(RecipeIssue.notes);
    if (name.trim().isEmpty) issues.add(RecipeIssue.name);
    final ids = [...ingredients.map((e) => e.id), ...stages.map((e) => e.id)];
    if (ids.toSet().length != ids.length || ids.any((id) => id <= 0)) {
      issues.add(RecipeIssue.references);
    }
    if (ingredients.any((e) => e.name.trim().isEmpty) ||
        stages.any((e) => e.name.trim().isEmpty)) {
      issues.add(RecipeIssue.labels);
    }
    if (ingredients.any(
      (e) => e.amount != null && (!e.amount!.isFinite || e.amount! < 0),
    )) {
      issues.add(RecipeIssue.quantity);
    }
    for (final stage in stages) {
      if (stage.durationMin != null && stage.durationMin! < 0 ||
          stage.durationMax != null && stage.durationMax! < 0 ||
          stage.durationMin != null &&
              stage.durationMax != null &&
              stage.durationMax! < stage.durationMin!) {
        issues.add(RecipeIssue.duration);
      }
      if (stage.temperatureMin != null &&
          stage.temperatureMax != null &&
          stage.temperatureMax! < stage.temperatureMin!) {
        issues.add(RecipeIssue.temperature);
      }
      final seen = <int>{};
      for (final ref in stage.ingredients) {
        if (!ids.contains(ref.id) || ref.id == stage.id || !seen.add(ref.id)) {
          issues.add(RecipeIssue.references);
        }
        if (ref.amount != null && (!ref.amount!.isFinite || ref.amount! < 0)) {
          issues.add(RecipeIssue.quantity);
        }
      }
    }
    final visiting = <int>{};
    final visited = <int>{};
    final byId = {for (final stage in stages) stage.id: stage};
    bool cycle(int id) {
      if (visiting.contains(id)) return true;
      if (!visited.add(id)) return false;
      visiting.add(id);
      for (final ref in byId[id]!.ingredients) {
        if (byId.containsKey(ref.id) && cycle(ref.id)) return true;
      }
      visiting.remove(id);
      return false;
    }

    if (byId.keys.any(cycle)) issues.add(RecipeIssue.references);
    // Dependencies must appear before the stage that consumes them.
    final positions = {for (var i = 0; i < stages.length; i++) stages[i].id: i};
    for (var i = 0; i < stages.length; i++) {
      if (stages[i].ingredients.any(
        (ref) => positions.containsKey(ref.id) && positions[ref.id]! >= i,
      )) {
        issues.add(RecipeIssue.references);
      }
    }
    return issues.toList();
  }

  bool get bakingReady =>
      validate().isEmpty &&
      ingredients.isNotEmpty &&
      stages.isNotEmpty &&
      stages.every((e) => e.durationMin != null && e.durationMax != null);
}

enum RecipeIssue {
  preparations,
  name,
  labels,
  references,
  quantity,
  duration,
  temperature,
  notes,
}

class RecipeIngredient {
  RecipeIngredient({
    required this.id,
    this.name = '',
    this.amount,
    this.unit = '',
    this.condition = '',
  });
  int id;
  String name;
  double? amount;
  String unit;
  String condition;
  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble(),
        unit: json['unit'] as String? ?? '',
        condition: json['condition'] as String? ?? '',
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'unit': unit,
    'condition': condition,
  };
}

class IngredientReference {
  IngredientReference({required this.id, this.amount, this.condition = ''});
  int id;
  double? amount;
  String condition;
  factory IngredientReference.fromJson(Map<String, dynamic> json) =>
      IngredientReference(
        id: (json['id'] as num).toInt(),
        amount: (json['amount'] as num?)?.toDouble(),
        condition: json['condition'] as String? ?? '',
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'condition': condition,
  };
}

class RecipeStage {
  RecipeStage({
    required this.id,
    this.name = '',
    this.description = '',
    this.durationMin,
    this.durationMax,
    this.temperatureMin,
    this.temperatureMax,
    List<IngredientReference>? ingredients,
  }) : ingredients = ingredients ?? [];
  int id;
  String name;
  String description;
  int? durationMin;
  int? durationMax;
  int? temperatureMin;
  int? temperatureMax;
  final List<IngredientReference> ingredients;
  factory RecipeStage.fromJson(Map<String, dynamic> json) {
    final duration = json['duration'] as Map?;
    final multiplier = duration?['unit'] == 'hours' ? 60 : 1;
    return RecipeStage(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationMin: (duration?['lower value'] as num?) == null
          ? null
          : ((duration!['lower value'] as num) * multiplier).round(),
      durationMax: (duration?['upper value'] as num?) == null
          ? null
          : ((duration!['upper value'] as num) * multiplier).round(),
      temperatureMin: (json['temperature']?['lower value'] as num?)?.toInt(),
      temperatureMax: (json['temperature']?['upper value'] as num?)?.toInt(),
      ingredients: (json['ingredients'] as List? ?? [])
          .map(
            (e) => IngredientReference.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'duration': {
      'unit': 'minutes',
      'lower value': durationMin,
      'upper value': durationMax,
    },
    'temperature': temperatureMin == null && temperatureMax == null
        ? null
        : {'lower value': temperatureMin, 'upper value': temperatureMax},
  };
}

class RecipeImport {
  static List<RecipeData> parse(String source) {
    final value = jsonDecode(source);
    final recipes = <RecipeData>[];
    void visit(dynamic node) {
      if (node is List) {
        for (final item in node) {
          visit(item);
        }
        return;
      }
      if (node is! Map<String, dynamic>) return;
      if (node.containsKey('@graph')) visit(node['@graph']);
      final types = node['@type'] is List
          ? node['@type'] as List
          : [node['@type']];
      if (types.any(
        (e) =>
            e is String &&
            (e == 'Recipe' || e.endsWith('/Recipe') || e.endsWith(':Recipe')),
      )) {
        recipes.add(_schemaRecipe(node));
      } else if (!node.containsKey('@type') &&
          node['name'] is String &&
          !node.containsKey('@graph')) {
        recipes.add(RecipeData.fromExternalJson(node));
      }
    }

    visit(value);
    if (recipes.isEmpty) throw const FormatException('recipe');
    return recipes;
  }

  static RecipeData _schemaRecipe(Map<String, dynamic> json) {
    final result = RecipeData(
      name: json['name'] as String? ?? '',
      description: json['description'] is String
          ? json['description'] as String
          : '',
    );
    result.importedPreparationsRemoved =
        json.containsKey('preparations') &&
        json['preparations'] != null &&
        json['preparations'].toString() != '[]';
    final ingredients = json['recipeIngredient'];
    for (final text
        in ingredients is List
            ? ingredients
            : ingredients is String
            ? [ingredients]
            : []) {
      result.ingredients.add(
        RecipeIngredient(id: result.nextId, name: text.toString()),
      );
    }
    void instruction(dynamic item) {
      if (item is List) {
        for (final child in item) {
          instruction(child);
        }
      } else if (item is String && item.trim().isNotEmpty) {
        result.stages.add(
          RecipeStage(
            id: result.nextId,
            name: '${result.stages.length + 1}',
            description: item,
          ),
        );
      } else if (item is Map) {
        if (item['itemListElement'] != null) {
          instruction(item['itemListElement']);
        } else if (item['text'] is String) {
          final stage = RecipeStage(
            id: result.nextId,
            name: item['name'] as String? ?? '${result.stages.length + 1}',
            description: item['text'] as String,
          );
          result.stages.add(stage);
        }
      }
    }

    instruction(json['recipeInstructions']);
    return result;
  }
}
