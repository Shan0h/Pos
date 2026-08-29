import 'package:flutter/material.dart';
import 'package:pos/enum/payment_enum.dart';

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
    return Dialog(
      backgroundColor: Colors.white,
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
                const Text(
                  'Payment',
                  style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
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
                  const Text('Total Amount', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text(
                    'RM ${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment Methods
            const Text('Payment Method', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
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
              const Text('Quick Cash', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickCashButton(widget.totalAmount, 'Exact'),
                  _buildQuickCashButton(5.0, 'RM 5'),
                  _buildQuickCashButton(10.0, 'RM 10'),
                  _buildQuickCashButton(20.0, 'RM 20'),
                  _buildQuickCashButton(50.0, 'RM 50'),
                  _buildQuickCashButton(100.0, 'RM 100'),
                ],
              ),
              const SizedBox(height: 16),
              
              // Custom Amount Input
              TextField(
                controller: _customAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Custom Cash Amount',
                  prefixText: 'RM ',
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
                    const Text('Change', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
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
            ],

            const SizedBox(height: 32),
            
            // Confirm Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: (_selectedType == TypePayment.cash && _tenderedAmount < widget.totalAmount) ? null : () {
                  Navigator.pop(context, PaymentResult(
                    type: _selectedType,
                    cashAmount: _selectedType == TypePayment.cash ? _tenderedAmount : widget.totalAmount,
                  ));
                },
                child: const Text('CONFIRM PAYMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
          color: isSelected ? Colors.teal : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black87, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCashButton(double amount, String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.grey[200],
      onPressed: () {
        setState(() {
          _tenderedAmount = amount;
          _customAmountController.text = amount.toStringAsFixed(2);
        });
      },
    );
  }
}
