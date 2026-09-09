import 'package:flutter/material.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/controller/inventory_controller.dart';
import 'package:pos/pages/pos_modern/menu_item_editor_dialog.dart';
import 'package:pos/utils/extension.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  bool _isLoading = true;
  List<ItemModel> _items = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await inventoryService.getInventorys(category: 'Menu');
    inventoryController.menuItems.reload(); // Trigger refresh for POS page
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _toggleStock(ItemModel item) async {
    final newQuantity = item.jumlahBarang > 0 ? 0 : 999;
    // Update a full copy so no fields (discount %, timestamps, etc.)
    // are lost when only the availability changes.
    final updatedItem = item.copy()
      ..jumlahBarang = newQuantity; // Toggle stock

    await inventoryService.updateInventory(updatedItem);
    _loadItems();
  }

  Future<void> _editItemDialog(ItemModel item) async {
    final updatedItem = await showDialog<ItemModel>(
      context: context,
      builder: (context) => MenuItemEditorDialog(item: item),
    );

    if (updatedItem != null) {
    await inventoryService.updateInventory(updatedItem);
      _loadItems();
    }
  }

  Future<void> _deleteItem(ItemModel item) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: context.panelBackground,
        title: Text('Delete Item?', style: TextStyle(color: context.appTextColor)),
        content: Text('Are you sure you want to delete ${item.nama}?', style: TextStyle(color: context.appTextColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B5E3C)))),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && item.id != null) {
      await inventoryService.deleteInventory(item.id!);
      _loadItems();
    }
  }

  Future<void> _addItemDialog() async {
    final newItem = await showDialog<ItemModel>(
      context: context,
      builder: (context) => const MenuItemEditorDialog(),
    );

    if (newItem != null) {
      await inventoryService.addInventory(newItem);
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((i) => i.nama.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: const Color(0xFF5D3A1A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: context.pageBackground,
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  style: TextStyle(color: context.appTextColor),
                  decoration: InputDecoration(
                    hintText: 'Search menu...',
                    hintStyle: TextStyle(color: context.secondaryTextColor),
                    prefixIcon: Icon(Icons.search, color: context.secondaryTextColor),
                    filled: true,
                    fillColor: context.mutedBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isAvailable = item.jumlahBarang > 0;
                       return Card(
                         margin: const EdgeInsets.only(bottom: 8),
                         color: context.panelBackground,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         child: ListTile(
                           title: Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                           subtitle: Text('RM ${item.price.toStringAsFixed(2)} | Code: ${item.code}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                icon: Icon(isAvailable ? Icons.check_circle : Icons.cancel, 
                                  color: isAvailable ? Colors.green : Colors.red),
                                label: Text(isAvailable ? 'Tersedia' : 'Habis (Out of Stock)', 
                                  style: TextStyle(color: isAvailable ? Colors.green : Colors.red)),
                                onPressed: () => _toggleStock(item),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editItemDialog(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItemDialog,
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
