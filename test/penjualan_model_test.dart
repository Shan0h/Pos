import 'package:flutter_test/flutter_test.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/model/penjualan_model.dart';

void main() {
  test('PenjualanModel round-trips through encoded items string', () {
    final original = PenjualanModel(
      id: 123,
      items: [
        ProductItemModel(
          id: 5,
          nama: 'Espresso Large Less Sugar',
          code: 'ESP-01',
          deskripsi: 'Size: Large',
          jumlahBarang: 10,
          quantity: 2,
          ukuran: 'cup',
          hargaDasar: 4,
          hargaJual: 9,
          isHargaJualPersen: false,
          isSynced: true,
        )..hargaJualExact = 8.5,
      ],
      totalItem: 2,
      totalHarga: 17.0,
      diskon: 0,
      staffId: 1,
      keterangan: 'Modern POS Checkout',
      createdAt: DateTime.parse('2026-09-08T10:00:00.000Z'),
      tenderedAmount: 20.0,
      changeAmount: 2.0,
      paymentMethod: 'cash',
    );

    final restored = PenjualanModel.fromJson(original.toJson());

    expect(restored.id, 123);
    expect(restored.items, hasLength(1));
    expect(restored.items.first.nama, 'Espresso Large Less Sugar');
    expect(restored.items.first.quantity, 2);
    expect(restored.items.first.createdAt, isNull);
    expect(restored.items.first.hargaJualExact, 8.5);
    expect(restored.items.first.price, 8.5);
    expect(restored.totalHarga, 17.0);
    expect(restored.totalItem, 2);
    expect(restored.tenderedAmount, 20.0);
    expect(restored.changeAmount, 2.0);
    expect(restored.paymentMethod, 'cash');
  });

  test('ProductItemModel parses date strings from remote payloads', () {
    final parsed = ProductItemModel.fromJson({
      'id': 7,
      'nama': 'Latte',
      'code': 'LAT-01',
      'quantity': 1,
      'hargaJual': 12,
      'hargaJualPersen': 5,
      'createdAt': '2026-09-08T10:00:00.000Z',
      'barangMasuk': '2026-09-01T08:00:00.000Z',
    });

    expect(parsed.createdAt, DateTime.parse('2026-09-08T10:00:00.000Z'));
    expect(parsed.barangMasuk, DateTime.parse('2026-09-01T08:00:00.000Z'));
    expect(parsed.hargaJualPersen, 5.0);
    expect(parsed.barangKeluar, isNull);
  });

  test('ItemModel price falls back to legacy hargaJual when exact is null',
      () {
    final item = ItemModel(
      nama: 'Americano',
      code: 'AM-01',
      jumlahBarang: 10,
      quantity: 1,
      ukuran: '',
      hargaDasar: 0,
      hargaJual: 8,
      isHargaJualPersen: false,
    )..hargaJualExact = 8.5;

    expect(item.price, 8.5);

    final legacy = ItemModel(
      nama: 'Americano',
      code: 'AM-01',
      jumlahBarang: 10,
      quantity: 1,
      ukuran: '',
      hargaDasar: 0,
      hargaJual: 8,
      isHargaJualPersen: false,
    );

    expect(legacy.price, 8.0);
  });

  test('ItemModel round-trips hargaJualExact through JSON', () {
    final item = ItemModel(
      nama: 'Latte',
      code: 'LT-01',
      jumlahBarang: 10,
      quantity: 1,
      ukuran: '',
      hargaDasar: 0,
      hargaJual: 8,
      hargaJualExact: 8.5,
      isHargaJualPersen: false,
    );

    final restored = ItemModel.fromJson(item.toJson());

    expect(restored.hargaJualExact, 8.5);
    expect(restored.price, 8.5);
  });

  test('ItemModel round-trips menuCategory through JSON', () {
    final item = ItemModel(
      nama: 'Latte',
      code: 'LT-01',
      jumlahBarang: 10,
      quantity: 1,
      ukuran: '',
      hargaDasar: 0,
      hargaJual: 8,
      isHargaJualPersen: false,
      category: 'Menu',
      menuCategory: 'Coffee',
    );

    final restored = ItemModel.fromJson(item.toJson());

    expect(restored.menuCategory, 'Coffee');
    expect(restored.category, 'Menu');

    final copied = item.copy();
    expect(copied.menuCategory, 'Coffee');
  });
}
