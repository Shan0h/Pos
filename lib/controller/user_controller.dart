import 'package:pos/model/user_model.dart';
import 'package:pos/service/database.dart';
import 'package:signals/signals_flutter.dart';

class UserController {
  final searchUser = signal<String?>(null);
  final users = futureSignal(
      () async => Database().getUsers(name: userController.searchUser.value));
  final userSelected = signal<UserModel?>(null);
}

final userController = UserController();
