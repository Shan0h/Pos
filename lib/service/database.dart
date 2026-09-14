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

  /// The full schema list — shared by every Isar.open() call so the app can
  /// never open the DB with a different schema set than the one used to
  /// create it (a mismatch makes backups from other devices unopenable).
  static const List<CollectionSchema<dynamic>> schemas = [
    ItemModelSchema,
    CustomerModelSchema,
    PenjualanModelSchema,
    UserModelSchema,
    AuthModelSchema,
    StoreModelSchema,
    ExpensesModelSchema,
    SalaryModelSchema,
  ];

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
  //
  // Android/iOS note: FilePicker.saveFile() uses SAF (ACTION_CREATE_DOCUMENT)
  // and the PLUGIN writes the `bytes` content to the chosen location itself.
  // The returned path may be a virtual SAF URI (e.g. /document/primary:...)
  // that dart:io cannot open — never rewrite the file there with File.copy().
  // The PDF export (pdf_receipt_generator.dart) follows the same pattern.
  Future<bool> createBackUp() async {
    File? tempFile;
    try {
      final isar = await db;
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/backup_db.isar');

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await isar.copyToFile(tempFile.path);

      // The DB file must be handed to the plugin as bytes on mobile (it
      // writes them via SAF); POS databases are MB-scale, so a full
      // in-memory read is acceptable.
      final dbBytes = await tempFile.readAsBytes();

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName: 'pos_backup_db_${DateTime.now().millisecondsSinceEpoch}.isar',
        type: FileType.any,
        bytes: dbBytes,
        lockParentWindow: true,
      );

      if (outputFile == null) {
        // User cancelled the dialog — not an error.
        return false;
      }

      if (!Platform.isAndroid && !Platform.isIOS) {
        // Desktop: the plugin only returns a path. It writes bytes when
        // provided, but verify and fall back to a plain copy for safety.
        final target = File(outputFile);
        if (!await target.exists() || await target.length() == 0) {
          await tempFile.copy(outputFile);
        }
      }

      return true;
    } catch (e) {
      // Surface the real error to the caller (UI shows a failure message)
      // instead of failing silently — a swallowed error here looked like
      // "nothing happened" on the device.
      log('Backup failed with exception: $e');
      throw Exception('Backup failed: $e');
    } finally {
      // Clean up the temp snapshot in all cases.
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  Future<bool> restoreDB() async {
    File? pickedFile;
    try {
      final dbDirectory = await getApplicationDocumentsDirectory();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select legacy Isar backup file (.isar)',
        type: FileType.any,
        lockParentWindow: true,
      );
      if (result == null || result.files.single.path == null) {
        // User cancelled the file picker — not an error.
        return false;
      }
      pickedFile = File(result.files.single.path!);

      // VALIDATE BEFORE DESTROYING ANYTHING: copy the picked file into our
      // documents dir under a temporary probe name and open it with the
      // app's own schema list. If it is corrupt, or was written with a
      // different app version (Isar embeds its schema in the file and
      // throws SchemaMismatchError), we fail here with a clear error while
      // the live database is still untouched.
      final probeName = 'restore_probe_${DateTime.now().millisecondsSinceEpoch}';
      final probeFile = File('${dbDirectory.path}/$probeName.isar');
      Isar? probe;
      try {
        await pickedFile.copy(probeFile.path);
        probe = await Isar.open(
          schemas,
          directory: dbDirectory.path,
          name: probeName,
          inspector: false,
        );
        // Force actual file access (open is lazy about reading data pages).
        await probe.itemModels.count();
        await probe.penjualanModels.count();
      } catch (probeError) {
        throw Exception(
          'This file cannot be used as a database backup — it is corrupt or '
          'was created by an incompatible app version. ($probeError)',
        );
      } finally {
        // The probe instance must be closed+deleted in both paths; its files
        // live under our app dir but are NOT the live database.
        try {
          await probe?.close(deleteFromDisk: true);
        } catch (_) {}
        try {
          if (await probeFile.exists()) await probeFile.delete();
        } catch (_) {}
      }

      // Validation passed — now perform the actual swap. Only after this
      // point is the live DB touched.
      final isar = await db;
      await isar.close(deleteFromDisk: true);

      File targetFile = await pickedFile.copy("${dbDirectory.path}/default.isar");
      log("Correctly copied to ${targetFile.path}");

      db = Isar.open(
        schemas,
        directory: dbDirectory.path,
      );
      await db;
      return true;
    } catch (e) {
      log('Restore failed: $e');
      // Best-effort recovery: if the swap itself exploded, make sure the app
      // is left with a working database instead of a closed instance. With
      // validate-before-swap above, this path is nearly unreachable — it
      // only runs when the copy/open after validation failed.
      try {
        final isar = await db;
        final isOpen = !Isar.instanceNames.isEmpty;
        if (!isOpen) {
          db = openDB();
          await db;
        } else {
          // Instance still alive — nothing was destroyed, just re-throw path.
          // Touch the instance so a broken state surfaces immediately.
          await isar.itemModels.count();
        }
      } catch (recoveryError) {
        log('Restore recovery: reopening fresh DB ($recoveryError)');
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final leftover = File('${docsDir.path}/default.isar');
          if (await leftover.exists()) await leftover.delete();
          db = openDB();
          await db;
        } catch (fatalError) {
          log('Restore recovery also failed: $fatalError');
        }
      }
      // Surface the real error to the caller (UI shows a failure message)
      // instead of failing silently — a swallowed error here looked like
      // "nothing happened" on the device.
      throw Exception('Restore failed: $e');
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
        schemas,
        directory: dir.path,
        inspector: true,
      );

      return isar;
    }

    return Future.value(Isar.getInstance());
  }
}
