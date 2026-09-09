import 'package:isar/isar.dart';

part 'salary_model.g.dart';

@collection
class SalaryModel {
  Id? id = Isar.autoIncrement;
  int userId;
  String status;
  String periode;
  List<ItemSalary> items;
  List<ItemSalary>? deductions;
  int? total;
  String? note;
  String? management;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool isDeleted;
  bool isSynced;

  SalaryModel({
    this.id,
    required this.userId,
    required this.status,
    required this.periode,
    required this.items,
    this.deductions,
    required this.total,
    this.note,
    this.management,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.isSynced = true,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'status': status,
      'periode': periode,
      'items': items,
      'deductions': deductions,
      'total': total,
      'note': note,
      'management': management,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'isSynced': isSynced,
    };
  }

  factory SalaryModel.fromJson(json) {
    return SalaryModel(
      id: json['id'],
      userId: json['userId'],
      status: json['status'],
      periode: json['periode'],
      items: json['items'],
      deductions: json['deductions'],
      total: json['total'],
      note: json['note'],
      management: json['management'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isDeleted: json['isDeleted'] ?? false,
      isSynced: json['isSynced'] ?? true,
    );
  }
}

@embedded
class ItemSalary {
  int? id;
  String? description;
  String? amount;

  ItemSalary({
    this.id,
    this.description,
    this.amount,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'description': description,
      'amount': amount,
    };
  }

  factory ItemSalary.fromJson(json) {
    return ItemSalary(
      id: json['id'],
      description: json['description'],
      amount: json['amount'],
    );
  }
}
