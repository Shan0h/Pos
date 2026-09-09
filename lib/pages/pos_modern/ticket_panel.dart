import 'package:flutter/material.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/utils/extension.dart';

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

  double lineTotal(ItemModel item) =>
      item.diskonPersen == null || item.diskonPersen == 0
          ? item.quantity * item.price
          : item.quantity *
              (item.price - item.price * (item.diskonPersen! / 100));

  /// Per-unit effective price after discount (for the second detail line).
  String unitPriceLabel(ItemModel item) {
    if (item.diskonPersen != null && item.diskonPersen != 0) {
      final discounted =
          item.price - item.price * (item.diskonPersen! / 100);
      return 'RM ${discounted.toStringAsFixed(2)} '
          '(${item.diskonPersen!.toStringAsFixed(0)}% off)';
    }
    return 'RM ${item.price.toStringAsFixed(2)}';
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: context.panelBackground,
        title:
            Text('Clear order?', style: TextStyle(color: context.appTextColor)),
        content: Text(
          'This removes all ${cartItems.length} line(s) from the current order.',
          style: TextStyle(color: context.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B5E3C))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) onClear();
  }

  @override
  Widget build(BuildContext context) {
    final double subtotal =
        cartItems.fold(0, (sum, item) => sum + lineTotal(item));
    final double grandTotal = subtotal;
    final int totalQty =
        cartItems.fold(0, (sum, item) => sum + item.quantity);
    final int totalDiscountLines = cartItems
        .where((i) => i.diskonPersen != null && i.diskonPersen != 0)
        .length;

    return Container(
      color: context.panelBackground,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: context.panelBackground,
              border: Border(
                bottom: BorderSide(color: context.borderColor, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Order',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.appTextColor,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalQty pcs',
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed:
                          cartItems.isEmpty ? null : () => _confirmClear(context),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
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
                            size: 64, color: context.subtleTextColor),
                        const SizedBox(height: 16),
                        Text(
                          'No items in order',
                          style: TextStyle(
                              color: context.secondaryTextColor, fontSize: 16),
                        ),
                        Text(
                          'Tap a product to add it',
                          style: TextStyle(
                              color: context.subtleTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: context.borderColor),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final hasDesc =
                          item.deskripsi != null && item.deskripsi!.isNotEmpty;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            // Qty Stepper
                            Container(
                              decoration: BoxDecoration(
                                color: context.mutedBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  _StepperButton(
                                    icon: item.quantity <= 1
                                        ? Icons.delete_outline
                                        : Icons.remove,
                                    color: item.quantity <= 1
                                        ? Colors.red
                                        : context.appTextColor,
                                    onTap: () => onDecrement(item),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: context.appTextColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  _StepperButton(
                                    icon: Icons.add,
                                    color: context.appTextColor,
                                    onTap: () => onIncrement(item),
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
                                    style: TextStyle(
                                        color: context.appTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    unitPriceLabel(item),
                                    style: TextStyle(
                                        color:
                                            context.secondaryTextColor,
                                        fontSize: 12),
                                  ),
                                  if (hasDesc)
                                    Text(
                                      item.deskripsi!,
                                      style: TextStyle(
                                          color: context.subtleTextColor,
                                          fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Item Total
                            Text(
                              'RM ${lineTotal(item).toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: context.appTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
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
              color: context.mutedBackground,
              border: Border(
                top: BorderSide(color: context.borderColor, width: 1),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow(context, 'Subtotal', subtotal),
                if (totalDiscountLines > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$totalDiscountLines discounted line(s)',
                    style: TextStyle(
                        color: context.subtleTextColor, fontSize: 11),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                          color: context.appTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'RM ${grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.isDarkMode
                              ? const Color(0xFFD7A86E)
                              : const Color(0xFF8B5E3C)),
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
                      backgroundColor: const Color(0xFF8B5E3C),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          context.mutedBackground,
                      disabledForegroundColor: context.secondaryTextColor,
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

  Widget _buildSummaryRow(BuildContext context, String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: context.secondaryTextColor, fontSize: 14),
        ),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: TextStyle(
              color: context.appTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 14),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 36,
        height: 40,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
