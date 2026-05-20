import 'package:startistics/model/base.dart';

class UnitModel implements BaseModel {
  final String unitId;
  final String unitName;

  UnitModel({required this.unitId, required this.unitName});

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      unitId: json['unitId'] ?? '',
      unitName: json['unitName'] ?? '',
    );
  }
}
