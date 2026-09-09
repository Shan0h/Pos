import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/enum/payment_enum.dart';
import 'package:pos/utils/extension.dart';
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
    final reports = await reportService.getReportToday();
    
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

      final method = TypePayment.values.firstWhere(
        (value) => value.name == report.paymentMethod,
        orElse: () => TypePayment.cash,
      );
      payments[method] = (payments[method] ?? 0) + 1;

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
    final textColor = context.appTextColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: const Color(0xFF5D3A1A),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            tooltip: 'Database Settings',
            onSelected: (item) async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              if (item == 'backup') {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Backing up database...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                
                bool success = await database.createBackUp();
                
                if (context.mounted) Navigator.pop(context); // close dialog
                
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Backup Success! Data saved to selected folder.'), backgroundColor: Colors.green),
                  );
                }
              } else if (item == 'restore') {
                bool success = await database.restoreDB();
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Restore Success! Restart app to see changes.'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'backup',
                child: Row(
                  children: [Icon(Icons.save, color: Colors.black54), SizedBox(width: 8), Text('Backup Config / DB')],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'restore',
                child: Row(
                  children: [Icon(Icons.restore, color: Colors.black54), SizedBox(width: 8), Text('Restore Config / DB')],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Back to Cashier Mode',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      backgroundColor: context.pageBackground,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s Overview', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Stat Cards
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Total Sales', 'RM ${_totalSales.toStringAsFixed(2)}', Icons.monetization_on, const Color(0xFF8B5E3C))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Total Receipts', '$_receiptCount', Icons.receipt_long, const Color(0xFF6B4226))),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildStatCard('Total Sales', 'RM ${_totalSales.toStringAsFixed(2)}', Icons.monetization_on, const Color(0xFF8B5E3C)),
                      const SizedBox(height: 16),
                      _buildStatCard('Total Receipts', '$_receiptCount', Icons.receipt_long, const Color(0xFF6B4226)),
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
                Text('Management Modules', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildModulesGrid(context),
              ],
            ),
          ),
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    final modules = [
      {'title': 'Store Info', 'icon': Icons.store, 'route': '/store', 'color': const Color(0xFF8B5E3C)},
      {'title': 'Report', 'icon': Icons.home_repair_service_outlined, 'route': '/report', 'color': const Color(0xFF6B4226)},
      {'title': 'Inventory', 'icon': Icons.inventory, 'route': '/inventory', 'color': const Color(0xFFA0522D)},
      {'title': 'Expenses', 'icon': Icons.monetization_on, 'route': '/expenses', 'color': const Color(0xFF5D3A1A)},
      {'title': 'Users', 'icon': Icons.person_2, 'route': '/users', 'color': const Color(0xFF7B5B3A)},
      {'title': 'Customer', 'icon': Icons.people, 'route': '/customer', 'color': const Color(0xFF9C6634)},
      {'title': 'Salaries', 'icon': Icons.account_balance, 'route': '/salaries', 'color': const Color(0xFF6B4226)},
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
              color: context.panelBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: context.appShadowColor, blurRadius: 10, offset: const Offset(0, 4))],
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
                Text(mod['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextColor)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopItemsCard() {
    return Card(
      color: context.panelBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Top Selling Coffee/Items', style: TextStyle(color: context.appTextColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            if (_topItems.isEmpty)
              Text('No sales yet today.', style: TextStyle(color: context.secondaryTextColor)),
            ..._topItems.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(e.key, style: TextStyle(color: context.appTextColor, fontSize: 16))),
                  Text('${e.value} sold', style: TextStyle(color: context.appTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
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
      color: context.panelBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Payment Methods', style: TextStyle(color: context.appTextColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            _buildPaymentRow('Cash', _paymentMethods[TypePayment.cash] ?? 0, _receiptCount, const Color(0xFF8B5E3C)),
            const SizedBox(height: 16),
            _buildPaymentRow('QR DuitNow', _paymentMethods[TypePayment.qris] ?? 0, _receiptCount, const Color(0xFF6B4226)),
            const SizedBox(height: 16),
            _buildPaymentRow('Card', _paymentMethods[TypePayment.transfer] ?? 0, _receiptCount, const Color(0xFFA0522D)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: context.panelBackground,
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.secondaryTextColor,
                  ),
                ),
                Text(value, style: TextStyle(color: context.appTextColor, fontSize: 32, fontWeight: FontWeight.bold)),
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
            Text(name, style: TextStyle(color: context.appTextColor, fontSize: 16)),
            Text('$count (${(percentage * 100).toStringAsFixed(1)}%)', style: TextStyle(color: context.appTextColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: context.mutedBackground,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
