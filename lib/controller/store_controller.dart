import 'package:pos/service/app_services.dart';
import 'package:signals/signals_flutter.dart';

class StoreController {
  final store = futureSignal(() async => storeService.getStore());
}

final storeController = StoreController();
