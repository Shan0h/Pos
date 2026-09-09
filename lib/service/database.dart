import 'dart:developer';
import 'dart:io';

import 'package:pos/main.dart';
import 'package:pos/model/auth_model.dart';
import 'package:pos/model/customer_model.dart';
import 'package:pos/model/expenses_model.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/model/salary_model.dart';
import 'package:pos/model/store_model.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/service/supabase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class Database {
  late Future<Isar> db;

  Database() {
    db = openDB();
  }

  final SupabaseHelper _supabaseHelper = SupabaseHelper();
  static final SupabaseClient supabase = Supabase.instance.client;

  bool get _canSync =>
      isDeviceConnected.value && supabase.auth.currentUser != null;

  DateTime _now() => DateTime.now();

  // Public accessors for entity services
  SupabaseHelper get supabaseHelper => _supabaseHelper;
  bool get canSync => _canSync;
  DateTime get now => _now();
  Isar get isar {
    Isar? instance = Isar.getInstance();
    if (instance != null) return instance;
    throw StateError('Isar instance not initialized. Ensure Database is fully initialized before accessing isar.');
  }

  // Entity CRUD/sync methods have been moved to entity-specific services.
  // This class now manages only Isar lifecycle, auth-local state, and backup/restore.

  // Auth Local
  Future<void> loginUser(AuthModel val) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.authModels.put(val);
      await val.user.save();
    });
  }

  Future<void> changeUser(AuthModel val) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.authModels.put(val);
      await val.user.save();
    });
  }

  Future<AuthModel?> authUser() async {
    final isar = await db;
    IsarCollection<AuthModel> authCollection = isar.collection<AuthModel>();
    final users = await authCollection.where().findAll();
    if (users.isEmpty) {
      return null;
    }
    return users.first;
  }

  // Backup & Restore
  Future<bool> createBackUp() async {
    try {
      final isar = await db;
      final tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/backup_db.isar');

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await isar.copyToFile(tempFile.path);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName: 'pos_backup_db_${DateTime.now().millisecondsSinceEpoch}.isar',
        type: FileType.any,
      );

      if (outputFile == null) {
        return false;
      }

      if (!outputFile.endsWith('.isar')) {
        outputFile += '.isar';
      }

      await tempFile.copy(outputFile);
      return true;
    } catch (e) {
      log('Backup finished with exception: $e');
      return false;
    }
  }

  Future<bool> restoreDB() async {
    try {
      final dbDirectory = await getApplicationDocumentsDirectory();
      final isar = await db;

      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        await isar.close(deleteFromDisk: true);

        File targetFile = await file.copy("${dbDirectory.path}/default.isar");
        log("Correctly copied to ${targetFile.path}");

        db = Isar.open(
          [
            ItemModelSchema,
            CustomerModelSchema,
            PenjualanModelSchema,
            UserModelSchema,
            AuthModelSchema,
            StoreModelSchema,
            ExpensesModelSchema,
            SalaryModelSchema,
          ],
          directory: dbDirectory.path,
        );
        await db;
        return true;
      }
      return false;
    } catch (e) {
      log('Restore failed: $e');
      return false;
    }
  }

  Future<void> clearAllData() async {
    final isar = await db;
    await isar.writeTxn<void>(() => isar.clear());
    await isar.close(deleteFromDisk: true);
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final isar = await Isar.open(
        [
          ItemModelSchema,
          CustomerModelSchema,
          PenjualanModelSchema,
          UserModelSchema,
          AuthModelSchema,
          StoreModelSchema,
          ExpensesModelSchema,
          SalaryModelSchema,
        ],
        directory: dir.path,
        inspector: true,
      );

      return isar;
    }

    return Future.value(Isar.getInstance());
  }
}
