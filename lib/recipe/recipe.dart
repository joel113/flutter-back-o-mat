import 'dart:convert';

import 'package:flutter/material.dart';
import '../util/util.dart';
import 'item.dart';

class BackometRecipe extends StatefulWidget {
  const BackometRecipe({Key? key, required this.filename}) : super(key: key);

  final String filename;

  @override
  State<BackometRecipe> createState() => _BackomatRecipe();
}

class _BackomatRecipe extends State<BackometRecipe> {
  Item? recipe;

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
    Widget titleSection = Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Container(child: recipe),
          Icon(
            Icons.star,
            color: Colors.red[500],
          ),
          const Text('41'),
        ],
      ),
    );

    Widget buttonSection = Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildButtonColumn(color, Icons.not_started, 'Start'),
            _buildButtonColumn(color, Icons.share, 'Share'),
          ],
        ));

    Widget textSection = const Padding(
      padding: EdgeInsets.only(left: 32),
      child: Text(
        'Ein schönes Brot aus Roggen und Dinkel. Durch die Verwendung von Dinkel'
        'bekommt das Brot einen tollen Geschmack. Ich habe das Brot von Plötzblog'
        'schon mehrmals gebacken. Das Rezept stammt vom Plötzblog und ist unter'
        'https://www.ploetzblog.de/2021/05/29/bergkruste-sauerteigbrot-mit-roggen-und-dinkel/ zu finden.',
        softWrap: true,
      ),
    );

    return Scaffold(
        appBar: AppBar(
          title: const Text('Backomat'),
        ),
        body: ListView(
          children: [
            Image.asset(
              'images/DSC_4302.jpg',
              width: 600,
              height: 240,
              fit: BoxFit.cover,
            ),
            titleSection,
            textSection,
            buttonSection,
          ],
        ));
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
