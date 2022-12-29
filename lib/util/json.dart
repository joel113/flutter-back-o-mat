import 'dart:collection';

class Json {
  static Map<dynamic, dynamic> mapify(
      List<dynamic> ingredients, List<dynamic> stageIngredients) {
    var ingredientsMap = HashMap.fromIterable(ingredients,
        key: (element) => element['id'], value: (element) => element);
    var stageIngredientsMap = HashMap.fromIterable(stageIngredients,
        key: (element) => element['id'], value: (element) => element);
    stageIngredientsMap.forEach((key, value) {
      if (!ingredientsMap.containsKey(key)) {
        ingredientsMap.putIfAbsent(key, () => value);
      }
    });
    return ingredientsMap;
  }

  static List<dynamic> merge(Map<dynamic, dynamic> ingredientsMap,
      List<dynamic> stageIngredients) {
    var mergedStageIngredients = stageIngredients.map((e) {
      e.putIfAbsent("name", () => ingredientsMap[e["id"]]["name"]);
      e.putIfAbsent("unit", () => ingredientsMap[e["id"]]["unit"]);
      return e;
    }).toList();
    return mergedStageIngredients;
  }
}
