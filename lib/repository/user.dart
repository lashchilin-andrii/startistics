import 'package:startistics/model/user.dart';
import 'package:startistics/repository/base.dart';

class UserRepository extends BaseRepository {
  Future<List<UserModel>> readAllUsers({String sectionName = "users"}) async {
    return readAll<UserModel>(
      sectionName: sectionName,
      fromJson: UserModel.fromJson,
    );
  }
}
