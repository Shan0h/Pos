import 'package:flutter/material.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/utils/extension.dart';

/// Category used for legacy/uncategorized menu items.
const posOthersCategory = 'Others';

/// Stable color per menu category (hash-based but constrained to a
/// pleasant, readable palette instead of random 24-bit colors).
Color categoryColor(String category) {
  const palette = <Color>[
    Color(0xFF8B5E3C), // coffee brown
    Color(0xFFA0522D), // sienna
    Color(0xFF6B8E23), // olive
    Color(0xFF2E7D32), // green
    Color(0xFFB5651D), // caramel
    Color(0xFF7B4B94), // plum
    Color(0xFF2F6690), // blue
    Color(0xFFC0392B), // red
    Color(0xFF0F766E), // teal-dark
    Color(0xFF946B2D), // gold-brown
  ];
  return palette[category.hashCode.abs() % palette.length];
}

class CatalogPanel extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<ItemModel> products;
  final ValueChanged<ItemModel> onProductTap;
  final List<String> categories;
  final bool showCategoryRail;

  const CatalogPanel({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.products,
    required this.onProductTap,
    required this.categories,
    this.showCategoryRail = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = context.appTextColor;
    return Container(
      color: context.pageBackground,
      child: Column(
        children: [
          // Header & Search
          Container(
            padding: const EdgeInsets.all(16.0),
            color: context.panelBackground,
            child: Row(
              children: [
                Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: searchQuery)
                      ..selection =
                          TextSelection.collapsed(offset: searchQuery.length),
                    onChanged: onSearchChanged,
                    style: TextStyle(color: context.appTextColor),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: context.secondaryTextColor),
                      prefixIcon: Icon(Icons.search,
                          color: const Color(0xFF8B5E3C)),
                      // Clear button: only shown when there is text.
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: context.secondaryTextColor),
                              onPressed: () => onSearchChanged(''),
                              tooltip: 'Clear',
                            )
                          : null,
                      filled: true,
                      fillColor: context.mutedBackground,
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

          // Products Grid (chips move to the left rail on wide tablets)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCategoryRail)
                  _CategoryRail(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    onCategorySelected: onCategorySelected,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (!showCategoryRail && categories.isNotEmpty)
                        _CategoryChips(
                          categories: categories,
                          selectedCategory: selectedCategory,
                          onCategorySelected: onCategorySelected,
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: products.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.search_off,
                                          size: 48,
                                          color: context.secondaryTextColor),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No products found',
                                        style: TextStyle(
                                            color: context.appTextColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Try a different search.',
                                        style: TextStyle(
                                            color:
                                                context.secondaryTextColor),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          final catColor = cat == 'All' || cat == posOthersCategory
              ? const Color(0xFF8B5E3C)
              : categoryColor(cat);
          return ChoiceChip(
            label: Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.white : context.appTextColor,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: catColor,
            backgroundColor: context.panelBackground,
            side: BorderSide(color: context.borderColor),
            onSelected: (selected) {
              if (selected) onCategorySelected(cat);
            },
          );
        },
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategoryRail({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      color: context.panelBackground,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final cat in categories)
            InkWell(
              onTap: () => onCategorySelected(cat),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: cat == selectedCategory
                      ? const Color(0xFF8B5E3C).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: cat == selectedCategory
                      ? Border.all(color: const Color(0xFF8B5E3C))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cat == 'All' || cat == posOthersCategory
                            ? const Color(0xFF8B5E3C)
                            : categoryColor(cat),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: cat == selectedCategory
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: cat == selectedCategory
                              ? const Color(0xFF8B5E3C)
                              : context.appTextColor,
                        ),
                      ),
                    ),
                  ],
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
    final color = product.menuCategory == null || product.menuCategory!.trim().isEmpty
        ? const Color(0xFF8B5E3C)
        : categoryColor(product.menuCategory!);
    final isOutOfStock = product.jumlahBarang == 0;

    return InkWell(
      onTap: isOutOfStock ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isOutOfStock ? 0.5 : 1.0,
        child: Container(
        decoration: BoxDecoration(
          color: context.panelBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.appShadowColor,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.appTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.price == 0
                        ? 'Open Price'
                        : 'RM ${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.isDarkMode
                          ? const Color(0xFFD7A86E)
                          : const Color(0xFF8B5E3C),
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
