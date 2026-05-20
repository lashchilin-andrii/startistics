import 'package:startistics/model/taunt.dart';
import 'package:startistics/repository/base.dart';

class TauntRepository extends BaseRepository {
  TauntRepository(super.dataSource);

  Future<List<TauntModel>> getTaunts() async {
    return loadData<TauntModel>(
      sectionName: 'taunts',
      fromJson: TauntModel.fromJson,
    );
  }
}