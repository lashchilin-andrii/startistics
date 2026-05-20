import 'package:startistics/model/base.dart';
import 'package:startistics/model/user_metric.dart';

class UserModel implements BaseModel {
  final String userId;
  final String userName;
  final String userSex;
  final int userAge;
  final int userHeightCm;
  final double userWeightKg;
  final List<UserMetricModel> userMetrics;

  UserModel({
    required this.userId,
    required this.userName,
    required this.userSex,
    required this.userAge,
    required this.userHeightCm,
    required this.userWeightKg,
    required this.userMetrics,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userSex: json['userSex'] ?? '',
      userAge: json['userAge'] ?? 0,
      userHeightCm: json['userHeightCm'] ?? 0,
      userWeightKg: (json['userWeightKg'] ?? 0.0).toDouble(),
      userMetrics: (json['userMetrics'] as List? ?? [])
          .map((e) => UserMetricModel.fromJson(e))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userSex': userSex,
      'userAge': userAge,
      'userHeightCm': userHeightCm,
      'userWeightKg': userWeightKg,
      'userMetrics': userMetrics.map((e) => e.toJson()).toList(),
    };
  }
}
