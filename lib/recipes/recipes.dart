import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'item.dart';

class BackomatRecipes extends StatefulWidget {
  const BackomatRecipes({Key? key}) : super(key: key);

  @override
  State<BackomatRecipes> createState() => _BackomatRecipesState();
}

class _BackomatRecipesState extends State<BackomatRecipes> {
  final recipes = <Item>[];

  @override
  void initState() {
    addRecipesFromApplicationDocuments();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (BuildContext itemContext, int index) {
          return recipes[index];
        }));
  }

  void addRecipesFromApplicationDocuments() async {
    await _applicationDocumentFiles
        .then((fileEntity) => fileEntity
          .whereType<File>()
          .forEach((file) => file.readAsString()
            .then((fileString) {
              final decodedJson = jsonDecode(fileString);
              final item = Item(
                name: decodedJson["name"],
                description: decodedJson["description"]);
              setState(() {
                recipes.add(item);
              });
            })));
  }

  Future<String> get _applicationDocumentsPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<List<FileSystemEntity>> get _applicationDocumentFiles async {
    final path = await _applicationDocumentsPath;
    final dir = Directory('$path/recipes');
    final future = dir.exists().then((value) {
      if (!value) {
        dir.create();
      }
    });
    return future.then((value) => dir.list().toList());
  }
}
