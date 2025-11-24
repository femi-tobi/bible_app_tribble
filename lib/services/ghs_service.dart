import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hymn.dart';

class GhsService {
  List<Hymn>? _hymns;

  Future<void> _loadHymns() async {
    if (_hymns != null) return;

    try {
      final String response = await rootBundle.loadString('assets/ghs.json');
      final Map<String, dynamic> jsonData = json.decode(response);
      
      // The JSON has a "hymns" object with numbered keys
      final Map<String, dynamic> hymnsMap = jsonData['hymns'];
      
      // Convert the map to a list of hymns
      _hymns = hymnsMap.values.map((json) => Hymn.fromJson(json)).toList();
      
      // Sort by hymn number
      _hymns!.sort((a, b) => a.number.compareTo(b.number));
    } catch (e) {
      print('Error loading GHS data: $e');
      _hymns = [];
    }
  }

  Future<Hymn?> getHymn(int number) async {
    await _loadHymns();
    try {
      return _hymns?.firstWhere((h) => h.number == number);
    } catch (e) {
      return null;
    }
  }

  Future<List<Hymn>> searchHymn(String query) async {
    await _loadHymns();
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return _hymns?.where((hymn) {
      return hymn.title.toLowerCase().contains(lowerQuery) ||
          hymn.number.toString() == query;
    }).toList() ?? [];
  }

  Future<int> getTotalHymns() async {
    await _loadHymns();
    return _hymns?.length ?? 0;
  }

  Future<List<Hymn>> getAllHymns() async {
    await _loadHymns();
    return _hymns ?? [];
  }
}
