import 'dart:convert';

import 'package:flutter/material.dart';
import '../util/util.dart';
import 'item.dart';

class BackomatRecipe extends StatefulWidget {
  const BackomatRecipe({super.key, required this.filename});

  final String filename;

  @override
  State<BackomatRecipe> createState() => _BackomatRecipe();
}

class _BackomatRecipe extends State<BackomatRecipe> {
  Item? recipe;

  Row _buildTopRow() {
    return Row(
      children: [
        Container(child: recipe),
        Icon(
          Icons.star,
          color: Colors.red[500],
        ),
        const Text('41'),
      ],
    );
  }

  Column _buildButtonColumn(Color color, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Color color = Theme.of(context).primaryColor;

    Widget headerSection = Image.asset(
      "images/${recipe?.image ?? "20220907-bergkruste.jpg"}",
      width: double.infinity,
      height: 240,
      fit: BoxFit.cover,
    );

    Widget titleSection = Padding(
        padding: const EdgeInsets.only(bottom: 16), child: _buildTopRow());

    Widget ingredientsSection = Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("Zutaten",
                textAlign: TextAlign.start,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ),
          recipe?.ingredients ?? const Text("")
        ]));

    Widget stagesSection = Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("Zubereitung",
                textAlign: TextAlign.start,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ),
          recipe?.stages ?? const Text("")
        ]));

    Widget buttonSection = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButtonColumn(color, Icons.not_started, 'Start'),
        _buildButtonColumn(color, Icons.share, 'Share'),
      ],
    );

    return Scaffold(
        appBar: AppBar(
          title: const Text('Backomat'),
        ),
        body: SingleChildScrollView(
            child: Column(children: [
          headerSection,
          Padding(
            padding:
                const EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              titleSection,
              ingredientsSection,
              stagesSection,
              buttonSection
            ]),
          )
        ])));
  }

  @override
  void initState() {
    super.initState();
    addRecipeFromApplicationDocument(widget.filename);
  }

  void addRecipeFromApplicationDocument(String name) async {
    await Util.applicationDocumentFile(name)
        .then((file) => file.readAsString().then((fileString) {
              setState(() => recipe = Item.fromJson(jsonDecode(fileString)));
            }));
  }
}
