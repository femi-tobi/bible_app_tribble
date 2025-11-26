import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/kjv.json');
  final content = await file.readAsString();
  final data = jsonDecode(content) as List;
  
  for (var book in data) {
    print('${book['abbrev']}');
  }
}
