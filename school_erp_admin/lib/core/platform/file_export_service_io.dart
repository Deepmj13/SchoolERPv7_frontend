import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveFile(List<int> bytes, String fileName, String mimeType) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}