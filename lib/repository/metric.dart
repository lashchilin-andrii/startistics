import 'package:startistics/model/metric.dart';
import 'package:startistics/repository/base.dart';

class MetricRepository extends BaseRepository {
  MetricRepository(super.dataSource);

  Future<List<MetricModel>> getMetricDefinitions() async {
    return loadData<MetricModel>(
      sectionName: 'metrics',
      fromJson: MetricModel.fromJson,
    );
  }
}