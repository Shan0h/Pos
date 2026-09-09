import 'package:flutter/material.dart';
import 'package:pos/utils/extension.dart';

class PriceNumpadDialog extends StatefulWidget {
  final String itemName;
  final double initialPrice;

  const PriceNumpadDialog({
    super.key,
    required this.itemName,
    this.initialPrice = 0.0,
  });

  /// Helper function to easily show this dialog
  static Future<double?> show(BuildContext context,
      {required String itemName, double initialPrice = 0.0}) {
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PriceNumpadDialog(
        itemName: itemName,
        initialPrice: initialPrice,
      ),
    );
  }

  @override
  State<PriceNumpadDialog> createState() => _PriceNumpadDialogState();
}

class _PriceNumpadDialogState extends State<PriceNumpadDialog> {
  late int _cents;

  @override
  void initState() {
    super.initState();
    // Convert initial price to cents
    _cents = (widget.initialPrice * 100).round();
  }

  void _onDigitTap(String digit) {
    setState(() {
      if (digit == '00') {
        _cents = _cents * 100;
      } else {
        int val = int.parse(digit);
        _cents = (_cents * 10) + val;
      }

      // Safety limit to prevent extremely large numbers
      if (_cents > 99999999) {
        _cents = 99999999;
      }
    });
  }

  void _onBackspaceTap() {
    setState(() {
      _cents = _cents ~/ 10;
    });
  }

  double get _currentPrice => _cents / 100.0;

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _cents > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: context.panelBackground,
      child: Container(
        width: 400, // Fixed width for tablet friendly UI
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.itemName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.appTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: context.secondaryTextColor),
                  onPressed: () => Navigator.of(context).pop(), // Returns null
                  splashRadius: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display Screen
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: context.mutedBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5E3C), width: 2),
              ),
              child: Text(
                'RM ${_currentPrice.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: context.isDarkMode ? const Color(0xFFD7A86E) : const Color(0xFF8B5E3C),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Numpad Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildNumpadButton('1'),
                _buildNumpadButton('2'),
                _buildNumpadButton('3'),
                _buildNumpadButton('4'),
                _buildNumpadButton('5'),
                _buildNumpadButton('6'),
                _buildNumpadButton('7'),
                _buildNumpadButton('8'),
                _buildNumpadButton('9'),
                _buildNumpadButton('0'),
                _buildNumpadButton('00'),
                _buildBackspaceButton(),
              ],
            ),
            const SizedBox(height: 24),

            // OK / Add to Cart Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: canSubmit
                    ? () {
                        // Return the price
                        Navigator.of(context).pop(_currentPrice);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5E3C),
                  disabledBackgroundColor: context.mutedBackground,
                  disabledForegroundColor: context.secondaryTextColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: canSubmit ? 2 : 0,
                ),
                child: const Text(
                  'Add to Order',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadButton(String text) {
    return Material(
      color: context.mutedBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _onDigitTap(text),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.appTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      color: context.mutedBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _onBackspaceTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: context.appTextColor,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
