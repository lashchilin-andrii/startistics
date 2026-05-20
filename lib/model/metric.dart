import 'package:startistics/model/base.dart';

class MetricModel extends BaseModel {
  final String metricId;
  final String metricName;
  final String unitId;
  final bool lowerIsBetter;
  final List<String> tauntIds;

  MetricModel({
    required this.metricId,
    required this.metricName,
    required this.unitId,
    required this.lowerIsBetter,
    required this.tauntIds,
  });

  factory MetricModel.fromJson(Map<String, dynamic> json) {
    return MetricModel(
      metricId: json['metricId'] ?? '',
      metricName: json['metricName'] ?? '',
      unitId: json['unitId'] ?? '',
      lowerIsBetter: json['lowerIsBetter'] ?? false,
      tauntIds: List<String>.from(json['tauntIds'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'metricId': metricId,
      'metricName': metricName,
      'unitId': unitId,
      'lowerIsBetter': lowerIsBetter,
      'tauntIds': tauntIds, 
    };
  }
}