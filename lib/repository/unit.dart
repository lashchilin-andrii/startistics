import 'package:startistics/model/unit.dart';
import 'package:startistics/repository/base.dart';

class UnitRepository extends BaseRepository {
  UnitRepository(super.dataSource);

  Future<List<UnitModel>> getUnits() async {
    return loadData<UnitModel>(
      sectionName: 'units',
      fromJson: UnitModel.fromJson,
    );
  }
}