class UserMetricModel {
  final String metricId;
  final double value;

  UserMetricModel({required this.metricId, required this.value});

  factory UserMetricModel.fromJson(Map<String, dynamic> json) {
    return UserMetricModel(
      metricId: json['metricId'] ?? '',
      value: (json['value'] ?? 0.0).toDouble(),
    );
  }
}
