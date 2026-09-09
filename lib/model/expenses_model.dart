import 'package:isar/isar.dart';

part 'expenses_model.g.dart';

@collection
class ExpensesModel {
  Id? id = Isar.autoIncrement;
  String title;
  String? note;
  int amount;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool isDeleted;
  bool isSynced;

  ExpensesModel({
    this.id,
    required this.title,
    this.note,
    required this.amount,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.isSynced = true,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'note': note,
      'amount': amount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'isSynced': isSynced,
    };
  }

  factory ExpensesModel.fromJson(json) {
    return ExpensesModel(
      id: json['id'],
      title: json['title'],
      note: json['note'] != null ? json['note'] as String : null,
      amount: json['amount'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isDeleted: json['isDeleted'] ?? false,
      isSynced: json['isSynced'] ?? true,
    );
  }
}
