import 'package:pos/controller/inventory_controller.dart';
import 'package:pos/controller/selling/events.dart';
import 'package:pos/controller/selling/service.dart';
import 'package:pos/enum/payment_enum.dart';
import 'package:pos/model/card_model.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/model/customer_model.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/service/app_services.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class SellingController {
  SellingController(this._cartService);
  final CartService _cartService;
  final isSearch = Signal(false);
  final tipeBayar = Signal(TypePayment.qris);
  final pelanggan = Signal<CustomerModel?>(null);
  final staffId = Signal<UserModel?>(null);
  final selectedPrint = Signal<String>("Xprinter XP-T371U");

  late final _cart = signal<AsyncState<Cart>>(const AsyncLoading());
  ReadonlySignal<AsyncState<Cart>> get cart => _cart;

  Future<void> dispatch(CartEvent event) async {
    switch (event) {
      case CartStarted():
        _cart.value = const AsyncLoading();
        _cartService
            .loadProducts()
            .then((items) => _cart.value = AsyncData(Cart(items: [...items])))
            // ignore: invalid_return_type_for_catch_error
            .catchError((e, s) => _cart.set(AsyncError(e, s)));

      case CartItemAdded(:final item):
        if (_cart.value case AsyncData<Cart>()) {
          try {
            _cartService.add(item);
            _cart.value = AsyncData(Cart(items: _cartService.items));
          } catch (e, s) {
            _cart.value = AsyncError(e, s);
          }
        }

      case CartItemRemoved(:final item):
        if (_cart.value case AsyncData<Cart>()) {
          try {
            _cartService.remove(item);
            _cart.value = AsyncData(Cart(items: _cartService.items));
          } catch (e, s) {
            _cart.value = AsyncError(e, s);
          }
        }

      case CartItemDecremented(:final item):
        if (_cart.value case AsyncData<Cart>()) {
          try {
            _cartService.decrement(item);
            _cart.value = AsyncData(Cart(items: _cartService.items));
          } catch (e, s) {
            _cart.value = AsyncError(e, s);
          }
        }

      case CartPaid():
        _cartService.clear();
        _cart.value = const AsyncData(Cart());
    }
  }

  Future<void> updateBatch(List<ItemModel> items) async {
    await Future.forEach<ItemModel>(items, (i) async {
      await inventoryService.decrementStock(i.id!, i.quantity);
    });
    Future.delayed(Durations.short1).then((_) {
      inventoryController.inventorys.refresh();
      inventoryController.menuItems.refresh();
    });
  }
}
