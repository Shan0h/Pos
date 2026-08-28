import 'package:pos/controller/selling/events.dart';
import 'package:pos/controller/selling/service.dart';
import 'package:pos/controller/selling_controller.dart';
import 'package:pos/controller/user_controller.dart';
import 'package:pos/service/database.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setup() {
  getIt.registerLazySingleton<Database>(() => Database());
  getIt.registerLazySingleton<UserController>(() => UserController());
  getIt.registerLazySingleton<CartService>(() => CartService());
  getIt.registerLazySingleton<SellingController>(() =>
      SellingController(getIt.get<CartService>())..dispatch(CartStarted()));
}
