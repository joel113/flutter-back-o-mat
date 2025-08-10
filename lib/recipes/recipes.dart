import 'package:flutter/material.dart';
import 'dart:convert';
import 'item.dart';
import '../util/db/db.dart';

class BackomatRecipes extends StatefulWidget {
  const BackomatRecipes({super.key});

  @override
  State<BackomatRecipes> createState() => _BackomatRecipesState();
}

class _BackomatRecipesState extends State<BackomatRecipes> {
  final dbHelper = DatabaseHelperJson();
  final recipes = <Item>[];

  @override
  void initState() {
    addRecipesFromDatabase();
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

  void addRecipesFromDatabase() async {
    await dbHelper.getAllRecipeJsonEntries().then((entries) {
      for (var entry in entries) {
        final json = jsonDecode(entry.jsonData);
        final image = Image.asset("assets/images/${json["image"]}");
        final item = Item(
            id: entry.id,
            image: image,
            name: entry.name,
            description: json["description"]);
        setState(() {
          recipes.add(item);
        });
      }
    });
  }
}
