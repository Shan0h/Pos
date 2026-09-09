import 'package:flutter_test/flutter_test.dart';
import 'package:pos/model/customer_model.dart';
import 'package:pos/model/expenses_model.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/model/user_model.dart';

void main() {
  test('UserModel serializes sync metadata', () {
    final user = UserModel(
      id: 99,
      nama: 'Alya',
      status: true,
      createdAt: DateTime.parse('2026-09-07T08:00:00Z'),
      updatedAt: DateTime.parse('2026-09-07T08:05:00Z'),
      isDeleted: false,
      isSynced: false,
    );

    final json = user.toJson();
    expect(json['updatedAt'], '2026-09-07T08:05:00.000Z');
    expect(json['isDeleted'], isFalse);
    expect(json['isSynced'], isFalse);
  });

  test('CustomerModel restores sync metadata defaults', () {
    final customer = CustomerModel.fromJson({
      'id': 7,
      'nama': 'Nadia',
      'status': true,
      'createdAt': '2026-09-07T08:00:00.000Z',
    });

    expect(customer.isDeleted, isFalse);
    expect(customer.isSynced, isTrue);
  });

  test('ItemModel preserves delete and sync flags', () {
    final item = ItemModel(
      id: 4,
      nama: 'Espresso Beans',
      code: 'ESP-01',
      jumlahBarang: 10,
      quantity: 1,
      ukuran: 'kg',
      hargaDasar: 40,
      hargaJual: 0,
      isHargaJualPersen: false,
      updatedAt: DateTime.parse('2026-09-07T08:15:00Z'),
      isDeleted: true,
      isSynced: false,
    );

    final json = item.toJson();
    expect(json['isDeleted'], isTrue);
    expect(json['isSynced'], isFalse);
    expect(json['updatedAt'], '2026-09-07T08:15:00.000Z');
  });

  test('ExpensesModel restores explicit sync metadata', () {
    final expense = ExpensesModel.fromJson({
      'id': 12,
      'title': 'Milk delivery',
      'amount': 120,
      'createdAt': '2026-09-07T08:00:00.000Z',
      'updatedAt': '2026-09-07T08:20:00.000Z',
      'isDeleted': true,
      'isSynced': false,
    });

    expect(expense.updatedAt, DateTime.parse('2026-09-07T08:20:00.000Z'));
    expect(expense.isDeleted, isTrue);
    expect(expense.isSynced, isFalse);
  });
}
