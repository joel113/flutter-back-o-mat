import 'dart:convert';

import '../util/db/db.dart';

class RecipeSummary {
  const RecipeSummary({
    required this.id,
    required this.name,
    this.image,
    this.description,
    this.variantCount = 1,
    this.familyId,
  });

  final int id;
  final int? familyId;
  final int variantCount;
  final String name;
  final String? image;
  final String? description;

  factory RecipeSummary.fromEntry(RecipeJsonEntry entry) {
    final json = jsonDecode(entry.jsonData) as Map<String, dynamic>;
    return RecipeSummary(
      id: entry.id,
      familyId: entry.familyId,
      variantCount: entry.variantCount,
      name: entry.name,
      image: json['image'] as String?,
      description: json['description'] as String?,
    );
  }
}
