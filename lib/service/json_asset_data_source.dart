import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class JsonAssetDataSource {
  final String assetPath;
  Map<String, dynamic>? _cachedData;

  JsonAssetDataSource({this.assetPath = 'asset/db.json'});

  Future<Map<String, dynamic>> _getRawData() async {
    if (_cachedData != null) return _cachedData!;

    final String jsonString = await rootBundle.loadString(assetPath);
    _cachedData = jsonDecode(jsonString);
    return _cachedData!;
  }

  Future<List<dynamic>> getSection(String key) async {
    final data = await _getRawData();
    return data[key] ?? [];
  }
}
