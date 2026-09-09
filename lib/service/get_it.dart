import 'package:pos/controller/selling/events.dart';
import 'package:pos/controller/selling/service.dart';
import 'package:pos/controller/selling_controller.dart';
import 'package:pos/controller/user_controller.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/user_service.dart';
import 'package:pos/service/customer_service.dart';
import 'package:pos/service/inventory_service.dart';
import 'package:pos/service/report_service.dart';
import 'package:pos/service/expenses_service.dart';
import 'package:pos/service/salary_service.dart';
import 'package:pos/service/store_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setup() {
  getIt.registerLazySingleton<Database>(() => Database());
  getIt.registerLazySingleton<UserService>(() => UserService(getIt.get<Database>()));
  getIt.registerLazySingleton<CustomerService>(() => CustomerService(getIt.get<Database>()));
  getIt.registerLazySingleton<InventoryService>(() => InventoryService(getIt.get<Database>()));
  getIt.registerLazySingleton<ReportService>(() => ReportService(getIt.get<Database>()));
  getIt.registerLazySingleton<ExpensesService>(() => ExpensesService(getIt.get<Database>()));
  getIt.registerLazySingleton<SalaryService>(() => SalaryService(getIt.get<Database>()));
  getIt.registerLazySingleton<StoreService>(() => StoreService(getIt.get<Database>()));
  getIt.registerLazySingleton<UserController>(() => UserController());
  getIt.registerLazySingleton<CartService>(() => CartService());
  getIt.registerLazySingleton<SellingController>(() =>
      SellingController(getIt.get<CartService>())..dispatch(CartStarted()));
}
