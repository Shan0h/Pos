import 'dart:convert';

import 'package:isar/isar.dart';

part 'penjualan_model.g.dart';

@collection
class PenjualanModel {
  Id? id = Isar.autoIncrement;
  List<ProductItemModel> items = [];
  late int totalItem;
  late double totalHarga;
  late double diskon;
  late int staffId;
  int? pembeli;
  String? keterangan;
  DateTime createdAt = DateTime.now();
  DateTime? updatedAt;
  bool isDeleted;
  bool isSynced;
  
  // New fields for receipt/report enhancements
  double? tenderedAmount;
  double? changeAmount;
  String? paymentMethod;

  PenjualanModel({
    this.id,
    required this.items,
    required this.totalItem,
    required this.totalHarga,
    required this.diskon,
    required this.staffId,
    this.pembeli,
    this.keterangan,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.isSynced = true,
    this.tenderedAmount,
    this.changeAmount,
    this.paymentMethod,
  });

  factory PenjualanModel.fromJson(json) {
    final rawItems = json['items'];
    final List decodedItems = rawItems is String
        ? (jsonDecode(rawItems) as List)
        : (rawItems as List? ?? const []);
    return PenjualanModel(
      id: json['id'],
      items: decodedItems
          .map((e) => ProductItemModel.fromJson(e))
          .toList(growable: false),
      totalItem: json['totalItem'],
      totalHarga: (json['totalHarga'] as num).toDouble(),
      diskon: (json['diskon'] as num?)?.toDouble() ?? 0,
      staffId: json['staffId'],
      pembeli: json['pembeli'],
      keterangan: json['keterangan'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
      isSynced: json['isSynced'] ?? true,
      tenderedAmount: (json['tenderedAmount'] as num?)?.toDouble(),
      changeAmount: (json['changeAmount'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'items': jsonEncode(items.map((e) => e.toJson()).toList()),
      'totalItem': totalItem,
      'totalHarga': totalHarga,
      'diskon': diskon,
      'staffId': staffId,
      'pembeli': pembeli,
      'keterangan': keterangan,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'isSynced': isSynced,
      'tenderedAmount': tenderedAmount,
      'changeAmount': changeAmount,
      'paymentMethod': paymentMethod,
    };
  }
}

@embedded
class ProductItemModel {
  late int? id;
  late String? nama;
  late String? code;
  late String? deskripsi;
  late int? jumlahBarang;
  late int? quantity;
  late String? ukuran;
  late int? hargaDasar;
  late int? hargaJual;
  double? hargaJualPersen;
  double? diskonPersen;
  late bool? isHargaJualPersen;
  DateTime? barangMasuk;
  DateTime? barangKeluar;
  DateTime? createdAt;
  late bool? isSynced;
  String? category; // 'Menu' or 'Raw Material'

  ProductItemModel({
    this.id,
    this.nama,
    this.code,
    this.deskripsi,
    this.jumlahBarang,
    this.quantity,
    this.ukuran,
    this.hargaDasar,
    this.hargaJual,
    this.hargaJualPersen,
    this.diskonPersen,
    this.isHargaJualPersen,
    this.barangMasuk,
    this.barangKeluar,
    this.createdAt,
    this.isSynced,
    this.category,
  });

  factory ProductItemModel.fromJson(json) {
    return ProductItemModel(
        id: json['id'],
        nama: json['nama'],
        code: json['code'],
        deskripsi: json['deskripsi'],
        jumlahBarang: json['jumlahBarang'],
        quantity: json['quantity'],
        ukuran: json['ukuran'],
        hargaDasar: json['hargaDasar'],
        hargaJual: json['hargaJual'],
        hargaJualPersen: (json['hargaJualPersen'] as num?)?.toDouble(),
        diskonPersen: (json['diskonPersen'] as num?)?.toDouble(),
        isHargaJualPersen: json['isHargaJualPersen'],
        barangMasuk: _parseDate(json['barangMasuk']),
        barangKeluar: _parseDate(json['barangKeluar']),
        createdAt: _parseDate(json['createdAt']),
        isSynced: json['isSynced'],
        category: json['category'],
      )..hargaJualExact = (json['hargaJualExact'] as num?)?.toDouble();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// Sen-precise selling price override (RM). Null = fall back to
  /// whole-Ringgit [hargaJual] legacy field.
  double? hargaJualExact;

  /// Effective selling price used by all charge/display paths.
  double get price => hargaJualExact ?? (hargaJual ?? 0).toDouble();

  ProductItemModel copy() => ProductItemModel(
        id: id,
        nama: nama,
        code: code,
        deskripsi: deskripsi,
        jumlahBarang: jumlahBarang,
        quantity: quantity,
        ukuran: ukuran,
        hargaDasar: hargaDasar,
        hargaJual: hargaJual,
        hargaJualPersen: hargaJualPersen,
        diskonPersen: diskonPersen,
        isHargaJualPersen: isHargaJualPersen,
        barangMasuk: barangMasuk,
        barangKeluar: barangKeluar,
        createdAt: createdAt,
        isSynced: isSynced,
        category: category,
      )..hargaJualExact = hargaJualExact;

  toJson() {
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
      'hargaJualPersen': hargaJualPersen,
      'diskonPersen': diskonPersen,
      'isHargaJualPersen': isHargaJualPersen,
      'barangMasuk': barangMasuk,
      'barangKeluar': barangKeluar,
      'createdAt': createdAt?.toIso8601String(),
      'category': category,
      'hargaJualExact': hargaJualExact,
    };
  }
}
