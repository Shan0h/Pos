class PosProduct {
  final String id;
  final String name;
  final double price;
  final String category;
  final String colorHex;
  final bool isOpenPrice;

  PosProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.colorHex,
    this.isOpenPrice = false,
  });
}

class CartItem {
  final PosProduct product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.price * quantity;
}

final List<String> mockCategories = ['All', 'Food', 'Snacks', 'Drinks', 'Sets'];

final List<PosProduct> mockProducts = [
  PosProduct(
      id: '1',
      name: 'Nasi Lemak Ayam Berempah',
      price: 12.50,
      category: 'Food',
      colorHex: 'FF9800'),
  PosProduct(
      id: '2',
      name: 'Mee Goreng Mamak',
      price: 8.00,
      category: 'Food',
      colorHex: 'FF9800'),
  PosProduct(
      id: '3',
      name: 'Kuey Teow Kerang',
      price: 9.50,
      category: 'Food',
      colorHex: 'FF9800'),
  PosProduct(
      id: '4',
      name: 'Karipap Pusing (3pcs)',
      price: 3.00,
      category: 'Snacks',
      colorHex: '4CAF50'),
  PosProduct(
      id: '5',
      name: 'Pisang Goreng Cheese',
      price: 6.00,
      category: 'Snacks',
      colorHex: '4CAF50'),
  PosProduct(
      id: '6',
      name: 'Teh Tarik Mangkuk',
      price: 3.50,
      category: 'Drinks',
      colorHex: '03A9F4'),
  PosProduct(
      id: '7',
      name: 'Sirap Bandung Cincau',
      price: 4.50,
      category: 'Drinks',
      colorHex: '03A9F4'),
  PosProduct(
      id: '8',
      name: 'Kopi O Ais',
      price: 2.80,
      category: 'Drinks',
      colorHex: '03A9F4'),
  PosProduct(
      id: '9',
      name: 'Set Bestseller A',
      price: 20.00,
      category: 'Sets',
      colorHex: 'E91E63'),
  PosProduct(
      id: '10',
      name: 'Nasi Campur (Buka Harga)',
      price: 0.00,
      category: 'Food',
      colorHex: 'FF9800',
      isOpenPrice: true),
  PosProduct(
      id: '11',
      name: 'Keropok Lekor',
      price: 5.00,
      category: 'Snacks',
      colorHex: '4CAF50'),
  PosProduct(
      id: '12',
      name: 'Milo Dinosaur',
      price: 6.50,
      category: 'Drinks',
      colorHex: '03A9F4'),
];
