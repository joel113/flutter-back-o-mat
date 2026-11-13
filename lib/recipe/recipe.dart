import 'package:flutter/material.dart';

import 'editor/recipe_view.dart';

class BackomatRecipe extends StatelessWidget {
  const BackomatRecipe({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext context) => RecipeView(id: id);
}
