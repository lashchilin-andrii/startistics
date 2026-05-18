import 'package:startistics/model/unit.dart';
import 'package:startistics/service/json_asset_data_source.dart';

class UnitRepository {
  final JsonAssetDataSource _dataSource;
  UnitRepository(this._dataSource);

  Future<List<UnitModel>> getUnits() async {
    final rawList = await _dataSource.getSection('units');
    return rawList.map((e) => UnitModel.fromJson(e)).toList();
  }
}
