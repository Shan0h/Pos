import 'package:flutter/material.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/controller/inventory_controller.dart';

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
    final items = await Database().getInventorys();
    inventoryController.inventorys.reload(); // Trigger refresh for POS page
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _toggleStock(ItemModel item) async {
    final newQuantity = item.jumlahBarang > 0 ? 0 : 999;
    final updatedItem = ItemModel(
      id: item.id,
      nama: item.nama,
      code: item.code,
      jumlahBarang: newQuantity, // Toggle stock
      quantity: item.quantity,
      ukuran: item.ukuran,
      hargaDasar: item.hargaDasar,
      hargaJual: item.hargaJual,
      isHargaJualPersen: item.isHargaJualPersen,
      deskripsi: item.deskripsi,
    )..isSynced = false;
    
    await Database().updateInventory(updatedItem);
    _loadItems();
  }

  Future<void> _editItemDialog(ItemModel item) async {
    final nameController = TextEditingController(text: item.nama);
    final priceController = TextEditingController(text: item.hargaJual.toString());

    final bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name (Category = First Word)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (RM)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newPrice = int.tryParse(priceController.text) ?? item.hargaJual;
      final updatedItem = ItemModel(
        id: item.id,
        nama: nameController.text,
        code: item.code,
        jumlahBarang: item.jumlahBarang,
        quantity: item.quantity,
        ukuran: item.ukuran,
        hargaDasar: item.hargaDasar,
        hargaJual: newPrice,
        isHargaJualPersen: item.isHargaJualPersen,
        deskripsi: item.deskripsi,
      )..isSynced = false;
      
      await Database().updateInventory(updatedItem);
      _loadItems();
    }
  }

  Future<void> _deleteItem(ItemModel item) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete ${item.nama}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && item.id != null) {
      await Database().deleteInventory(item.id!);
      _loadItems();
    }
  }

  Future<void> _addItemDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final codeController = TextEditingController();

    final bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name (Category = First Word)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (RM)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Item Code (e.g. COFFEE01, optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newPrice = int.tryParse(priceController.text) ?? 0;
      final newCode = codeController.text.trim().isEmpty
          ? 'MENU${DateTime.now().millisecondsSinceEpoch}'
          : codeController.text.trim();

      final newItem = ItemModel(
        nama: nameController.text.trim(),
        code: newCode,
        jumlahBarang: 999, // By default available
        quantity: 1,
        ukuran: '',
        hargaDasar: 0,
        hargaJual: newPrice,
        isHargaJualPersen: false,
        createdAt: DateTime.now(),
      )..isSynced = false;

      await Database().addInventory(newItem);
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((i) => i.nama.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search menu...',
                    hintStyle: const TextStyle(color: Colors.black54),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('RM ${item.hargaJual.toStringAsFixed(2)} | Code: ${item.code}'),
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
