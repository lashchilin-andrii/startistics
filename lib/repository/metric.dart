import 'package:startistics/model/metric.dart';
import 'package:startistics/repository/base.dart';

class MetricRepository extends BaseRepository {
  Future<List<MetricModel>> readAllMetrics() async {
    return readAll<MetricModel>(
      sectionName: 'metrics',
      fromJson: MetricModel.fromJson,
    );
  }
}
