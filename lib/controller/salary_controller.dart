import 'package:pos/model/salary_model.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/service/database.dart';
import 'package:signals/signals_flutter.dart';

class SalaryController {
  final salaries = futureSignal(() async => Database().getSalary());
  final salarySelected = signal<SalaryModel?>(null);
  final dateRange = listSignal(
      [DateTime.now().subtract(const Duration(days: 31)), DateTime.now()]);
  final userId = signal<UserModel?>(null);
  final calculate = futureSignal(
    () async => Database().getReportById(
      start: salaryController.dateRange.first,
      end: salaryController.dateRange.last,
      userId: salaryController.userId.value?.id,
    ),
  );
}

final salaryController = SalaryController();
