import 'package:startistics/model/base.dart';
import 'package:startistics/service/json_asset_data_source.dart';

abstract class BaseRepository {
  final JsonAssetDataSource dataSource = JsonAssetDataSource();

  BaseRepository();

  Future<List<T>> readAll<T extends BaseModel>({
    required String sectionName,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final rawList = await dataSource.getSection(sectionName);
    return rawList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeAll<T extends BaseModel>({
    required String sectionName,
    required List<T> models,
  }) async {
    final List<Map<String, dynamic>> rawList = models
        .map((m) => m.toJson())
        .toList();
    await dataSource.saveSection(sectionName, rawList);
  }
}
