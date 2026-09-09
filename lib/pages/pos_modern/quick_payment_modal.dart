import 'package:flutter/material.dart';
import 'package:pos/enum/payment_enum.dart';
import 'package:pos/controller/store_controller.dart';
import 'dart:convert';
import 'package:pos/utils/extension.dart';

class PaymentResult {
  final TypePayment type;
  final double cashAmount;

  PaymentResult({required this.type, required this.cashAmount});
}

class QuickPaymentModal extends StatefulWidget {
  final double totalAmount;

  const QuickPaymentModal({super.key, required this.totalAmount});

  static Future<PaymentResult?> show(BuildContext context, double totalAmount) {
    return showDialog<PaymentResult>(
      context: context,
      builder: (context) => QuickPaymentModal(totalAmount: totalAmount),
    );
  }

  @override
  State<QuickPaymentModal> createState() => _QuickPaymentModalState();
}

class _QuickPaymentModalState extends State<QuickPaymentModal> {
  TypePayment _selectedType = TypePayment.cash;
  double _tenderedAmount = 0.0;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tenderedAmount = widget.totalAmount;
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.appTextColor;
    return Dialog(
      backgroundColor: context.panelBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  'Payment',
                  style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Grand Total
            Center(
              child: Column(
                children: [
                  Text('Total Amount', style: TextStyle(fontSize: 16, color: context.secondaryTextColor)),
                  Text(
                    'RM ${widget.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: context.isDarkMode
                            ? const Color(0xFFD7A86E)
                            : const Color(0xFF8B5E3C)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment Methods
            Text('Payment Method', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMethodButton(TypePayment.cash, Icons.money, 'Cash')),
                const SizedBox(width: 8),
                Expanded(child: _buildMethodButton(TypePayment.qris, Icons.qr_code, 'QR DuitNow')),
                const SizedBox(width: 8),
                Expanded(child: _buildMethodButton(TypePayment.transfer, Icons.credit_card, 'Card')),
              ],
            ),
            const SizedBox(height: 32),

            // Cash Options (Only if Cash is selected)
            if (_selectedType == TypePayment.cash) ...[
              Text('Quick Cash', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Only sensible denominations: exact amount and bills
                  // at/above the total (tapping RM 5 on a RM 12 order just
                  // confuses the cashier).
                  _buildQuickCashButton(widget.totalAmount, 'Exact'),
                  ..._quickCashDenominations(),
                ],
              ),
              const SizedBox(height: 16),
              
              // Custom Amount Input
              TextField(
                controller: _customAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Custom Cash Amount',
                  labelStyle: TextStyle(color: context.secondaryTextColor),
                  prefixText: 'RM ',
                  prefixStyle: TextStyle(color: textColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) {
                  final amount = double.tryParse(val);
                  if (amount != null) {
                    setState(() => _tenderedAmount = amount);
                  }
                },
              ),
              
              const SizedBox(height: 16),
              // Change Calculation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _tenderedAmount >= widget.totalAmount ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Change', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      'RM ${(_tenderedAmount >= widget.totalAmount ? (_tenderedAmount - widget.totalAmount) : 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _tenderedAmount >= widget.totalAmount ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              if (_tenderedAmount < widget.totalAmount) ...[
                const SizedBox(height: 8),
                Text(
                  'Cash received (RM ${_tenderedAmount.toStringAsFixed(2)}) is less than the total. '
                  'Increase the amount to confirm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],

            const SizedBox(height: 32),
            
            // Confirm Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5E3C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: context.mutedBackground,
                  disabledForegroundColor: context.secondaryTextColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: (_selectedType == TypePayment.cash && _tenderedAmount < widget.totalAmount) ? null : () async {
                  if (_selectedType == TypePayment.qris) {
                    final store = storeController.store.value.value;
                    final qr1 = store?.qrDuitNow1;
                    final qr2 = store?.qrDuitNow2;
                    
                    if (qr1 != null || qr2 != null) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => QRVerificationDialog(qr1: qr1, qr2: qr2),
                      );
                      if (confirmed != true) {
                        return; // Cancelled
                      }
                    }
                  }

                  if (context.mounted) {
                    Navigator.pop(context, PaymentResult(
                      type: _selectedType,
                      cashAmount: _selectedType == TypePayment.cash ? _tenderedAmount : widget.totalAmount,
                    ));
                  }
                },
                child: const Text('CONFIRM PAYMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildMethodButton(TypePayment type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() {
        _selectedType = type;
        if (type != TypePayment.cash) {
          _tenderedAmount = widget.totalAmount;
        }
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5E3C) : context.mutedBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF8B5E3C) : context.borderColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : context.appTextColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : context.appTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bill denominations at or above the current total (common cash notes).
  List<Widget> _quickCashDenominations() {
    const bills = [5.0, 10.0, 20.0, 50.0, 100.0];
    final usable = bills
        .where((b) => b >= widget.totalAmount)
        .map((b) => MapEntry(b, 'RM ${b.toStringAsFixed(0)}'))
        .toList();
    final entries = usable.isNotEmpty
        ? usable
        : [
            // Total above RM 100 — offer the next sensible rounded bill up.
            MapEntry(((widget.totalAmount / 50).ceil() * 50).toDouble(),
                'RM ${((widget.totalAmount / 50).ceil() * 50).toStringAsFixed(0)}'),
          ];
    return entries
        .map((e) => _buildQuickCashButton(e.key, e.value))
        .toList();
  }

  Widget _buildQuickCashButton(double amount, String label) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextColor)),
      backgroundColor: context.mutedBackground,
      onPressed: () {
        setState(() {
          _tenderedAmount = amount;
          _customAmountController.text = amount.toStringAsFixed(2);
        });
      },
    );
  }
}

class QRVerificationDialog extends StatelessWidget {
  final String? qr1;
  final String? qr2;

  const QRVerificationDialog({super.key, this.qr1, this.qr2});

  @override
  Widget build(BuildContext context) {
    final textColor = context.appTextColor;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        color: context.panelBackground,
        width: (qr1 != null && qr2 != null) ? 600 : 350,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, size: 48, color: Color(0xFF8B5E3C)),
              const SizedBox(height: 16),
              Text(
                'Scan QR Code',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Please ask the customer to scan the QR code below:',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.secondaryTextColor),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (qr1 != null) _buildZoomableQR(context, 'DuitNow 1', qr1!),
                  if (qr1 != null && qr2 != null) const SizedBox(width: 24),
                  if (qr2 != null) _buildZoomableQR(context, 'DuitNow 2', qr2!),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Has the customer scanned the QR code and is the payment confirmed?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: context.borderColor),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('NO (CANCEL)', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color(0xFF8B5E3C),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('YES (CONFIRM)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomableQR(BuildContext context, String title, String base64qr) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextColor)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      InteractiveViewer(
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(base64Decode(base64qr), fit: BoxFit.contain),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 32),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(base64Decode(base64qr), height: 200, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

