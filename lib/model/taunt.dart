import 'package:startistics/model/base.dart';

class TauntModel implements BaseModel {
  final String tauntId;
  final String tauntName;

  TauntModel({required this.tauntId, required this.tauntName});

  factory TauntModel.fromJson(Map<String, dynamic> json) {
    return TauntModel(
      tauntId: json['tauntId'] ?? '',
      tauntName: json['tauntName'] ?? '',
    );
  }
}
