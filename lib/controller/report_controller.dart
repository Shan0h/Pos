import 'package:pos/model/penjualan_model.dart';
import 'package:pos/service/app_services.dart';
import 'package:signals/signals_flutter.dart';

class ReportController {
  final dateRange = listSignal(
      [DateTime.now().subtract(const Duration(days: 31)), DateTime.now()]);
  final report = futureSignal(
    () async => reportService.getReport(
        start: reportController.dateRange.first,
        end: reportController.dateRange.last),
  );
  final reportToday = futureSignal(() async => reportService.getReportToday());
  final reportYesterday =
      futureSignal(() async => reportService.getReportYesterday());
  final reportUser = futureSignal(() async => reportService.getSalesByUser());
  final reportIncome = futureSignal(
    () async => reportService.getSalesByDate(
        start: reportController.dateRange.first,
        end: reportController.dateRange.last),
  );
  final reportOutOfStcok = futureSignal(() async => inventoryService.getOutStock());
  final bestSeller = listSignal<ProductItemModel>([], autoDispose: true);
}

final reportController = ReportController();
