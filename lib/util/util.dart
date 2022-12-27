import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Util {
  static Future<String> get _applicationDocumentsPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<List<FileSystemEntity>> applicationDocumentFiles() async {
    final path = await _applicationDocumentsPath;
    final dir = Directory('$path/recipes');
    final future = dir.exists().then((value) {
      if (!value) {
        dir.create();
      }
    });
    return future.then((value) => dir.list().toList());
  }

  static Future<File> applicationDocumentFile(String filename) async {
    final file = File(filename);
    final future = file.exists().then((value) => (value)
        ? Future.value(file)
        : Future.error(Exception("File could not be found.")));
    return future.then((value) => value);
  }
}
