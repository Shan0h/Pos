import 'package:isar/isar.dart';
import 'package:pos/model/store_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/supabase_service.dart';

class StoreService {
  final Database _database;
  StoreService(this._database);

  IsarCollection<StoreModel> get _collection => _database.isar.storeModels;
  SupabaseHelper get _supabase => _database.supabaseHelper;
  bool get _canSync => _database.canSync;

  Future<void> addStore(StoreModel val) async {
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.updateStore(val);
    }
  }

  Future<StoreModel?> getStore() async {
    return _collection.where().findFirst();
  }

  Future<void> syncStore() async {
    if (!_canSync) return;
    final store = await getStore();
    if (store != null) {
      await _supabase.updateStore(store);
    } else {
      final res = await _supabase.getStore();
      if (res != null) {
        await addStore(res);
      }
    }
  }
}
