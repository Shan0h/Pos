import 'package:pos/model/customer_model.dart';
import 'package:pos/service/app_services.dart';
import 'package:signals/signals_flutter.dart';

class CustomerController {
  final searchCustomer = signal<String?>(null);
  final customer = futureSignal(() async =>
      customerService.getCustomers(name: customerController.searchCustomer.value));
  final customerSelected = signal<CustomerModel?>(null);
}

final customerController = CustomerController();
