import 'package:flutter/material.dart';

/// Shared heading spacing for both empty and populated editor sections.
class RecipeEditorSection extends StatelessWidget {
  const RecipeEditorSection({
    super.key,
    required this.title,
    required this.child,
  });
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      child,
    ],
  );
}
