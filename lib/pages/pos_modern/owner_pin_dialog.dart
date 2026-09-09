import 'package:flutter/material.dart';
import 'package:pos/controller/store_controller.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/utils/extension.dart';

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

  /// The real PIN, loaded from the store row (never guessed from an
  /// unloaded signal). Keypad stays disabled until this resolves.
  String? _correctPin;
  bool _pinLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final store = storeController.store.value.value;
    String? pin;
    if (store != null) {
      pin = store.ownerPin;
    } else {
      // Signal not loaded (cold start) — read straight from the DB.
      pin = (await storeService.getStore())?.ownerPin;
    }
    if (mounted) {
      setState(() {
        _correctPin = pin ?? '1234';
        _pinLoaded = true;
      });
    }
  }

  void _onKey(String value) {
    // Block input until the real PIN has loaded, and never exceed 4 digits.
    if (!_pinLoaded || _pin.length >= 4) {
      return;
    }
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
        color: context.panelBackground,
        width: 350,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Color(0xFF8B5E3C)),
            const SizedBox(height: 16),
            Text(
              'Owner Access',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.appTextColor),
            ),
            const SizedBox(height: 8),
            Text('Enter 4-digit PIN', style: TextStyle(color: context.secondaryTextColor)),
            if (!_pinLoaded) ...[
              const SizedBox(height: 8),
              Text('Loading...', style: TextStyle(color: context.secondaryTextColor, fontSize: 12)),
            ],
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
                    color: index < _pin.length ? const Color(0xFF8B5E3C) : context.borderColor,
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
          color: isAction
              ? Colors.red.withValues(alpha: context.isDarkMode ? 0.2 : 0.08)
              : context.mutedBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: isAction ? 16 : 24,
            fontWeight: FontWeight.bold,
            color: isAction ? Colors.red : context.appTextColor,
          ),
        ),
      ),
    );
  }
}
