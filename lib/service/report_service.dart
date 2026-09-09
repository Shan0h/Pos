import 'package:collection/collection.dart';
import 'package:isar/isar.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/supabase_service.dart';

class ReportService {
  final Database _database;
  ReportService(this._database);

  IsarCollection<PenjualanModel> get _collection => _database.isar.penjualanModels;
  SupabaseHelper get _supabase => _database.supabaseHelper;
  bool get _canSync => _database.canSync;
  DateTime get _now => _database.now;

  Future<void> _markSynced(int id) async {
    final item = await _collection.get(id);
    if (item == null) return;
    item.isSynced = true;
    await _database.isar.writeTxn(() async => await _collection.put(item));
  }

  Future<void> addPenjualan(PenjualanModel val) async {
    val.updatedAt = _now;
    val.isDeleted = false;
    val.isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.addReport(val.toJson());
      await _markSynced(val.id!);
    }
  }

  Future<void> syncItemPenjualan(PenjualanModel val) async {
    if (_canSync) {
      final exists = await _supabase.getReportById(val.id!);
      if (exists) {
        await _supabase.updateReport(val);
      } else {
        await _supabase.addReport(val.toJson());
      }
      await _markSynced(val.id!);
    }
  }

  Future<void> removePenjualan(int val) async {
    final existing = await _collection.get(val);
    if (existing == null) return;
    if (_canSync) {
      await _supabase.removeReport(val);
      await _database.isar.writeTxn(() async => await _collection.delete(val));
      return;
    }
    existing
      ..updatedAt = _now
      ..isDeleted = true
      ..isSynced = false;
    await _database.isar.writeTxn(() async => await _collection.put(existing));
  }

  Future<List<PenjualanModel>> getReport({required DateTime start, required DateTime end}) async {
    return _collection
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(start.copyWith(hour: 0, minute: 0, second: 0),
            end.copyWith(hour: 23, minute: 59, second: 59))
        .findAll();
  }

  Future<List<PenjualanModel>> getReportById({required DateTime start, required DateTime end, int? userId}) async {
    return _collection
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(
          start.copyWith(hour: 0, minute: 0, second: 0),
          end.copyWith(hour: 23, minute: 59, second: 59),
        )
        .staffIdEqualTo(userId ?? 0)
        .findAll();
  }

  Future<List<PenjualanModel>> getReportToday() async {
    return _collection
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(
            DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
            DateTime.now().copyWith(hour: 23, minute: 59, second: 59))
        .findAll();
  }

  Future<List<PenjualanModel>> getReportYesterday() async {
    return _collection
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(
            DateTime.now().subtract(const Duration(days: 1)).copyWith(hour: 0, minute: 0, second: 0),
            DateTime.now().subtract(const Duration(days: 1)).copyWith(hour: 23, minute: 59, second: 59))
        .findAll();
  }

  Future<Map<int, List<PenjualanModel>>> getSalesByUser() async {
    final items = await _collection.filter().isDeletedEqualTo(false).findAll();
    return items.groupListsBy((i) => i.staffId);
  }

  Future<Map<DateTime, List<PenjualanModel>>> getSalesByDate({required DateTime start, required DateTime end}) async {
    final items = _collection
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(start.copyWith(hour: 0, minute: 0, second: 0),
            end.copyWith(hour: 23, minute: 59, second: 59))
        .findAllSync();
    return items.groupListsBy((order) => DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day));
  }

  Future<List<PenjualanModel>> getReportAll() async {
    return _collection.where().findAll();
  }

  Future<void> checkIsReportSynced() async {
    if (!_canSync) return;
    final localReports = await getReportAll();
    for (final report in localReports.where((r) => !r.isSynced)) {
      if (report.isDeleted) {
        await _supabase.removeReport(report.id!);
        await _database.isar.writeTxn(() async => await _collection.delete(report.id!));
        continue;
      }
      final exists = await _supabase.getReportById(report.id!);
      if (exists) {
        await _supabase.updateReport(report);
      } else {
        await _supabase.addReport(report.toJson());
      }
      await _markSynced(report.id!);
    }
    final remoteReports = await _supabase.getRepots();
    await _database.isar.writeTxn(() async {
      for (final remote in remoteReports) {
        final local = await _collection.get(remote.id!);
        if (local != null && !local.isSynced) continue;
        remote
          ..isDeleted = false
          ..isSynced = true;
        await _collection.put(remote);
      }
    });
  }
}
