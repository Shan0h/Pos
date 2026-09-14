import 'package:isar/isar.dart';
import 'package:pos/model/auth_model.dart';
import 'package:pos/model/customer_model.dart';
import 'package:pos/model/expenses_model.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/model/salary_model.dart';
import 'package:pos/model/store_model.dart';
import 'package:pos/model/user_model.dart';

/// Pure (no-Flutter, no-file-picker) JSON backup codec for the local Isar DB.
///
/// The backup is a versioned JSON envelope:
/// ```json
/// {
///   "app": "pos",
///   "formatVersion": 1,
///   "createdAt": "2026-01-01T10:00:00.000",
///   "data": {
///     "items":     [ ...ItemModel.toJson... ],
///     "customers": [ ... ],
///     "users":     [ ... ],
///     "auths":     [ {"id": 1, "createdAt": "...", "userId": 5} ],
///     "store":     [ ... ],
///     "sales":     [ {...PenjualanModel.toJson..., "orderStatus": "pending"} ],
///     "expenses":  [ ... ],
///     "salaries":  [ ... ]
///   }
/// }
/// ```
///
/// Why JSON instead of copying the raw .isar file: the JSON roundtrip goes
/// through the app's own toJson/fromJson for every model, so it works across
/// app versions (missing fields fall back to defaults), across platforms, and
/// survives the file being re-compressed/renamed by chat apps. The raw file
/// swap fails hard on any schema mismatch (Isar embeds its schema in the
/// file) and cannot be validated before it destroys the local DB.
class BackupCodec {
  BackupCodec._();

  /// Bump when the envelope shape changes. Importers must accept
  /// [formatVersion] and any older version.
  static const int formatVersion = 1;

  static const String appTag = 'pos';

  /// Human-readable name for the top-level keys, used in error messages.
  static const Map<String, String> _dataKeyLabels = {
    'items': 'menu / inventory items',
    'customers': 'customers',
    'users': 'staff profiles',
    'auths': 'active login session',
    'store': 'store settings',
    'sales': 'sales records',
    'expenses': 'expenses',
    'salaries': 'salaries',
  };

  // ---------------------------------------------------------------------------
  // EXPORT
  // ---------------------------------------------------------------------------

  /// Builds the backup envelope from the given open Isar instance.
  ///
  /// Never mutates the database — safe to run while the app is in use.
  static Future<Map<String, dynamic>> serialize(Isar isar) async {
    final sales = <Map<String, dynamic>>[];
    for (final sale in await isar.penjualanModels.where().findAll()) {
      // PenjualanModel.toJson() deliberately omits `orderStatus` so the
      // Supabase payload stays unchanged — the backup envelope is local-only,
      // so it is added here explicitly and restored below.
      sales.add(<String, dynamic>{
        ...sale.toJson(),
        'orderStatus': sale.orderStatus,
      });
    }

    final auths = <Map<String, dynamic>>[];
    for (final auth in await isar.authModels.where().findAll()) {
      await auth.user.load();
      auths.add(<String, dynamic>{
        'id': auth.id,
        'createdAt': auth.createdAt.toIso8601String(),
        'userId': auth.user.value?.id,
      });
    }

    return <String, dynamic>{
      'app': appTag,
      'formatVersion': formatVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'data': <String, dynamic>{
        'items': (await isar.itemModels.where().findAll())
            .map((e) => e.toJson())
            .toList(),
        'customers': (await isar.customerModels.where().findAll())
            .map((e) => e.toJson())
            .toList(),
        'users': (await isar.userModels.where().findAll())
            .map((e) => e.toJson())
            .toList(),
        'auths': auths,
        'store': (await isar.storeModels.where().findAll())
            .map((e) => e.toJson())
            .toList(),
        'sales': sales,
        'expenses': (await isar.expensesModels.where().findAll())
            .map((e) => e.toJson())
            .toList(),
        'salaries': (await isar.salaryModels.where().findAll())
            .map((e) => e.toJson())
            .toList(),
      },
    };
  }

  // ---------------------------------------------------------------------------
  // IMPORT
  // ---------------------------------------------------------------------------

