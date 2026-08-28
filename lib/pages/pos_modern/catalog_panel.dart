import 'package:flutter/material.dart';
import 'package:pos/model/item_model.dart';

class CatalogPanel extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<ItemModel> products;
  final ValueChanged<ItemModel> onProductTap;
  final ValueChanged<String> onBarcodeScanned;
  final List<String> categories;

  const CatalogPanel({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.products,
    required this.onProductTap,
    required this.onBarcodeScanned,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Header & Search
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    onSubmitted: (value) {
                      onBarcodeScanned(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search or Scan Barcode...',
                      prefixIcon: const Icon(Icons.qr_code_scanner, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Choice Chips
          if (categories.isNotEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == selectedCategory;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.teal,
                    backgroundColor: Colors.white,
                    onSelected: (selected) {
                      if (selected) onCategorySelected(cat);
                    },
                  );
                },
              ),
            ),
          // Products Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => onProductTap(product),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ItemModel product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Generate a pseudo-random color based on the item code or name
    final colorHash = product.nama.hashCode;
    final color = Color((colorHash & 0xFFFFFF) | 0xFF000000).withValues(alpha: 0.8);
    final isOutOfStock = product.jumlahBarang == 0;

    return InkWell(
      onTap: isOutOfStock ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isOutOfStock ? 0.5 : 1.0,
        child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Color Strip for category
            Container(
              height: 8,
              color: color,
            ),
            // Product Initial Placeholder
            Expanded(
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      product.nama.isNotEmpty ? product.nama[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.hargaJual == 0 
                        ? 'Open Price'
                        : 'RM ${product.hargaJual.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                  if (isOutOfStock)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text('OUT OF STOCK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
