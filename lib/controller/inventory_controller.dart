import 'dart:io';

import 'package:pos/model/item_model.dart';
import 'package:pos/service/database.dart';
import 'package:signals/signals_flutter.dart';

class InventoryController {
  final searchInventory = signal<String?>(null);
  final inventorys = futureSignal(() async => Database()
      .getInventorys(value: inventoryController.searchInventory.value));
  final deleteItemList = Signal<List<ItemModel>>([]);
  final inventorySelected = signal<ItemModel?>(null);
  final csvFile = signal<File?>(null);
  final selectAll = signal<bool>(false);
  final listItemFromCsv = ListSignal<ItemModel>([]);
}

final inventoryController = InventoryController();
