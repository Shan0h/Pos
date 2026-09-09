import 'package:pos/service/app_services.dart';
import 'package:signals/signals_flutter.dart';

class AuthController {
  final customer = futureSignal(() async => database.authUser());
}

final authController = AuthController();
