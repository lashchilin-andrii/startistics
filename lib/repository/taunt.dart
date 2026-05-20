import 'package:startistics/model/taunt.dart';
import 'package:startistics/repository/base.dart';

class TauntRepository extends BaseRepository {
  Future<List<TauntModel>> readAllTaunts() async {
    return readAll<TauntModel>(
      sectionName: 'taunts',
      fromJson: TauntModel.fromJson,
    );
  }
}
