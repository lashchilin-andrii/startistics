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
}
