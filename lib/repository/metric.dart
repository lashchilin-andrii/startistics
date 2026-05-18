import 'package:startistics/model/metric.dart'; // Изменен импорт
import 'package:startistics/service/json_asset_data_source.dart';

class MetricRepository {
  final JsonAssetDataSource _dataSource;
  MetricRepository(this._dataSource);

  // Теперь возвращает правильный тип данных
  Future<List<MetricDefinitionModel>> getMetricDefinitions() async {
    final rawList = await _dataSource.getSection('metrics');
    return rawList.map((e) => MetricDefinitionModel.fromJson(e)).toList();
  }
}