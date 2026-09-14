import 'package:pos/model/penjualan_model.dart';
import 'package:pos/service/app_services.dart';
import 'package:signals/signals_flutter.dart';

/// Drives the Awaiting Orders screen and the live pending-count badges.
/// All data comes from the local Isar database (see
/// [ReportService.getAwaitingOrders]) — no cloud round-trip.
class AwaitingOrdersController {
  /// Today's orders with status 'pending' (awaiting preparation).
  final awaiting = futureSignal(() => reportService.getAwaitingOrders());

  /// Today's orders already marked done.
  final completed = futureSignal(() => reportService.getCompletedOrdersToday());

  /// Count of today's pending orders, for drawer/app-bar badges.
  final pendingCount = futureSignal(() => reportService.countAwaitingOrders());

  /// Reloads everything. Call after checkout, mark-as-done, or when the
  /// screen opens so new/changed orders show up immediately.
  Future<void> refreshAll() {
    return Future.wait([
      awaiting.reload(),
      completed.reload(),
      pendingCount.reload(),
    ]);
  }

  /// Marks [order] done locally and refreshes all signals.
  Future<void> markDone(PenjualanModel order) async {
    await reportService.markOrderDone(order.id!);
    await refreshAll();
  }

  /// Cancels (voids) a paid order that was never fulfilled:
  /// removes the record (hard delete online / soft delete offline, same as
  /// the report delete flow) and returns every line item to stock, since the
  /// goods were never handed over. Refreshes all signals afterwards.
  Future<void> cancelOrder(PenjualanModel order) async {
    // Stock must be restored BEFORE the order record disappears — it is the
    // source of truth for which items and quantities to put back.
    for (final item in order.items) {
      if (item.id != null && (item.quantity ?? 0) > 0) {
        await inventoryService.incrementStock(item.id!, item.quantity!);
      }
    }
    await reportService.removePenjualan(order.id!);
    await refreshAll();
  }
}

final awaitingOrdersController = AwaitingOrdersController();
