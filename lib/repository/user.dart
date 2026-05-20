import 'package:startistics/model/user.dart';
import 'package:startistics/repository/base.dart';

class UserRepository extends BaseRepository {
  UserRepository(super.dataSource);

  // Передаем имя группы (например, 'users' или 'usersStandarts') динамически через параметр
  Future<List<UserModel>> getUsers(String sectionName) async {
    return loadData<UserModel>(
      sectionName: sectionName,
      fromJson: UserModel.fromJson,
    );
  }
}