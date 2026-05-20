import 'package:startistics/model/user.dart';
import 'package:startistics/repository/base.dart';

class UserRepository extends BaseRepository {
  Future<List<UserModel>> readAllUsers({String sectionName = "users"}) async {
    return readAll<UserModel>(
      sectionName: sectionName,
      fromJson: UserModel.fromJson,
    );
  }

  // Метод стал чистым и аккуратным
  Future<void> saveUsers(
    List<UserModel> users, {
    String sectionName = "users",
  }) async {
    await writeAll<UserModel>(sectionName: sectionName, models: users);
  }
}
