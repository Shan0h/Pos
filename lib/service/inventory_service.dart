import 'package:isar/isar.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/supabase_service.dart';

class InventoryService {
  final Database _database;
  InventoryService(this._database);

  IsarCollection<ItemModel> get _collection => _database.isar.itemModels;
  SupabaseHelper get _supabase => _database.supabaseHelper;
  bool get _canSync => _database.canSync;
  DateTime get _now => _database.now;

  Future<void> _markSynced(int id) async {
    final item = await _collection.get(id);
    if (item == null) return;
    item.isSynced = true;
    await _database.isar.writeTxn(() async => await _collection.put(item));
  }

  Future<void> addInventory(ItemModel val) async {
    val.updatedAt = _now;
    val.isDeleted = false;
    val.isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.addInventory(val.toJson());
      await _markSynced(val.id!);
    }
  }

  Future<void> deleteInventory(int val) async {
    final existing = await _collection.get(val);
    if (existing == null) return;
    if (_canSync) {
      await _supabase.removeInventory(val);
      await _database.isar.writeTxn(() async => await _collection.delete(val));
      return;
    }
    existing
      ..updatedAt = _now
      ..isDeleted = true
      ..isSynced = false;
    await _database.isar.writeTxn(() async => await _collection.put(existing));
  }

  Future<void> updateInventory(ItemModel val) async {
    val
      ..updatedAt = _now
      ..isDeleted = false
      ..isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.updateInventory(val);
      await _markSynced(val.id!);
    }
  }

  Future<void> decrementStock(int id, int qty) async {
    final master = await _collection.get(id);
    if (master == null) return;
    master
      ..jumlahBarang = master.jumlahBarang - qty
      ..updatedAt = _now
      ..isDeleted = false
      ..isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(master));
    if (_canSync) {
      await _supabase.updateInventory(master);
      await _markSynced(master.id!);
    }
  }

  /// Restores stock that was deducted at checkout — used when a paid,
  /// not-yet-fulfilled order is cancelled from the Awaiting Orders screen
  /// (the goods were never handed over, so they go back on the shelf).
  /// Mirrors [decrementStock] including the Supabase sync write.
  Future<void> incrementStock(int id, int qty) async {
    final master = await _collection.get(id);
    if (master == null) return;
    master
      ..jumlahBarang = master.jumlahBarang + qty
      ..updatedAt = _now
      ..isDeleted = false
      ..isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(master));
    if (_canSync) {
      await _supabase.updateInventory(master);
      await _markSynced(master.id!);
    }
  }

  Future<List<ItemModel>> getInventorys({String? value, String? category}) async {
    var query = _collection.filter().group((q) => q
            .namaContains(value ?? '', caseSensitive: false)
            .or()
            .codeContains(value ?? '', caseSensitive: false))
        .and()
        .isDeletedEqualTo(false);
    if (category != null) {
      return await query.categoryEqualTo(category).findAll();
    }
    return await query.findAll();
  }

  Future<List<ItemModel>> getInventorysForSync() async {
    return _collection.where().findAll();
  }

  Future<void> addAllInventory(List<ItemModel> vals) async {
    for (var val in vals) {
      await addInventory(val);
    }
  }

  Future<List<ItemModel>> getOutStock() async {
    return _collection
        .filter()
        .group((q) => q.jumlahBarangLessThan(1))
        .and()
        .isDeletedEqualTo(false)
        .findAll();
  }

  Future<ItemModel?> searchByBarcode(String value) async {
    return _collection
        .filter()
        .group((q) => q.codeContains(value, caseSensitive: false))
        .findFirst();
  }

  Future<void> clearInventory() async {
    await _database.isar.writeTxn(() async => await _collection.clear());
  }

  Future<List<ItemModel>> searchInventorys({String? value}) async {
    return _collection
        .filter()
        .group((q) => q
            .namaContains(value ?? '', caseSensitive: false)
            .or()
            .codeContains(value ?? '', caseSensitive: false))
        .and()
        .isDeletedEqualTo(false)
        .findAll();
  }

  Future<void> checkIsInventorySynced() async {
    if (!_canSync) return;
    final localItems = await getInventorysForSync();
    for (final item in localItems.where((i) => !i.isSynced)) {
      if (item.isDeleted) {
        await _supabase.removeInventory(item.id!);
        await _database.isar.writeTxn(() async => await _collection.delete(item.id!));
        continue;
      }
      final existing = await _supabase.getInventoryById(item.id!);
      if (existing) {
        await _supabase.updateInventory(item);
      } else {
        await _supabase.addInventory(item.toJson());
      }
      await _markSynced(item.id!);
    }
    final remoteItems = await _supabase.getInventoryAll();
    await _database.isar.writeTxn(() async {
      for (final remote in remoteItems) {
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
