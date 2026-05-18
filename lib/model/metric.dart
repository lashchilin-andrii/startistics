class MetricDefinitionModel {
  final String metricId;
  final String metricName;
  final String unitId;
  final bool lowerIsBetter;
  final List<String> tauntIds;

  MetricDefinitionModel({
    required this.metricId,
    required this.metricName,
    required this.unitId,
    required this.lowerIsBetter,
    required this.tauntIds,
  });

  factory MetricDefinitionModel.fromJson(Map<String, dynamic> json) {
    return MetricDefinitionModel(
      metricId: json['metricId'] ?? '',
      metricName: json['metricName'] ?? '',
      unitId: json['unitId'] ?? '',
      lowerIsBetter: json['lowerIsBetter'] ?? false,
      tauntIds: List<String>.from(json['tauntIds'] ?? []),
    );
  }
}
