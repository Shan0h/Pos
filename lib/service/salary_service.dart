import 'package:isar/isar.dart';
import 'package:pos/model/salary_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/supabase_service.dart';

class SalaryService {
  final Database _database;
  SalaryService(this._database);

  IsarCollection<SalaryModel> get _collection => _database.isar.salaryModels;
  SupabaseHelper get _supabase => _database.supabaseHelper;
  bool get _canSync => _database.canSync;
  DateTime get _now => _database.now;

  Future<void> _markSynced(int id) async {
    final item = await _collection.get(id);
    if (item == null) return;
    item.isSynced = true;
    await _database.isar.writeTxn(() async => await _collection.put(item));
  }

  Future<void> addSalary(SalaryModel val) async {
    val.updatedAt = _now;
    val.isDeleted = false;
    val.isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.addSalary(val.toJson());
      await _markSynced(val.id!);
    }
  }

  Future<void> updateSalary(SalaryModel val) async {
    val
      ..updatedAt = _now
      ..isDeleted = false
      ..isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.updateSalary(val);
      await _markSynced(val.id!);
    }
  }

  Future<void> deleteSalary(int val) async {
    final existing = await _collection.get(val);
    if (existing == null) return;
    if (_canSync) {
      await _supabase.removeSalary(val);
      await _database.isar.writeTxn(() async => await _collection.delete(val));
      return;
    }
    existing
      ..updatedAt = _now
      ..isDeleted = true
      ..isSynced = false;
    await _database.isar.writeTxn(() async => await _collection.put(existing));
  }

  Future<List<SalaryModel>> getSalary() async {
    return _collection.where().findAll();
  }

  Future<List<SalaryModel>> getSalaryForSync() async {
    return _collection.where().findAll();
  }

  Future<void> salariesSync() async {
    if (!_canSync) return;
    final localSalaries = await getSalaryForSync();
    for (final salary in localSalaries.where((s) => !s.isSynced)) {
      if (salary.isDeleted) {
        await _supabase.removeSalary(salary.id!);
        await _database.isar.writeTxn(() async => await _collection.delete(salary.id!));
        continue;
      }
      final exists = await _supabase.getSalariesById(salary.id!);
      if (exists) {
        await _supabase.updateSalary(salary);
      } else {
        await _supabase.addSalary(salary.toJson());
      }
      await _markSynced(salary.id!);
    }
    final remoteSalaries = await _supabase.getSalarys();
    await _database.isar.writeTxn(() async {
      for (final remote in remoteSalaries) {
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
