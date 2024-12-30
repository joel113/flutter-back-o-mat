import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_back_o_mat/planner/planner.dart';
import 'package:flutter_back_o_mat/recipes/recipes.dart';

class BackomatNavigation extends StatefulWidget {
  const BackomatNavigation({super.key});

  @override
  State<BackomatNavigation> createState() => _BackomatNavigationState();
}

class _BackomatNavigationState extends State<BackomatNavigation> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    BackomatRecipes(),
    BackomatPlanner(),
    Text(
      'Index 2: School',
      style: optionStyle,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backomat'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: AppLocalizations.of(context)?.recipes,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.lock_clock),
            label: AppLocalizations.of(context)?.planer,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info),
            label: AppLocalizations.of(context)?.info,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
