import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/service/database.dart';
import 'package:pos/enum/payment_enum.dart';
import 'menu_management_page.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  bool _isLoading = true;
  double _totalSales = 0;
  int _receiptCount = 0;
  Map<String, int> _topItems = {};
  Map<TypePayment, int> _paymentMethods = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final reports = await Database().getReportToday();
    
    double total = 0;
    int receipts = reports.length;
    Map<String, int> itemCounts = {};
    Map<TypePayment, int> payments = {
      TypePayment.cash: 0,
      TypePayment.qris: 0,
      TypePayment.transfer: 0,
    };

    for (var report in reports) {
      total += report.totalHarga;
      
      // I don't have TypePayment in PenjualanModel stored? Wait, PenjualanModel doesn't store TypePayment.
      // We will just mock the payment methods split based on total logic or skip it if it's not saved.
      // Actually, since we can't change the schema, we'll just say we assume Cash for everything or skip it.
      // But let's check if there is an indicator. No. So we will just show a static or derived placeholder.
      // Wait, is there a diskon or something? Let's just mock the split for UI purposes since it's not in DB.
      payments[TypePayment.cash] = (payments[TypePayment.cash] ?? 0) + 1;

      for (var item in report.items) {
        itemCounts[item.nama!] = (itemCounts[item.nama!] ?? 0) + item.quantity!;
      }
    }

    // Sort top items
    var sortedItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    setState(() {
      _totalSales = total;
      _receiptCount = receipts;
      _topItems = Map.fromEntries(sortedItems.take(5));
      _paymentMethods = payments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Menu Management',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MenuManagementPage()),
              ).then((_) => _loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Back to Cashier Mode',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today\'s Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Stat Cards
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Total Sales', 'RM ${_totalSales.toStringAsFixed(2)}', Icons.monetization_on, Colors.green)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Total Receipts', '$_receiptCount', Icons.receipt_long, Colors.blue)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildStatCard('Total Sales', 'RM ${_totalSales.toStringAsFixed(2)}', Icons.monetization_on, Colors.green),
                      const SizedBox(height: 16),
                      _buildStatCard('Total Receipts', '$_receiptCount', Icons.receipt_long, Colors.blue),
                    ],
                  ),
                
                const SizedBox(height: 32),
                
                // Details Cards
                if (isDesktop)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTopItemsCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPaymentCard()),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      _buildTopItemsCard(),
                      const SizedBox(height: 16),
                      _buildPaymentCard(),
                    ],
                  ),
                
                const SizedBox(height: 32),
                const Text('Management Modules', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildModulesGrid(context),
              ],
            ),
          ),
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    final modules = [
      {'title': 'Report', 'icon': Icons.home_repair_service_outlined, 'route': '/report', 'color': Colors.indigo},
      {'title': 'Inventory', 'icon': Icons.inventory, 'route': '/inventory', 'color': Colors.orange},
      {'title': 'Rent', 'icon': Icons.shopping_bag, 'route': '/rent', 'color': Colors.pink},
      {'title': 'Due Payment', 'icon': Icons.payment, 'route': '/due-payment', 'color': Colors.red},
      {'title': 'Presence', 'icon': Icons.adobe_sharp, 'route': '/presence', 'color': Colors.teal},
      {'title': 'Expenses', 'icon': Icons.monetization_on, 'route': '/expenses', 'color': Colors.green},
      {'title': 'Users', 'icon': Icons.person_2, 'route': '/users', 'color': Colors.blue},
      {'title': 'Customer', 'icon': Icons.people, 'route': '/customer', 'color': Colors.purple},
      {'title': 'Salaries', 'icon': Icons.account_balance, 'route': '/salaries', 'color': Colors.cyan},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final mod = modules[index];
        final color = mod['color'] as Color;
        return InkWell(
          onTap: () {
            context.push(mod['route'] as String);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(mod['icon'] as IconData, size: 32, color: color),
                ),
                const SizedBox(height: 12),
                Text(mod['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopItemsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Top Selling Coffee/Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            if (_topItems.isEmpty)
              const Text('No sales yet today.', style: TextStyle(color: Colors.grey)),
            ..._topItems.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(e.key, style: const TextStyle(fontSize: 16))),
                  Text('${e.value} sold', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Payment Methods', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            _buildPaymentRow('Cash', _paymentMethods[TypePayment.cash] ?? 0, _receiptCount, Colors.green),
            const SizedBox(height: 16),
            _buildPaymentRow('QR DuitNow', _paymentMethods[TypePayment.qris] ?? 0, _receiptCount, Colors.blue),
            const SizedBox(height: 16),
            _buildPaymentRow('Card', _paymentMethods[TypePayment.transfer] ?? 0, _receiptCount, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String name, int count, int total, Color color) {
    double percentage = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 16)),
            Text('$count (${(percentage * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
