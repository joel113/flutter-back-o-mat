import 'package:flutter/material.dart';

import 'editor/recipe_view.dart';

class BackomatBacker extends StatelessWidget {
  const BackomatBacker({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext context) => RecipeView(id: id, baking: true);
}
