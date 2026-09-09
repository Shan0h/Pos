import 'package:isar/isar.dart';
import 'package:pos/model/customer_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/supabase_service.dart';

class CustomerService {
  final Database _database;
  CustomerService(this._database);

  IsarCollection<CustomerModel> get _collection => _database.isar.customerModels;
  SupabaseHelper get _supabase => _database.supabaseHelper;
  bool get _canSync => _database.canSync;
  DateTime get _now => _database.now;

  Future<void> _markSynced(int id) async {
    final customer = await _collection.get(id);
    if (customer == null) return;
    customer.isSynced = true;
    await _database.isar.writeTxn(() async => await _collection.put(customer));
  }

  Future<void> addNewCustomer(CustomerModel val) async {
    val.updatedAt = _now;
    val.isDeleted = false;
    val.isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.addCustomer(val.toJson());
      await _markSynced(val.id!);
    }
  }

  Future<void> deleteCustomer(int val) async {
    final existing = await _collection.get(val);
    if (existing == null) return;
    if (_canSync) {
      await _supabase.removeCustomer(val);
      await _database.isar.writeTxn(() async => await _collection.delete(val));
      return;
    }
    existing
      ..updatedAt = _now
      ..isDeleted = true
      ..isSynced = false;
    await _database.isar.writeTxn(() async => await _collection.put(existing));
  }

  Future<void> updateCustomer(CustomerModel val) async {
    val
      ..updatedAt = _now
      ..isDeleted = false
      ..isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.updateCustomer(val);
      await _markSynced(val.id!);
    }
  }

  Future<List<CustomerModel>> getCustomers({String? name}) async {
    return _collection
        .filter()
        .namaContains(name ?? '', caseSensitive: false)
        .and()
        .isDeletedEqualTo(false)
        .findAll();
  }

  Future<List<CustomerModel>> getCustomersForSync() async {
    return _collection.where().findAll();
  }

  Future<CustomerModel?> getCustomerById(int id) async {
    return _collection.get(id);
  }

  Future<void> clearCustomer() async {
    await _database.isar.writeTxn(() async => await _collection.clear());
  }

  Future<void> syncCustomers() async {
    if (!_canSync) return;
    final localCustomers = await _collection.where().findAll();
    for (final customer in localCustomers.where((c) => !c.isSynced)) {
      if (customer.isDeleted) {
        await _supabase.removeCustomer(customer.id!);
        await _database.isar.writeTxn(() async => await _collection.delete(customer.id!));
        continue;
      }
      final exists = await _supabase.getCustomerById(customer.id!);
      if (exists) {
        await _supabase.updateCustomer(customer);
      } else {
        await _supabase.addCustomer(customer.toJson());
      }
      await _markSynced(customer.id!);
    }
    final remoteCustomers = await _supabase.getCustomerAll();
    await _database.isar.writeTxn(() async {
      for (final remote in remoteCustomers) {
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
