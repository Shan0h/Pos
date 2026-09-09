import 'package:isar/isar.dart';
import 'package:pos/model/expenses_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/supabase_service.dart';

class ExpensesService {
  final Database _database;
  ExpensesService(this._database);

  IsarCollection<ExpensesModel> get _collection => _database.isar.expensesModels;
  SupabaseHelper get _supabase => _database.supabaseHelper;
  bool get _canSync => _database.canSync;
  DateTime get _now => _database.now;

  Future<void> _markSynced(int id) async {
    final expense = await _collection.get(id);
    if (expense == null) return;
    expense.isSynced = true;
    await _database.isar.writeTxn(() async => await _collection.put(expense));
  }

  Future<void> addExpenses(ExpensesModel val) async {
    val.updatedAt = _now;
    val.isDeleted = false;
    val.isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.addExpenses(val.toJson());
      await _markSynced(val.id!);
    }
  }

  Future<void> deleteExpenses(int val) async {
    final existing = await _collection.get(val);
    if (existing == null) return;
    if (_canSync) {
      await _supabase.removeExpenses(val);
      await _database.isar.writeTxn(() async => await _collection.delete(val));
      return;
    }
    existing
      ..updatedAt = _now
      ..isDeleted = true
      ..isSynced = false;
    await _database.isar.writeTxn(() async => await _collection.put(existing));
  }

  Future<void> updateExpenses(ExpensesModel val) async {
    val
      ..updatedAt = _now
      ..isDeleted = false
      ..isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.updateExpenses(val);
      await _markSynced(val.id!);
    }
  }

  Future<List<ExpensesModel>> getExpenses({required DateTime start, required DateTime end}) async {
    return _collection
        .where()
        .filter()
        .createdAtBetween(start.copyWith(hour: 0, minute: 0, second: 0),
            end.copyWith(hour: 23, minute: 59, second: 59))
        .and()
        .isDeletedEqualTo(false)
        .findAll();
  }

  Future<List<ExpensesModel>> getExpensesForSync() async {
    return _collection.where().findAll();
  }

  Future<void> clearExpenses() async {
    await _database.isar.writeTxn(() async => await _collection.clear());
  }

  Future<void> expensesSync() async {
    if (!_canSync) return;
    final expenses = await getExpensesForSync();
    for (final expense in expenses.where((e) => !e.isSynced)) {
      if (expense.isDeleted) {
        await _supabase.removeExpenses(expense.id!);
        await _database.isar.writeTxn(() async => await _collection.delete(expense.id!));
        continue;
      }
      final exists = await _supabase.getExpensesById(expense.id!);
      if (exists) {
        await _supabase.updateExpenses(expense);
      } else {
        await _supabase.addExpenses(expense.toJson());
      }
      await _markSynced(expense.id!);
    }
    final remoteExpenses = await _supabase.getExpenses();
    await _database.isar.writeTxn(() async {
      for (final remote in remoteExpenses) {
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
