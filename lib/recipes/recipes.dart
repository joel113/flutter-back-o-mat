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
    return Scaffold(
      body: ListView.separated(
        itemCount: recipes.length,
        itemBuilder: (BuildContext itemContext, int index) {
          return Container(
            child: recipes[index],
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
      backgroundColor: Colors.grey[200],
    );
  }

  void addRecipesFromApplicationDocuments() async {
    await _applicationDocumentFiles.then((fileEntity) => fileEntity
        .whereType<File>()
        .where((element) =>
            element.path
                .substring(element.path.length - 4, element.path.length) ==
            "json")
        .forEach((file) => file.readAsString().then((fileString) {
              final decodedJson = jsonDecode(fileString);
              final image = Image.file(
                  File("${file.parent.path}/${decodedJson["image"]}"));
              final item = Item(
                  image: image,
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
