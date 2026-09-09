import 'package:isar/isar.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/supabase_service.dart';

class UserService {
  final Database _database;
  UserService(this._database);

  IsarCollection<UserModel> get _collection => _database.isar.userModels;
  SupabaseHelper get _supabase => _database.supabaseHelper;
  bool get _canSync => _database.canSync;
  DateTime get _now => _database.now;

  Future<void> _markSynced(int id) async {
    final user = await _collection.get(id);
    if (user == null) return;
    user.isSynced = true;
    await _database.isar.writeTxn(() async => await _collection.put(user));
  }

  Future<void> addNewUser(UserModel val) async {
    val.updatedAt = _now;
    val.isDeleted = false;
    val.isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.addUsers(val.toJson());
      await _markSynced(val.id!);
    }
  }

  Future<void> deleteUser(int val) async {
    final existing = await _collection.get(val);
    if (existing == null) return;
    if (_canSync) {
      await _supabase.removeUsers(val);
      await _database.isar.writeTxn(() async => await _collection.delete(val));
      return;
    }
    existing
      ..isDeleted = true
      ..isSynced = false
      ..updatedAt = _now;
    await _database.isar.writeTxn(() async => await _collection.put(existing));
  }

  Future<void> updateUser(UserModel val) async {
    val
      ..updatedAt = _now
      ..isDeleted = false
      ..isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.updateUsers(val);
      await _markSynced(val.id!);
    }
  }

  Future<List<UserModel>> getUsers({String? name}) async {
    return _collection
        .filter()
        .namaContains(name ?? '', caseSensitive: false)
        .and()
        .isDeletedEqualTo(false)
        .findAll();
  }

  Future<UserModel?> getUserById(int id) async {
    return _collection.get(id);
  }

  Future<void> clearUser() async {
    await _database.isar.writeTxn(() async => await _collection.clear());
  }

  Future<void> syncUsers() async {
    if (!_canSync) return;
    final localUsers = await _collection.where().findAll();
    for (final user in localUsers.where((u) => !u.isSynced)) {
      if (user.isDeleted) {
        await _supabase.removeUsers(user.id!);
        await _database.isar.writeTxn(() async => await _collection.delete(user.id!));
        continue;
      }
      final exists = await _supabase.getUserById(user.id!);
      if (exists) {
        await _supabase.updateUsers(user);
      } else {
        await _supabase.addUsers(user.toJson());
      }
      await _markSynced(user.id!);
    }
    final remoteUsers = await _supabase.getUsers();
    await _database.isar.writeTxn(() async {
      for (final remote in remoteUsers) {
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
