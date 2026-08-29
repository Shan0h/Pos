import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pos/model/item_model.dart';

class MenuItemEditorDialog extends StatefulWidget {
  final ItemModel? item;

  const MenuItemEditorDialog({super.key, this.item});

  @override
  State<MenuItemEditorDialog> createState() => _MenuItemEditorDialogState();
}

class _MenuItemEditorDialogState extends State<MenuItemEditorDialog> {
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;

  List<Map<String, dynamic>> _sizes = [];
  List<Map<String, dynamic>> _sugarLevels = [];
  List<Map<String, dynamic>> _addons = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.nama ?? '');
    _codeController = TextEditingController(text: widget.item?.code ?? '');
    _priceController = TextEditingController(text: (widget.item?.hargaJual ?? 0).toString());
    _discountController = TextEditingController(text: (widget.item?.diskonPersen ?? 0).toString());

    if (widget.item?.customizationsJson != null && widget.item!.customizationsJson!.isNotEmpty) {
      try {
        final data = jsonDecode(widget.item!.customizationsJson!);
        if (data['sizes'] != null) _sizes = List<Map<String, dynamic>>.from(data['sizes']);
        if (data['sugar_levels'] != null) _sugarLevels = List<Map<String, dynamic>>.from(data['sugar_levels']);
        if (data['addons'] != null) _addons = List<Map<String, dynamic>>.from(data['addons']);
      } catch (e) {
        debugPrint('Error parsing customizations: $e');
      }
    }
  }

  void _addOption(String title, List<Map<String, dynamic>> list) {
    showDialog(
      context: context,
      builder: (c) {
        final nameCtrl = TextEditingController();
        final priceCtrl = TextEditingController(text: '0');
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Add $title', style: const TextStyle(color: Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl, 
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Name (e.g., Large)',
                  labelStyle: TextStyle(color: Colors.black54),
                )
              ),
              TextField(
                controller: priceCtrl, 
                keyboardType: TextInputType.number, 
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Additional Price (RM)',
                  labelStyle: TextStyle(color: Colors.black54),
                )
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel', style: TextStyle(color: Colors.brown))),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    list.add({'name': nameCtrl.text, 'price': double.tryParse(priceCtrl.text) ?? 0});
                  });
                  Navigator.pop(c);
                }
              },
              child: const Text('Add'),
            )
          ],
        );
      }
    );
  }

  Widget _buildCustomizationList(String title, List<Map<String, dynamic>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            TextButton.icon(
              onPressed: () => _addOption(title, list),
              icon: const Icon(Icons.add, size: 18, color: Colors.brown),
              label: const Text('Add', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text('No options added yet.', style: TextStyle(color: Colors.black54)),
          ),
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          var opt = entry.value;
          return Card(
            elevation: 0,
            color: Colors.grey[200],
            child: ListTile(
              dense: true,
              title: Text(opt['name'], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              subtitle: Text('+RM ${opt['price']}', style: const TextStyle(color: Colors.black54)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => setState(() => list.removeAt(idx)),
              ),
            ),
          );
        }),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item == null ? 'Add New Menu Item' : 'Edit Menu Item',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.brown,
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: Colors.brown,
                      tabs: [
                        Tab(text: 'Basic Info'),
                        Tab(text: 'Customizations'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Basic Info Tab
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: const InputDecoration(labelText: 'Item Name (Category = First Word)', labelStyle: TextStyle(color: Colors.black54)),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _codeController,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: const InputDecoration(labelText: 'Item Code (Optional)', labelStyle: TextStyle(color: Colors.black54)),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: const InputDecoration(labelText: 'Selling Price (RM)', labelStyle: TextStyle(color: Colors.black54)),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _discountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: const InputDecoration(labelText: 'Discount Percent (%)', labelStyle: TextStyle(color: Colors.black54)),
                                ),
                              ],
                            ),
                          ),
                          // Customizations Tab
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCustomizationList('Item Sizes', _sizes),
                                _buildCustomizationList('Sugar Levels', _sugarLevels),
                                _buildCustomizationList('Add-ons', _addons),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.brown))),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                  onPressed: () {
                    if (_nameController.text.trim().isEmpty) return;
                    
                    final customizations = {
                      'sizes': _sizes,
                      'sugar_levels': _sugarLevels,
                      'addons': _addons,
                    };

                    final newItem = ItemModel(
                      id: widget.item?.id,
                      nama: _nameController.text.trim(),
                      code: _codeController.text.trim().isEmpty ? 'MENU${DateTime.now().millisecondsSinceEpoch}' : _codeController.text.trim(),
                      jumlahBarang: widget.item?.jumlahBarang ?? 999, // default available
                      quantity: 1,
                      ukuran: '',
                      hargaDasar: widget.item?.hargaDasar ?? 0,
                      hargaJual: int.tryParse(_priceController.text) ?? 0,
                      diskonPersen: double.tryParse(_discountController.text) ?? 0,
                      isHargaJualPersen: false,
                      createdAt: widget.item?.createdAt ?? DateTime.now(),
                      category: 'Menu',
                      customizationsJson: jsonEncode(customizations),
                    )..isSynced = false;

                    Navigator.pop(context, newItem);
                  },
                  child: const Text('Save'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
