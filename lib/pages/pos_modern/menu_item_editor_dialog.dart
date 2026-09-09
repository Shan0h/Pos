import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/utils/extension.dart';

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
  String? _menuCategory;
  List<String> _existingCategories = const [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.nama ?? '');
    _codeController = TextEditingController(text: widget.item?.code ?? '');
    _priceController = TextEditingController(text: (widget.item?.price ?? 0).toString());
    _discountController = TextEditingController(text: (widget.item?.diskonPersen ?? 0).toString());
    _menuCategory = widget.item?.menuCategory;

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
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final items = await inventoryService.getInventorys(category: 'Menu');
    final categories = items
        .map((i) => i.menuCategory)
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (mounted) {
      setState(() => _existingCategories = categories);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _addOption(String title, List<Map<String, dynamic>> list) {
    showDialog(
      context: context,
      builder: (c) {
        final nameCtrl = TextEditingController();
        final priceCtrl = TextEditingController(text: '0');
        return AlertDialog(
          backgroundColor: context.panelBackground,
          title: Text('Add $title', style: TextStyle(color: context.appTextColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: context.appTextColor),
                decoration: InputDecoration(
                  labelText: 'Name (e.g., Large)',
                  labelStyle: TextStyle(color: context.secondaryTextColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: context.appTextColor),
                  ),
                ),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: context.appTextColor),
                decoration: InputDecoration(
                  labelText: 'Additional Price (RM)',
                  labelStyle: TextStyle(color: context.secondaryTextColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: context.appTextColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('Cancel', style: TextStyle(color: context.secondaryTextColor)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    list.add({'name': nameCtrl.text, 'price': double.tryParse(priceCtrl.text) ?? 0});
                  });
                  Navigator.pop(c);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5E3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }

  Widget _buildCustomizationList(String title, List<Map<String, dynamic>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.appTextColor)),
            TextButton.icon(
              onPressed: () => _addOption(title, list),
              icon: const Icon(Icons.add, size: 18, color: Color(0xFF8B5E3C)),
              label: const Text('Add', style: TextStyle(color: Color(0xFF8B5E3C), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text('No options added yet.', style: TextStyle(color: context.secondaryTextColor)),
          ),
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          var opt = entry.value;
          return Card(
            elevation: 0,
            color: context.mutedBackground,
            child: ListTile(
              dense: true,
              title: Text(opt['name'], style: TextStyle(color: context.appTextColor, fontWeight: FontWeight.bold)),
              subtitle: Text('+RM ${opt['price']}', style: TextStyle(color: context.secondaryTextColor)),
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

  Future<String?> _promptNewCategory() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: context.panelBackground,
        title: Text('New Category', style: TextStyle(color: context.appTextColor)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: context.appTextColor),
          decoration: InputDecoration(
            labelText: 'Category name (e.g. Coffee)',
            labelStyle: TextStyle(color: context.secondaryTextColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('Cancel', style: TextStyle(color: context.secondaryTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5E3C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(c, ctrl.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.panelBackground,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item == null ? 'Add New Menu Item' : 'Edit Menu Item',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.appTextColor)),
            const SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: const Color(0xFF8B5E3C),
                      unselectedLabelColor: context.secondaryTextColor,
                      indicatorColor: const Color(0xFF8B5E3C),
                      tabs: const [
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
                                  style: TextStyle(color: context.appTextColor),
                                  decoration: InputDecoration(
                                    labelText: 'Item Name',
                                    labelStyle: TextStyle(color: context.secondaryTextColor),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: context.borderColor),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: context.appTextColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: _menuCategory,
                                  hint: Text('Menu Category (e.g. Coffee, Tea, Food)',
                                      style: TextStyle(color: context.secondaryTextColor)),
                                  style: TextStyle(color: context.appTextColor),
                                  dropdownColor: context.panelBackground,
                                  decoration: InputDecoration(
                                    labelText: 'Menu Category',
                                    labelStyle: TextStyle(color: context.secondaryTextColor),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: context.borderColor),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: context.appTextColor),
                                    ),
                                  ),
                                  items: [
                                    ..._existingCategories
                                        .where((c) => c != _menuCategory)
                                        .map((c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(c),
                                            )),
                                    const DropdownMenuItem(
                                      value: '__new__',
                                      child: Text('New category…',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  onChanged: (value) async {
                                    if (value == '__new__') {
                                      final newCategory =
                                          await _promptNewCategory();
                                      if (newCategory != null &&
                                          newCategory.trim().isNotEmpty) {
                                        final trimmed = newCategory.trim();
                                        setState(() {
                                          _menuCategory = trimmed;
                                          if (!_existingCategories
                                              .contains(trimmed)) {
                                            _existingCategories = [
                                              ..._existingCategories,
                                              trimmed
                                            ]..sort();
                                          }
                                        });
                                      } else {
                                        setState(() {}); // revert selection
                                      }
                                    } else {
                                      setState(() => _menuCategory = value);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _codeController,
                                  style: TextStyle(color: context.appTextColor),
                                  decoration: InputDecoration(
                                    labelText: 'Item Code (Optional)',
                                    labelStyle: TextStyle(color: context.secondaryTextColor),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: context.borderColor),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: context.appTextColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(color: context.appTextColor),
                                  decoration: InputDecoration(
                                    labelText: 'Selling Price (RM)',
                                    labelStyle: TextStyle(color: context.secondaryTextColor),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: context.borderColor),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: context.appTextColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _discountController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: context.appTextColor),
                                  decoration: InputDecoration(
                                    labelText: 'Discount Percent (%)',
                                    labelStyle: TextStyle(color: context.secondaryTextColor),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: context.borderColor),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: context.appTextColor),
                                    ),
                                  ),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: context.secondaryTextColor)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5E3C), foregroundColor: Colors.white),
                  onPressed: () {
                    if (_nameController.text.trim().isEmpty) return;

                    final customizations = {
                      'sizes': _sizes,
                      'sugar_levels': _sugarLevels,
                      'addons': _addons,
                    };

                    final exactPrice = double.tryParse(_priceController.text) ?? 0;

                    final newItem = ItemModel(
                      id: widget.item?.id,
                      nama: _nameController.text.trim(),
                      code: _codeController.text.trim().isEmpty ? 'MENU${DateTime.now().millisecondsSinceEpoch}' : _codeController.text.trim(),
                      jumlahBarang: widget.item?.jumlahBarang ?? 999, // default available
                      quantity: 1,
                      ukuran: '',
                      hargaDasar: widget.item?.hargaDasar ?? 0,
                      hargaJual: exactPrice.round(),
                      hargaJualExact: exactPrice,
                      diskonPersen: double.tryParse(_discountController.text) ?? 0,
                      isHargaJualPersen: false,
                      createdAt: widget.item?.createdAt ?? DateTime.now(),
                      category: 'Menu',
                      menuCategory: _menuCategory,
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
