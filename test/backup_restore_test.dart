import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:pos/model/auth_model.dart';
import 'package:pos/model/customer_model.dart';
import 'package:pos/model/expenses_model.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/model/salary_model.dart';
import 'package:pos/model/store_model.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/service/backup_codec.dart';
import 'package:pos/service/database.dart';

import 'test_isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Isar isar;

  setUpAll(() async {
    await TestIsar.initializeCore();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pos_backup_test');
    isar = await Isar.open(
      Database.schemas,
      directory: tempDir.path,
      inspector: false,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await tempDir.delete(recursive: true);
  });

  ItemModel sampleItem({String code = 'SKU1'}) => ItemModel(
        id: null,
        nama: 'Latte',
        code: code,
        jumlahBarang: 10,
        quantity: 10,
        ukuran: 'M',
        hargaDasar: 800,
        hargaJual: 1200,
        hargaJualExact: 12.50,
        isHargaJualPersen: false,
        createdAt: DateTime(2026, 1, 2, 9, 30),
        menuCategory: 'Coffee',
        customizationsJson: '{"Size":["S","M"]}',
      );

  UserModel sampleUser({String nama = 'Aisyah', String? pin}) => UserModel(
        id: null,
        nama: nama,
        status: true,
        createdAt: DateTime(2026, 1, 1),
        pin: pin,
      );

  PenjualanModel sampleSale({required int staffId, String? orderStatus}) =>
      PenjualanModel(
        id: null,
        items: [
          ProductItemModel(
            id: 1,
            nama: 'Latte',
            code: 'SKU1',
            jumlahBarang: 10,
            quantity: 2,
            ukuran: 'M',
            hargaDasar: 800,
            hargaJual: 1200,
            isHargaJualPersen: false,
            isSynced: true,
            createdAt: DateTime(2026, 1, 2, 9, 30),
            barangMasuk: DateTime(2026, 1, 1),
            category: 'Menu',
          )..hargaJualExact = 12.50,
        ],
        totalItem: 2,
        totalHarga: 25.00,
        diskon: 0,
        staffId: staffId,
        createdAt: DateTime(2026, 1, 2, 10, 0),
        paymentMethod: 'cash',
        tenderedAmount: 30,
        changeAmount: 5,
      )..orderStatus = orderStatus;

  group('BackupCodec.serialize', () {
    test('envelope contains all collections + app/format tags', () async {
      final envelope = await BackupCodec.serialize(isar);

      expect(envelope['app'], 'pos');
      expect(envelope['formatVersion'], BackupCodec.formatVersion);
      expect(envelope['createdAt'], isA<String>());

      final data = envelope['data'] as Map<String, dynamic>;
      for (final key in [
        'items',
        'customers',
        'users',
        'auths',
        'store',
        'sales',
        'expenses',
        'salaries',
      ]) {
        expect(data[key], isA<List>());
      }
    });

    test('sales include orderStatus even though toJson omits it', () async {
      await isar.writeTxn(() async {
        await isar.penjualanModels.put(sampleSale(staffId: 1));
        // keep a handle to check below
      });
      final saved = await isar.penjualanModels.where().findFirst();

      final envelope = await BackupCodec.serialize(isar);
      final sales = (envelope['data'] as Map)['sales'] as List;
      final row = sales.single as Map<String, dynamic>;

      expect(row['orderStatus'], saved!.orderStatus);
      expect(row.containsKey('orderStatus'), isTrue);
    });

    test('product item dates serialize as ISO strings (jsonEncode-safe)',
        () async {
      await isar.writeTxn(() async {
        await isar.penjualanModels.put(sampleSale(staffId: 1));
      });

      final envelope = await BackupCodec.serialize(isar);
      // Must not throw — DateTime objects inside ProductItemModel.toJson
      // previously made jsonEncode fail.
      final json = jsonEncode(envelope);
      expect(json, isA<String>());

      final items =
          ((envelope['data'] as Map)['sales'] as List).first as Map;
      final product = (jsonDecode(items['items'] as String)
          as List).first as Map<String, dynamic>;
      expect(product['barangMasuk'], isA<String>());
    });
  });

  group('BackupCodec roundtrip', () {
    test('full export -> wipe -> import restores every collection', () async {
      // ---- Seed ----
      late int userId;
      await isar.writeTxn(() async {
        final user = sampleUser(pin: '1234');
        userId = await isar.userModels.put(user);

        final item = sampleItem();
        await isar.itemModels.put(item);

        await isar.customerModels.put(CustomerModel(
          id: null,
          nama: 'Walk-in',
          status: false,
          dob: DateTime(1990, 5, 5),
        ));

        await isar.storeModels.put(StoreModel(
          id: null,
          title: 'Kopi Tiam',
          description: 'Cafe POS',
          phone: '0123456789',
          ownerPin: '9999',
        ));

        await isar.penjualanModels
            .put(sampleSale(staffId: userId, orderStatus: 'pending'));

        await isar.expensesModels.put(ExpensesModel(
          id: null,
          title: 'Milk restock',
          amount: 15000,
          createdAt: DateTime(2026, 1, 3),
        ));

        await isar.salaryModels.put(SalaryModel(
          id: null,
          userId: userId,
          status: 'paid',
          periode: '2026-01',
          items: [ItemSalary(id: 1, description: 'Base', amount: '1800')],
          deductions: [ItemSalary(id: 2, description: 'EPF', amount: '180')],
          total: 1620,
          createdAt: DateTime(2026, 1, 31),
        ));

        // AuthModel with a live IsarLink to the user.
        final auth = AuthModel()..createdAt = DateTime(2026, 1, 1, 8);
        await isar.authModels.put(auth);
        auth.user.value = await isar.userModels.get(userId);
        await auth.user.save();
      });

      // ---- Export ----
      final envelope = await BackupCodec.serialize(isar);
      final jsonText = const JsonEncoder.withIndent('  ').convert(envelope);

      // ---- Simulate a second device: wipe everything ----
      await isar.writeTxn(() async => isar.clear());

      // ---- Parse + apply (what restore does) ----
      final backup = BackupCodec.parse(jsonDecode(jsonText) as Map<String, dynamic>);
      await BackupCodec.apply(isar, backup);

      // ---- Assert ----
      final items = await isar.itemModels.where().findAll();
      expect(items, hasLength(1));
      expect(items.single.nama, 'Latte');
      expect(items.single.hargaJualExact, 12.50);
      expect(items.single.menuCategory, 'Coffee');
      expect(items.single.createdAt, DateTime(2026, 1, 2, 9, 30));

      final users = await isar.userModels.where().findAll();
      expect(users, hasLength(1));
      expect(users.single.id, userId);
      expect(users.single.pin, '1234');

      final auths = await isar.authModels.where().findAll();
      expect(auths, hasLength(1));
      await auths.single.user.load();
      expect(auths.single.user.value?.id, userId,
          reason: 'AuthModel -> UserModel link must be re-linked on restore');

      final sales = await isar.penjualanModels.where().findAll();
      expect(sales, hasLength(1));
      expect(sales.single.orderStatus, 'pending');
      expect(sales.single.paymentMethod, 'cash');
      expect(sales.single.tenderedAmount, 30);
      expect(sales.single.changeAmount, 5);
      expect(sales.single.items.single.price, 12.50);

      final customers = await isar.customerModels.where().findAll();
      expect(customers, hasLength(1));
      expect(customers.single.dob, DateTime(1990, 5, 5));

      final store = await isar.storeModels.where().findAll();
      expect(store.single.ownerPin, '9999');

      final expenses = await isar.expensesModels.where().findAll();
      expect(expenses.single.amount, 15000);

      final salaries = await isar.salaryModels.where().findAll();
      expect(salaries.single.items.single.description, 'Base');
      expect(salaries.single.deductions!.single.amount, '180');
      expect(salaries.single.total, 1620);
    });

    test('auto-increment continues after restore (max id respected)',
        () async {
      await isar.writeTxn(() async {
        await isar.itemModels.put(sampleItem());
      });
      final original = await isar.itemModels.where().findFirst();
      final originalId = original!.id!;

      final envelope = await BackupCodec.serialize(isar);
      await isar.writeTxn(() async => isar.clear());
      final backup =
          BackupCodec.parse(jsonDecode(jsonEncode(envelope)) as Map<String, dynamic>);
      await BackupCodec.apply(isar, backup);

      await isar.writeTxn(() async {
        await isar.itemModels.put(sampleItem(code: 'SKU2'));
      });
      final all = await isar.itemModels.where().findAll();
      expect(all, hasLength(2));
      expect(all.map((e) => e.id), contains(originalId));
      final restored = all.firstWhere((e) => e.id == originalId);
      final fresh = all.firstWhere((e) => e.code == 'SKU2');
      expect(fresh.id! > restored.id!, isTrue,
          reason: 'new row must get a higher id than the restored max');
    });
  });

  group('BackupCodec.parse validation', () {
    Map<String, dynamic> validEnvelope() => <String, dynamic>{
          'app': 'pos',
          'formatVersion': BackupCodec.formatVersion,
          'createdAt': DateTime.now().toIso8601String(),
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[],
            'customers': <Map<String, dynamic>>[],
            'users': <Map<String, dynamic>>[],
            'auths': <Map<String, dynamic>>[],
            'store': <Map<String, dynamic>>[],
            'sales': <Map<String, dynamic>>[],
            'expenses': <Map<String, dynamic>>[],
            'salaries': <Map<String, dynamic>>[],
          },
        };

    test('rejects non-POS files with a friendly message', () {
      expect(
        () => BackupCodec.parse({'hello': 'world'}),
        throwsA(isA<BackupFormatException>().having(
          (e) => e.message,
          'message',
          contains('not a POS backup file'),
        )),
      );
    });

    test('rejects newer format versions', () {
      final envelope = validEnvelope();
      envelope['formatVersion'] = BackupCodec.formatVersion + 1;
      expect(
        () => BackupCodec.parse(envelope),
        throwsA(isA<BackupFormatException>().having(
          (e) => e.message,
          'message',
          contains('newer version'),
        )),
      );
    });

    test('rejects missing data sections', () {
      final envelope = validEnvelope();
      (envelope['data'] as Map<String, dynamic>).remove('salaries');
      expect(
        () => BackupCodec.parse(envelope),
        throwsA(isA<BackupFormatException>().having(
          (e) => e.message,
          'message',
          contains('salaries'),
        )),
      );
    });

    test('rejects corrupted rows with the row index in the message', () {
      final envelope = validEnvelope();
      (envelope['data'] as Map<String, dynamic>)['items'] = <Object>[
        {
          // Fully-valid row — proves indexing reaches row #2.
          'id': 1,
          'nama': 'Latte',
          'code': 'SKU1',
          'jumlahBarang': 10,
          'quantity': 10,
          'ukuran': 'M',
          'hargaDasar': 800,
          'hargaJual': 1200,
          'isHargaJualPersen': false,
        },
        'not-a-map',
      ];
      expect(
        () => BackupCodec.parse(envelope),
        throwsA(isA<BackupFormatException>().having(
          (e) => e.message,
          'message',
          contains('#2'),
        )),
      );
    });

    test('rejects rows with missing required fields', () {
      // fromJson factories throw on missing required fields — that must be
      // wrapped into BackupFormatException, not a raw crash.
      final envelope = validEnvelope();
      (envelope['data'] as Map<String, dynamic>)['items'] = [
        {'nama': 'No code field'},
      ];
      expect(
        () => BackupCodec.parse(envelope),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}
