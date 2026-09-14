import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/controller/awaiting_orders_controller.dart';
import 'package:pos/controller/user_controller.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/utils/order_ref.dart';
import 'package:pos/utils/extension.dart';
import 'package:signals/signals_flutter.dart';

/// Awaiting Orders — lets the worker see which paid orders are still
/// pending preparation and mark them done. Data is local (Isar); status
/// updates live via [awaitingOrdersController].
class AwaitingOrdersPage extends StatefulWidget {
  const AwaitingOrdersPage({super.key});

  @override
  State<AwaitingOrdersPage> createState() => _AwaitingOrdersPageState();
}

class _AwaitingOrdersPageState extends State<AwaitingOrdersPage> {
  bool _showDone = false;
  bool _refreshed = false;
  String _markingRef = '';
  String _cancellingRef = '';

  /// Resolves a staff display name from the order's staffId using the
  /// cached users signal. Falls back to 'Staff' when unknown.
  String _staffName(int staffId) {
    final users = userController.users.peek().value ?? const [];
    for (final u in users) {
      if (u.id == staffId) return u.nama;
    }
    return 'Staff';
  }

  @override
  void initState() {
    super.initState();
    // Pick up orders created since the last visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_refreshed) {
        _refreshed = true;
        awaitingOrdersController.refreshAll();
      }
    });
  }

  Future<void> _markDone(PenjualanModel order) async {
    final ref = orderRef(order.id);
    if (_markingRef.isNotEmpty || _cancellingRef.isNotEmpty) return; // one at a time
    setState(() => _markingRef = ref);
    try {
      await awaitingOrdersController.markDone(order);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $ref marked as done.'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update order $ref — please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _markingRef = '');
    }
  }

  /// Cancel (void) a paid order that was never fulfilled. Asks for
  /// confirmation first — this permanently removes the order and returns
  /// its items to stock.
  Future<void> _cancelOrder(PenjualanModel order) async {
    final ref = orderRef(order.id);
    if (_markingRef.isNotEmpty || _cancellingRef.isNotEmpty) return; // one at a time
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cancel order $ref?'),
        content: Text(
          'This permanently removes the paid order (RM '
          '${order.totalHarga.toStringAsFixed(2)}) and returns its items to '
          'stock. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancellingRef = ref);
    try {
      await awaitingOrdersController.cancelOrder(order);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $ref cancelled — items returned to stock.'),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not cancel order $ref — please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellingRef = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final awaitingState = awaitingOrdersController.awaiting.watch(context);
    final completedState = awaitingOrdersController.completed.watch(context);

    final awaiting = awaitingState.value ?? const <PenjualanModel>[];
    final completed = completedState.value ?? const <PenjualanModel>[];
    final orders = _showDone ? completed : awaiting;
    final isLoading = _showDone
        ? completedState.isLoading
        : awaitingState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Awaiting Orders'),
        backgroundColor: const Color(0xFF5D3A1A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: context.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Awaiting / Done toggle
            Container(
              padding: const EdgeInsets.all(12),
              color: context.panelBackground,
              child: Row(
                children: [
                  Expanded(
                    child: _StatusTab(
                      label: 'Awaiting',
                      count: awaiting.length,
                      selected: !_showDone,
                      selectedColor: const Color(0xFF8B5E3C),
                      onTap: () => setState(() => _showDone = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusTab(
                      label: 'Done',
                      count: completed.length,
                      selected: _showDone,
                      selectedColor: Colors.green.shade700,
                      onTap: () => setState(() => _showDone = true),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                      ? _EmptyState(showDone: _showDone)
                      : RefreshIndicator(
                          onRefresh: awaitingOrdersController.refreshAll,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: orders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _OrderCard(
                                order: order,
                                isAwaiting: !_showDone,
                                isMarking: _markingRef == orderRef(order.id),
                                isCancelling: _cancellingRef == orderRef(order.id),
                                staffName: _staffName(order.staffId),
                                onMarkDone: () => _markDone(order),
                                onCancel: () => _cancelOrder(order),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _StatusTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedColor : context.mutedBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selectedColor : context.borderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : context.secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (count > 0 ? selectedColor.withValues(alpha: 0.15) : null),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : (count > 0 ? selectedColor : context.subtleTextColor),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool showDone;

  const _EmptyState({required this.showDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showDone ? Icons.check_circle_outline : Icons.schedule,
            size: 64,
            color: context.subtleTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            showDone
                ? 'No completed orders yet today'
                : 'No orders awaiting preparation',
            style: TextStyle(
              color: context.secondaryTextColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showDone
                ? 'Orders you mark as done appear here'
                : 'New paid orders will appear here',
            style: TextStyle(color: context.subtleTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PenjualanModel order;
  final bool isAwaiting;
  final bool isMarking;
  final bool isCancelling;
  final String staffName;
  final VoidCallback onMarkDone;
  final VoidCallback onCancel;

  const _OrderCard({
    required this.order,
    required this.isAwaiting,
    required this.isMarking,
    required this.isCancelling,
    required this.staffName,
    required this.onMarkDone,
    required this.onCancel,
  });

  String get _timeLabel => DateFormat('HH:mm').format(order.createdAt);

  List<Widget> _itemLines(BuildContext context) {
    final items = order.items;
    const maxLines = 3;
    final shown = items.take(maxLines).toList();
    final lines = <Widget>[];
    for (final item in shown) {
      lines.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '${item.quantity ?? 0} x ${item.nama ?? '-'}',
            style: TextStyle(
              color: context.appTextColor,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    if (items.length > maxLines) {
      lines.add(
        Text(
          '+${items.length - maxLines} more item(s)',
          style: TextStyle(
            color: context.subtleTextColor,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return lines;
  }

  Color get _paymentColor {
    switch (order.paymentMethod) {
      case 'cash':
        return Colors.green.shade700;
      case 'qris':
        return const Color(0xFFD7A86E);
      case 'transfer':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  String get _paymentLabel {
    switch (order.paymentMethod) {
      case 'cash':
        return 'Cash';
      case 'qris':
        return 'QRIS';
      case 'transfer':
        return 'Transfer';
      default:
        return 'Paid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panelBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAwaiting
              ? const Color(0xFF8B5E3C).withValues(alpha: 0.4)
              : Colors.green.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ref + time + status/payment chips
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order ${orderRef(order.id)}',
                  style: TextStyle(
                    color: context.appTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _timeLabel,
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _paymentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _paymentLabel,
                  style: TextStyle(
                    color: _paymentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Items
          ..._itemLines(context),
          const SizedBox(height: 10),
          // Footer: total + staff
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total RM ${order.totalHarga.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: context.appTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$staffName · ${order.totalItem} item(s)',
                      style: TextStyle(
                        color: context.subtleTextColor,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isAwaiting) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          // Actions: Cancel (void) first, then Mark as Done — own full-width
          // row so both buttons never overflow on narrow phones.
          if (isAwaiting) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        (isMarking || isCancelling) ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      disabledForegroundColor:
                          Colors.red.shade700.withValues(alpha: 0.5),
                      side: BorderSide(
                        color: Colors.red.shade700.withValues(alpha: 0.6),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: isCancelling
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red.shade700,
                            ),
                          )
                        : const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(
                      isCancelling ? 'Cancelling...' : 'Cancel',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        (isMarking || isCancelling) ? null : onMarkDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5E3C),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF8B5E3C).withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: isMarking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      isMarking ? 'Updating...' : 'Mark as Done',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
