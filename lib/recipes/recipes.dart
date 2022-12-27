import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../util/util.dart';
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
    await Util.applicationDocumentFiles().then((fileEntity) => fileEntity
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
                  filename: file.path,
                  image: image,
                  name: decodedJson["name"],
                  description: decodedJson["description"]);
              setState(() {
                recipes.add(item);
              });
            })));
  }
}
