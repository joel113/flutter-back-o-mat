import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Only app-owned filenames are resolved; imported paths are never read.
class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, this.image, this.width, this.height});
  final String? image;
  final double? width;
  final double? height;

  static Future<String> copyCover(String source) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = await Directory('${root.path}/recipe_images')
        .create(recursive: true);
    final extension = source.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final name = '${DateTime.now().microsecondsSinceEpoch}.$extension';
    await File(source).copy('${directory.path}/$name');
    return 'local:$name';
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.bakery_dining_outlined)),
    );
    final name = image;
    Widget child = placeholder;
    if (name != null &&
        name.isNotEmpty &&
        !name.contains('/') &&
        !name.contains('\\')) {
      if (name.startsWith('local:')) {
        child = FutureBuilder<Directory>(
          future: getApplicationDocumentsDirectory(),
          builder: (context, snapshot) => snapshot.hasData
              ? Image.file(
                  File(
                    '${snapshot.data!.path}/recipe_images/${name.substring(6)}',
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => placeholder,
                )
              : placeholder,
        );
      } else {
        child = Image.asset(
          'assets/images/$name',
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) => placeholder,
        );
      }
    }
    return SizedBox(width: width, height: height, child: child);
  }
}
