import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/utils/extension.dart';

class CustomizationResult {
  final String appendedName;
  final String description;
  final double extraPrice;

  CustomizationResult({
    required this.appendedName,
    required this.description,
    required this.extraPrice,
  });
}

class CoffeeCustomDialog extends StatefulWidget {
  final ItemModel item;

  const CoffeeCustomDialog({
    super.key,
    required this.item,
  });

  static Future<CustomizationResult?> show(BuildContext context, {required ItemModel item}) {
    return showDialog<CustomizationResult>(
      context: context,
      builder: (context) => CoffeeCustomDialog(item: item),
    );
  }

  @override
  State<CoffeeCustomDialog> createState() => _CoffeeCustomDialogState();
}

class _CoffeeCustomDialogState extends State<CoffeeCustomDialog> {
  List<Map<String, dynamic>> _sizes = [];
  List<Map<String, dynamic>> _sugarLevels = [];
  List<Map<String, dynamic>> _addons = [];

  Map<String, dynamic>? _selectedSize;
  Map<String, dynamic>? _selectedSugar;
  final List<Map<String, dynamic>> _selectedAddons = [];

  @override
  void initState() {
    super.initState();
    _parseCustomizations();
  }

  void _parseCustomizations() {
    if (widget.item.customizationsJson != null && widget.item.customizationsJson!.isNotEmpty) {
      try {
        final data = jsonDecode(widget.item.customizationsJson!);
        if (data['sizes'] != null) {
          _sizes = List<Map<String, dynamic>>.from(data['sizes']);
          if (_sizes.isNotEmpty) _selectedSize = _sizes.first;
        }
        if (data['sugar_levels'] != null) {
          _sugarLevels = List<Map<String, dynamic>>.from(data['sugar_levels']);
          if (_sugarLevels.isNotEmpty) _selectedSugar = _sugarLevels.first;
        }
        if (data['addons'] != null) {
          _addons = List<Map<String, dynamic>>.from(data['addons']);
        }
      } catch (e) {
        debugPrint('Error parsing customizations: $e');
      }
    }
  }

  double get _extraPrice {
    double total = 0;
    if (_selectedSize != null) total += (_selectedSize!['price'] as num).toDouble();
    if (_selectedSugar != null) total += (_selectedSugar!['price'] as num).toDouble();
    for (var addon in _selectedAddons) {
      total += (addon['price'] as num).toDouble();
    }
    return total;
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: const Color(0xFF8B5E3C).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF5D3A1A) : context.appTextColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF8B5E3C) : context.borderColor,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: const Color(0xFF8B5E3C).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF5D3A1A),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF5D3A1A) : context.appTextColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF8B5E3C) : context.borderColor,
        ),
      ),
    );
  }

  String _formatOption(Map<String, dynamic> opt) {
    double price = (opt['price'] as num).toDouble();
    if (price > 0) return '${opt['name']} (+RM${price.toStringAsFixed(2)})';
    return opt['name'];
  }

  @override
  Widget build(BuildContext context) {
    if (_sizes.isEmpty && _sugarLevels.isEmpty && _addons.isEmpty) {
      // If there are no customizations, return an empty dialog or just add immediately
      return AlertDialog(
        backgroundColor: context.panelBackground,
        title: Text('Add ${widget.item.nama}', style: TextStyle(color: context.appTextColor)),
        content: Text(
          'Are you sure you want to add this item?',
          style: TextStyle(color: context.appTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.secondaryTextColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, CustomizationResult(appendedName: widget.item.nama, description: '', extraPrice: 0)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5E3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          )
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: context.panelBackground,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customize: ${widget.item.nama}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.appTextColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),
              
              if (_sizes.isNotEmpty) ...[
                Text('Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sizes.map((s) => _buildChoiceChip(
                    _formatOption(s), 
                    _selectedSize == s, 
                    () => setState(() => _selectedSize = s)
                  )).toList(),
                ),
                const SizedBox(height: 16),
              ],

              if (_sugarLevels.isNotEmpty) ...[
                Text('Sugar Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sugarLevels.map((s) => _buildChoiceChip(
                    _formatOption(s), 
                    _selectedSugar == s, 
                    () => setState(() => _selectedSugar = s)
                  )).toList(),
                ),
                const SizedBox(height: 16),
              ],

              if (_addons.isNotEmpty) ...[
                Text('Add-ons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _addons.map((a) => _buildFilterChip(
                    _formatOption(a), 
                    _selectedAddons.contains(a), 
                    () => setState(() {
                      if (_selectedAddons.contains(a)) {
                        _selectedAddons.remove(a);
                      } else {
                        _selectedAddons.add(a);
                      }
                    })
                  )).toList(),
                ),
                const SizedBox(height: 32),
              ],

              // Summary and Add Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.mutedBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Price', style: TextStyle(color: context.secondaryTextColor)),
                        Text(
                          'RM ${(widget.item.price + _extraPrice).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.appTextColor),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5E3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        String suffix = '';
                        List<String> descParts = [];

                        if (_selectedSize != null) {
                          suffix = ' (${_selectedSize!['name']})';
                        }
                        
                        if (_selectedSugar != null) {
                          descParts.add('Sugar: ${_selectedSugar!['name']}');
                        }

                        if (_selectedAddons.isNotEmpty) {
                          final addonNames = _selectedAddons.map((a) => a['name']).join(', ');
                          descParts.add('Add: $addonNames');
                        }

                        Navigator.pop(context, CustomizationResult(
                          appendedName: suffix,
                          description: descParts.join(' | '),
                          extraPrice: _extraPrice,
                        ));
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Cart', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
