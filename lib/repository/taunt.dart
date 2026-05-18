import 'package:startistics/model/taunt.dart';
import 'package:startistics/service/json_asset_data_source.dart';

class TauntRepository {
  final JsonAssetDataSource _dataSource;
  TauntRepository(this._dataSource);

  Future<List<TauntModel>> getTaunts() async {
    final rawList = await _dataSource.getSection('taunts');
    return rawList.map((e) => TauntModel.fromJson(e)).toList();
  }
}
