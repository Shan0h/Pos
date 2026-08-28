import 'package:flutter/material.dart';
import 'package:pos/model/item_model.dart';

class TicketPanel extends StatelessWidget {
  final List<ItemModel> cartItems;
  final VoidCallback onClear;
  final ValueChanged<ItemModel> onIncrement;
  final ValueChanged<ItemModel> onDecrement;
  final VoidCallback onPay;

  const TicketPanel({
    super.key,
    required this.cartItems,
    required this.onClear,
    required this.onIncrement,
    required this.onDecrement,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    double subtotal = cartItems.fold(0, (sum, item) {
      double itemPrice = item.diskonPersen == null 
          ? (item.quantity * item.hargaJual).toDouble()
          : (item.quantity * (item.hargaJual - item.hargaJual * (item.diskonPersen! / 100)));
      return sum + itemPrice;
    });
    double tax = subtotal * 0.06; // 6% SST example
    double grandTotal = subtotal + tax;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Order',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton.icon(
                  onPressed: cartItems.isEmpty ? null : onClear,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label:
                      const Text('Clear', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No items in order',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            // Qty Controls
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: () => onDecrement(item),
                                    constraints: const BoxConstraints(
                                        minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                    splashRadius: 18,
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () => onIncrement(item),
                                    constraints: const BoxConstraints(
                                        minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                    splashRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Item Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nama,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RM ${item.hargaJual.toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Item Total
                            Text(
                              'RM ${(item.quantity * item.hargaJual).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Summary Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal', subtotal),
                const SizedBox(height: 8),
                _buildSummaryRow('Tax (6%)', tax),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'RM ${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Pay Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: cartItems.isEmpty ? null : onPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'PAY NOW',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
