import 'package:collection/collection.dart';

import 'package:pos/model/item_model.dart';

class CartService {
  final _items = <ItemModel>[];

  List<ItemModel> get items => _items.map((i) => i.copy()).toList();

  Future<List<ItemModel>> loadProducts() =>
      Future.delayed(const Duration(milliseconds: 100) * 10, () => _items);

  bool _sameLine(ItemModel a, ItemModel b) =>
      a.id == b.id && a.nama == b.nama && a.hargaJual == b.hargaJual;

  void add(ItemModel item) {
    final existing = _items.firstWhereOrNull((val) => _sameLine(val, item));
    if (existing != null) {
      existing.quantity = existing.quantity + 1;
    } else {
      _items.add(item);
    }
  }

  void decrement(ItemModel item) {
    final existing = _items.firstWhereOrNull((val) => _sameLine(val, item));
    if (existing == null) return;
    if (existing.quantity > 1) {
      existing.quantity = existing.quantity - 1;
    } else {
      _items.remove(existing);
    }
  }

  void remove(ItemModel item) {
    final existing = _items.firstWhereOrNull((val) => _sameLine(val, item));
    if (existing != null) _items.remove(existing);
  }

  void clear() => _items.clear();
}
