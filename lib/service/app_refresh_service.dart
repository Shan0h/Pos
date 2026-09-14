import 'package:pos/controller/auth_controller.dart';
import 'package:pos/controller/awaiting_orders_controller.dart';
import 'package:pos/controller/customer_controller.dart';
import 'package:pos/controller/expenses_controller.dart';
import 'package:pos/controller/inventory_controller.dart';
import 'package:pos/controller/report_controller.dart';
import 'package:pos/controller/salary_controller.dart';
import 'package:pos/controller/selling/events.dart';
import 'package:pos/controller/selling_controller.dart';
import 'package:pos/controller/store_controller.dart';
import 'package:pos/controller/user_controller.dart';
import 'package:pos/service/get_it.dart';

/// Central helper for reloading every screen-driving signal in one call.
///
/// Used after the database file is swapped on disk (restore from backup):
/// screens render from in-memory signals created at startup, so a restored
/// DB is invisible until those signals re-run their queries.
class AppRefreshService {
  /// Reloads every screen-driving signal after the DB file is swapped.
  Future<void> reloadAll() async {
    // Store + auth (login state / staff identity).
    storeController.store.reload();
    authController.customer.reload();

    // Catalog + inventory (menu items & raw materials).
    inventoryController.inventorys.reload();
    inventoryController.menuItems.reload();

    // Reports (sales history, income, out-of-stock).
    reportController.report.reload();
    reportController.reportToday.reload();
    reportController.reportYesterday.reload();
    reportController.reportUser.reload();
    reportController.reportIncome.reload();
    reportController.reportOutOfStcok.reload();

    // Management screens.
    userController.users.reload();
    customerController.customer.reload();
    expensesController.expenses.reload();
    salaryController.salaries.reload();

    // Awaiting Orders (awaits its three internal signals).
    await awaitingOrdersController.refreshAll();

    // The cart is in-memory only and is not part of a backup — reset it
    // to a clean empty state after the DB swap.
    await getIt.get<SellingController>().dispatch(CartStarted());
  }
}

final appRefreshService = AppRefreshService();
