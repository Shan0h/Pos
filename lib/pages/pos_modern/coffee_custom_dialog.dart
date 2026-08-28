import 'package:flutter/material.dart';

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
  final String itemName;
  final double basePrice;

  const CoffeeCustomDialog({
    super.key,
    required this.itemName,
    required this.basePrice,
  });

  static Future<CustomizationResult?> show(BuildContext context, {required String itemName, required double basePrice}) {
    return showDialog<CustomizationResult>(
      context: context,
      builder: (context) => CoffeeCustomDialog(itemName: itemName, basePrice: basePrice),
    );
  }

  @override
  State<CoffeeCustomDialog> createState() => _CoffeeCustomDialogState();
}

class _CoffeeCustomDialogState extends State<CoffeeCustomDialog> {
  String _temperature = 'Hot'; // Hot, Iced
  String _size = 'Regular'; // Regular, Large
  String _sugar = 'Normal'; // Normal, Kurang Manis, Tiada Gula
  final List<String> _addons = []; // Extra Shot, Syrup

  double get _extraPrice {
    double total = 0;
    if (_temperature == 'Iced') total += 1.0;
    if (_size == 'Large') total += 2.0;
    if (_addons.contains('Extra Shot')) total += 2.0;
    if (_addons.contains('Vanilla Syrup')) total += 1.5;
    if (_addons.contains('Caramel Syrup')) total += 1.5;
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customize: ${widget.itemName}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Temperature
            const Text('Temperature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChoiceChip('Hot', _temperature == 'Hot', () => setState(() => _temperature = 'Hot')),
                const SizedBox(width: 8),
                _buildChoiceChip('Iced (+RM1.00)', _temperature == 'Iced', () => setState(() => _temperature = 'Iced')),
              ],
            ),
            const SizedBox(height: 16),

            // Size
            const Text('Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChoiceChip('Regular', _size == 'Regular', () => setState(() => _size = 'Regular')),
                const SizedBox(width: 8),
                _buildChoiceChip('Large (+RM2.00)', _size == 'Large', () => setState(() => _size = 'Large')),
              ],
            ),
            const SizedBox(height: 16),

            // Sugar Level
            const Text('Sugar Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChoiceChip('Normal', _sugar == 'Normal', () => setState(() => _sugar = 'Normal')),
                const SizedBox(width: 8),
                _buildChoiceChip('Kurang Manis', _sugar == 'Kurang Manis', () => setState(() => _sugar = 'Kurang Manis')),
                const SizedBox(width: 8),
                _buildChoiceChip('Tiada Gula', _sugar == 'Tiada Gula', () => setState(() => _sugar = 'Tiada Gula')),
              ],
            ),
            const SizedBox(height: 16),

            // Add-ons
            const Text('Add-ons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('Extra Shot (+RM2.00)', _addons.contains('Extra Shot'), (val) {
                  setState(() { val ? _addons.add('Extra Shot') : _addons.remove('Extra Shot'); });
                }),
                _buildFilterChip('Vanilla Syrup (+RM1.50)', _addons.contains('Vanilla Syrup'), (val) {
                  setState(() { val ? _addons.add('Vanilla Syrup') : _addons.remove('Vanilla Syrup'); });
                }),
                _buildFilterChip('Caramel Syrup (+RM1.50)', _addons.contains('Caramel Syrup'), (val) {
                  setState(() { val ? _addons.add('Caramel Syrup') : _addons.remove('Caramel Syrup'); });
                }),
              ],
            ),

            const SizedBox(height: 32),
            
            // Total & Submit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Price', style: TextStyle(fontSize: 14, color: Colors.teal)),
                      Text(
                        'RM ${(widget.basePrice + _extraPrice).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      final suffixName = '($_temperature, ${_size == 'Regular' ? 'Reg' : 'Lrg'})';
                      final desc = '$_sugar${_addons.isNotEmpty ? ', ' : ''}${_addons.join(', ')}';
                      Navigator.pop(context, CustomizationResult(
                        appendedName: suffixName,
                        description: desc,
                        extraPrice: _extraPrice,
                      ));
                    },
                    child: const Text('Add to Cart'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.teal,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Colors.teal,
      backgroundColor: Colors.grey[200],
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
