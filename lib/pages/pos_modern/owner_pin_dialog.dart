import 'package:flutter/material.dart';

class OwnerPinDialog extends StatefulWidget {
  const OwnerPinDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const OwnerPinDialog(),
    );
    return result ?? false;
  }

  @override
  State<OwnerPinDialog> createState() => _OwnerPinDialogState();
}

class _OwnerPinDialogState extends State<OwnerPinDialog> {
  String _pin = '';
  final String _correctPin = '1234';

  void _onKey(String value) {
    if (_pin.length < 4) {
      setState(() => _pin += value);
      if (_pin.length == 4) {
        if (_pin == _correctPin) {
          Navigator.pop(context, true);
        } else {
          // Wrong PIN
          setState(() => _pin = '');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN!'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.teal),
            const SizedBox(height: 16),
            const Text(
              'Owner Access',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Enter 4-digit PIN', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            // PIN Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? Colors.teal : Colors.grey[300],
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Numpad
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (var i = 1; i <= 9; i++)
                  _buildKey(i.toString(), () => _onKey(i.toString())),
                _buildKey('Cancel', () => Navigator.pop(context, false), isAction: true),
                _buildKey('0', () => _onKey('0')),
                _buildKey('Del', _onBackspace, isAction: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String label, VoidCallback onTap, {bool isAction = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isAction ? Colors.red[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: isAction ? 16 : 24,
            fontWeight: FontWeight.bold,
            color: isAction ? Colors.red : Colors.black87,
          ),
        ),
      ),
    );
  }
}
