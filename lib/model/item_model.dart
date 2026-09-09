import 'package:isar/isar.dart';

part 'item_model.g.dart';

@collection
class ItemModel {
  Id? id = Isar.autoIncrement;
  String nama;
  String code;
  String? deskripsi;
  int jumlahBarang;
  int quantity;
  String ukuran;
  int hargaDasar;
  int hargaJual;
  double? hargaJualPersen;
  double? diskonPersen;
  bool isHargaJualPersen;
  DateTime? barangMasuk;
  DateTime? barangKeluar;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool isDeleted;
  bool isSynced;
  String? category; // 'Menu' or 'Raw Material'
  String? customizationsJson; // JSON string for dynamic customizations (Size, Sugar, Add-ons)

  /// Cafe-facing menu category (e.g. Coffee, Tea, Food). Null for raw
  /// materials and legacy rows (shown as "Others" in the POS catalog).
  String? menuCategory;

  /// Sen-precise selling price override (RM). Null = fall back to the
  /// whole-Ringgit legacy [hargaJual] field.
  double? hargaJualExact;

  /// Effective selling price used by all charge/display paths.
  double get price => hargaJualExact ?? hargaJual.toDouble();

  ItemModel({
    this.id,
    required this.nama,
    required this.code,
    this.deskripsi,
    required this.jumlahBarang,
    required this.quantity,
    required this.ukuran,
    required this.hargaDasar,
    required this.hargaJual,
    this.hargaJualExact,
    this.hargaJualPersen,
    this.diskonPersen,
    required this.isHargaJualPersen,
    this.barangMasuk,
    this.barangKeluar,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.isSynced = true,
    this.category,
    this.customizationsJson,
    this.menuCategory,
  });

  ItemModel copy() => ItemModel(
        id: id,
        nama: nama,
        code: code,
        deskripsi: deskripsi,
        jumlahBarang: jumlahBarang,
        quantity: quantity,
        ukuran: ukuran,
        hargaDasar: hargaDasar,
        hargaJual: hargaJual,
        hargaJualExact: hargaJualExact,
        hargaJualPersen: hargaJualPersen,
        diskonPersen: diskonPersen,
        isHargaJualPersen: isHargaJualPersen,
        barangMasuk: barangMasuk,
        barangKeluar: barangKeluar,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isDeleted: isDeleted,
        isSynced: isSynced,
        category: category,
        customizationsJson: customizationsJson,
        menuCategory: menuCategory,
      );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nama': nama,
      'code': code,
      'deskripsi': deskripsi,
      'jumlahBarang': jumlahBarang,
      'quantity': quantity,
      'ukuran': ukuran,
      'hargaDasar': hargaDasar,
      'hargaJual': hargaJual,
      'hargaJualExact': hargaJualExact,
      'hargaJualPersen': hargaJualPersen,
      'diskonPersen': diskonPersen,
      'isHargaJualPersen': isHargaJualPersen,
      'barangMasuk': barangMasuk?.toIso8601String(),
      'barangKeluar': barangKeluar?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'isSynced': isSynced,
      'category': category,
      'customizationsJson': customizationsJson,
      'menuCategory': menuCategory,
    };
  }

  factory ItemModel.fromJson(json) {
    return ItemModel(
      id: json['id'],
      nama: json['nama'],
      code: json['code'],
      deskripsi: json['deskripsi'] != null ? json['deskripsi'] as String : null,
      jumlahBarang: json['jumlahBarang'],
      quantity: json['quantity'],
      ukuran: json['ukuran'],
      hargaDasar: json['hargaDasar'],
      hargaJual: json['hargaJual'],
      hargaJualExact: (json['hargaJualExact'] as num?)?.toDouble(),
      hargaJualPersen: json['hargaJualPersen']?.toDouble(),
      diskonPersen: json['diskonPersen']?.toDouble(),
      isHargaJualPersen: json['isHargaJualPersen'],
      barangMasuk: json['barangMasuk'] != null
          ? DateTime.parse(json['barangMasuk'])
          : null,
      barangKeluar: json['barangKeluar'] != null
          ? DateTime.parse(json['barangKeluar'])
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isDeleted: json['isDeleted'] ?? false,
      isSynced: json['isSynced'] ?? true,
      category: json['category'],
      customizationsJson: json['customizationsJson'],
      menuCategory: json['menuCategory'],
    );
  }
}
