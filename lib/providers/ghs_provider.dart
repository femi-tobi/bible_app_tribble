import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../services/ghs_service.dart';

class GhsProvider with ChangeNotifier {
  final GhsService _ghsService = GhsService();
  
  Hymn? _currentHymn;
  bool _isLoading = false;
  String? _error;

  Hymn? get currentHymn => _currentHymn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> selectHymn(int number) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hymn = await _ghsService.getHymn(number);
      if (hymn != null) {
        _currentHymn = hymn;
      } else {
        _error = 'Hymn #$number not found';
      }
    } catch (e) {
      _error = 'Error loading hymn: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Hymn>> searchHymns(String query) async {
    return await _ghsService.searchHymn(query);
  }

  Future<int> getTotalHymns() async {
    return await _ghsService.getTotalHymns();
  }

  void clearSelection() {
    _currentHymn = null;
    _error = null;
    notifyListeners();
  }
}
