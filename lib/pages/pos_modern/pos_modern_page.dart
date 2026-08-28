import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mock_data.dart';
import 'catalog_panel.dart';
import 'ticket_panel.dart';
import 'price_numpad_dialog.dart';

class PosModernPage extends StatefulWidget {
  const PosModernPage({super.key});

  @override
  State<PosModernPage> createState() => _PosModernPageState();
}

class _PosModernPageState extends State<PosModernPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<CartItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    // Lock to landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    // Reset to any orientation when leaving (if preferred)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  List<PosProduct> get _filteredProducts {
    return mockProducts.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _handleProductTap(PosProduct product) async {
    double itemPrice = product.price;

    if (product.isOpenPrice) {
      final enteredPrice = await PriceNumpadDialog.show(
        context,
        itemName: product.name,
      );
      
      if (enteredPrice == null || enteredPrice <= 0) {
        return; // User canceled or entered invalid price
      }
      itemPrice = enteredPrice;
    }

    setState(() {
      if (product.isOpenPrice) {
        // Open price items are treated as separate line items
        final customProduct = PosProduct(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID for each open price item
          name: product.name,
          price: itemPrice,
          category: product.category,
          colorHex: product.colorHex,
          isOpenPrice: true,
        );
        _cartItems.add(CartItem(product: customProduct));
      } else {
        final existingItemIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
        if (existingItemIndex >= 0) {
          _cartItems[existingItemIndex].quantity++;
        } else {
          _cartItems.add(CartItem(product: product));
        }
      }
    });
  }

  void _handleIncrement(CartItem item) {
    setState(() {
      item.quantity++;
    });
  }

  void _handleDecrement(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cartItems.removeWhere((i) => i.product.id == item.product.id);
      }
    });
  }

  void _handleClear() {
    setState(() {
      _cartItems.clear();
    });
  }

  void _handlePay() {
    // Handle payment logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment processed successfully!'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
    _handleClear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern POS'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Row(
          children: [
            // Left Side: Catalog Panel (flex: 7)
            Expanded(
              flex: 7,
              child: CatalogPanel(
                searchQuery: _searchQuery,
                onSearchChanged: (query) => setState(() => _searchQuery = query),
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) => setState(() => _selectedCategory = category),
                products: _filteredProducts,
                onProductTap: _handleProductTap,
              ),
            ),
            
            // Right Side: Ticket Panel (flex: 5)
            Expanded(
              flex: 5,
              child: TicketPanel(
                cartItems: _cartItems,
                onClear: _handleClear,
                onIncrement: _handleIncrement,
                onDecrement: _handleDecrement,
                onPay: _handlePay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
