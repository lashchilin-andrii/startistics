import 'package:startistics/model/user.dart';
import 'package:startistics/service/json_asset_data_source.dart';

class UserRepository {
  final JsonAssetDataSource _dataSource;
  UserRepository(this._dataSource);

  Future<List<UserModel>> getUsers() async {
    final rawList = await _dataSource.getSection('users');
    return rawList.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<List<UserModel>> getUsersStandards() async {
    final rawList = await _dataSource.getSection('usersStandarts');
    return rawList.map((e) => UserModel.fromJson(e)).toList();
  }
}
