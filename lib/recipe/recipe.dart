import 'package:flutter/material.dart';

class Recipe extends StatelessWidget {
  const Recipe({Key? key}) : super(key: key);

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: const Text(
                    'Bergkruste',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Sauerteigbrot mit Roggen und Dinkel',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.star,
            color: Colors.red[500],
          ),
          const Text('41'),
        ],
      ),
    );

    Widget buttonSection = Padding(
        padding: EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildButtonColumn(color, Icons.exit_to_app, 'Plan'),
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

    return ListView(
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
    );
  }
}
