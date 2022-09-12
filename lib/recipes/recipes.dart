import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'item.dart';

class BackomatReceipes extends StatefulWidget {
  const BackomatReceipes({Key? key}) : super(key: key);

  @override
  State<BackomatReceipes> createState() => _BackomatReceipesState();
}

class _BackomatReceipesState extends State<BackomatReceipes> {
  final _receipesList = <Item>[
    Item(
      name: 'Bergkruste',
      description: 'Intensives aromatisches Brot aus Dinkel und Roggen.',
    ),
    Item(
      name: 'San Francisco Sourdough Bread aus Dinkel',
      description: 'Dinkelsauerteig Brot auf Basis des San Francisco Sourdough Bread Brotes aus dem Brotbackbuch Nr. 4.',
    )
  ];

  void _addItem() {}

  @override
  Widget build(BuildContext context) {
    final applicationDocumentFiles = _applicationDocmentFiles;
    return Scaffold(body: ListView(children: _receipesList.toList()));
  }

  Future<String> get _applicationDocumentsPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<List<FileSystemEntity>> get _applicationDocmentFiles async {
    final path = await _applicationDocumentsPath;
    final dir = Directory('$path/recipes');
    final future = dir.exists().then((value) {
      if(!value) {
        dir.create();
      }
    });
    final list = await future.whenComplete(() => dir.list().toList());
    return list;
  }
}