  /// Decodes + validates the whole backup BEFORE anything touches the
  /// database. Throws [BackupFormatException] with a user-presentable
  /// message on any problem; on success returns a fully-parsed
  /// [ParsedBackup] that [apply] can write in one atomic transaction.
  static ParsedBackup parse(Map<String, dynamic>? decoded) {
    if (decoded == null) {
      throw const BackupFormatException(
          'The selected file is empty or not a valid backup file.');
    }

    final app = decoded['app'];
    if (app is! String || app != appTag) {
      throw const BackupFormatException(
          'This file is not a POS backup file. Please pick a file exported by the Backup feature.');
    }

    final version = decoded['formatVersion'];
    if (version is! int) {
      throw const BackupFormatException(
          'Backup file is corrupted (missing version).');
    }
    if (version > formatVersion) {
      throw BackupFormatException(
          'This backup was created by a newer version of the app (format v$version, '
          'this app supports v$formatVersion). Please update the app first.');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const BackupFormatException(
          'Backup file is corrupted (missing data section).');
    }

    for (final key in _dataKeyLabels.keys) {
      if (data[key] is! List) {
        throw BackupFormatException(
            'Backup file is corrupted (missing "${_dataKeyLabels[key]}" section).');
      }
    }

    try {
      final items = _mapRows<ItemModel>(
        data['items'] as List,
        'menu / inventory item',
        ItemModel.fromJson,
      );
      final customers = _mapRows<CustomerModel>(
        data['customers'] as List,
        'customer',
        CustomerModel.fromJson,
      );
      final users = _mapRows<UserModel>(
        data['users'] as List,
        'staff profile',
        UserModel.fromJson,
      );
      final store = _mapRows<StoreModel>(
        data['store'] as List,
        'store setting',
        StoreModel.fromJson,
      );
      final expenses = _mapRows<ExpensesModel>(
        data['expenses'] as List,
        'expense',
        ExpensesModel.fromJson,
      );
      final salaries = _mapRows<SalaryModel>(
        data['salaries'] as List,
        'salary',
        SalaryModel.fromJson,
      );

      final sales = <PenjualanModel>[];
      final saleRows = data['sales'] as List;
      for (var i = 0; i < saleRows.length; i++) {
        final row = _rowMap(saleRows[i], 'sales record', i);
        try {
          final sale = PenjualanModel.fromJson(row);
          // `orderStatus` is intentionally absent from PenjualanModel.fromJson
          // (Supabase payload compatibility) — restore it from the envelope.
          sale.orderStatus = row['orderStatus'] as String?;
          sales.add(sale);
        } catch (e) {
          throw BackupFormatException(
              'Backup file is corrupted: sales record #${i + 1} could not be '
              'read (${e.runtimeType}). The file may be damaged or from a '
              'different app version.');
        }
      }

      final auths = <ParsedAuth>[];
      final authRows = data['auths'] as List;
      for (var i = 0; i < authRows.length; i++) {
        final row = _rowMap(authRows[i], 'login session', i);
        final userId = row['userId'];
        auths.add(ParsedAuth(
          id: row['id'] as int,
          createdAt: row['createdAt'] != null
              ? DateTime.parse(row['createdAt'] as String)
              : DateTime.now(),
          userId: userId is int ? userId : null,
        ));
      }

      return ParsedBackup(
        items: items,
        customers: customers,
        users: users,
        auths: auths,
        store: store,
        sales: sales,
        expenses: expenses,
        salaries: salaries,
        createdAt: decoded['createdAt'] is String
            ? DateTime.tryParse(decoded['createdAt'] as String)
            : null,
      );
    } on BackupFormatException {
      rethrow;
    } catch (e) {
      throw BackupFormatException(
          'Backup file could not be read — it may be damaged or from an incompatible version. (${e.runtimeType})');
    }
  }

  static List<T> _mapRows<T>(
    List rows,
    String label,
    T Function(Map<String, dynamic>) factory,
  ) {
    final result = <T>[];
    for (var i = 0; i < rows.length; i++) {
      final row = _rowMap(rows[i], label, i);
      try {
        result.add(factory(row));
      } on BackupFormatException {
        rethrow;
      } catch (e) {
        throw BackupFormatException(
            'Backup file is corrupted: ${_cap(label)} #${i + 1} could not be '
            'read (${e.runtimeType}). The file may be damaged or from a '
            'different app version.');
      }
    }
    return result;
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static Map<String, dynamic> _rowMap(Object? row, String label, int index) {
    if (row is! Map<String, dynamic>) {
      throw BackupFormatException(
          'Backup file is corrupted: $label #${index + 1} is invalid.');
    }
    return row;
  }

  /// Writes a parsed backup into [isar] in ONE atomic transaction:
  /// clears every collection, then re-inserts all rows with their original
  /// IDs (Isar's auto-increment counter follows the highest inserted ID, so
  /// new records after the restore continue from there), then re-links
  /// AuthModel -> UserModel.
  ///
  /// Because [parse] fully validated the payload first, this cannot fail
  /// halfway and leave the DB empty.
  static Future<void> apply(Isar isar, ParsedBackup backup) async {
    await isar.writeTxn(() async {
      await isar.clear();

      await isar.itemModels.putAll(backup.items);
      await isar.customerModels.putAll(backup.customers);
      await isar.userModels.putAll(backup.users);
      await isar.storeModels.putAll(backup.store);
      await isar.penjualanModels.putAll(backup.sales);
      await isar.expensesModels.putAll(backup.expenses);
      await isar.salaryModels.putAll(backup.salaries);

      for (final parsedAuth in backup.auths) {
        final auth = AuthModel()
          ..id = parsedAuth.id
          ..createdAt = parsedAuth.createdAt;
        await isar.authModels.put(auth);

        // Re-link the IsarLink<UserModel> — links live outside the row
        // itself, so the exported userId must be wired back manually.
        final user = backup.users
            .cast<UserModel?>()
            .firstWhere((u) => u?.id == parsedAuth.userId, orElse: () => null);
        if (user != null) {
          auth.user.value = user;
          await auth.user.save();
        }
      }
    });
  }
}

class ParsedAuth {
  final int id;
  final DateTime createdAt;
  final int? userId;

  const ParsedAuth({
    required this.id,
    required this.createdAt,
    this.userId,
  });
}

class ParsedBackup {
  final List<ItemModel> items;
  final List<CustomerModel> customers;
  final List<UserModel> users;
  final List<ParsedAuth> auths;
  final List<StoreModel> store;
  final List<PenjualanModel> sales;
  final List<ExpensesModel> expenses;
  final List<SalaryModel> salaries;
  final DateTime? createdAt;

  const ParsedBackup({
    required this.items,
    required this.customers,
    required this.users,
    required this.auths,
    required this.store,
    required this.sales,
    required this.expenses,
    required this.salaries,
    this.createdAt,
  });

  /// Human-readable per-collection counts, e.g. "24 menu items, 3 staff".
  String get summary {
    final parts = <String>[
      '${items.length} menu items',
      '${sales.length} sales',
      '${customers.length} customers',
      '${users.length} staff',
      '${expenses.length} expenses',
      '${salaries.length} salaries',
      '${store.length} store settings',
    ];
    return parts.join(', ');
  }
}

/// Carries a user-presentable reason why a backup file was rejected.
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => message;
}
