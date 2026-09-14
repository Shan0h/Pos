import 'package:flutter/material.dart';
import 'package:pos/utils/extension.dart';

/// Reusable 4-digit passcode dialog for the Netflix-style staff picker.
///
/// Unlike [OwnerPinDialog] (which loads its PIN from the store), the
/// correct PIN is passed in already resolved by the caller, so the keypad
/// enables immediately — no async loading state inside the dialog.
class StaffPinDialog extends StatefulWidget {
  final String title;
  final String staffName;
  final String correctPin;

  const StaffPinDialog({
    super.key,
    required this.title,
    required this.staffName,
    required this.correctPin,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String staffName,
    required String correctPin,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StaffPinDialog(
        title: title,
        staffName: staffName,
        correctPin: correctPin,
      ),
    );
    return result ?? false;
  }

  @override
  State<StaffPinDialog> createState() => _StaffPinDialogState();
}

class _StaffPinDialogState extends State<StaffPinDialog> {
  String _pin = '';
  int _wrongAttempts = 0;

  bool get _lockedOut => _wrongAttempts >= 3;

  void _onKey(String value) {
    if (_lockedOut || _pin.length >= 4) return;
    setState(() => _pin += value);
    if (_pin.length == 4) {
      if (_pin == widget.correctPin) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _pin = '';
          _wrongAttempts++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
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
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          color: context.panelBackground,
          width: 350,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline,
                  size: 48, color: Color(0xFF8B5E3C)),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.appTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.staffName,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.secondaryTextColor),
              ),
              const SizedBox(height: 8),
              if (_lockedOut)
                Text(
                  'Too many attempts. Ask the owner to reset your passcode.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 13),
                )
              else
                Text(
                  'Enter 4-digit passcode',
                  style: TextStyle(color: context.secondaryTextColor),
                ),
              const SizedBox(height: 24),

              // PIN display dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length
                          ? const Color(0xFF8B5E3C)
                          : context.borderColor,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Keypad
              AbsorbPointer(
                absorbing: _lockedOut,
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 1; i <= 9; i++)
                      _buildKey(i.toString(), () => _onKey(i.toString())),
                    _buildKey('Cancel', () => Navigator.pop(context, false),
                        isAction: true),
                    _buildKey('0', () => _onKey('0')),
                    _buildKey('Del', _onBackspace, isAction: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label, VoidCallback onTap, {bool isAction = false}) {
    return InkWell(
      onTap: _lockedOut ? null : onTap,
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
            color: isAction
                ? Colors.red
                : (_lockedOut ? context.subtleTextColor : context.appTextColor),
          ),
        ),
      ),
    );
  }
}
