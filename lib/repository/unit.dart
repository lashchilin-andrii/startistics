import 'package:startistics/model/unit.dart';
import 'package:startistics/repository/base.dart';

class UnitRepository extends BaseRepository {
  Future<List<UnitModel>> readAllUnits() async {
    return readAll<UnitModel>(
      sectionName: 'units',
      fromJson: UnitModel.fromJson,
    );
  }
}
