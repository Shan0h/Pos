import 'package:isar/isar.dart';

part 'store_model.g.dart';

@collection
class StoreModel {
  Id? id = Isar.autoIncrement;
  late String title;
  late String description;
  late String phone;
  String? footer;
  String? subFooter;
  String? ownerPin;
  String? qrDuitNow1;
  String? qrDuitNow2;

  StoreModel({
    this.id,
    required this.title,
    required this.description,
    required this.phone,
    this.footer,
    this.subFooter,
    this.ownerPin,
    this.qrDuitNow1,
    this.qrDuitNow2,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'phone': phone,
      'footer': footer,
      'subFooter': subFooter,
      'ownerPin': ownerPin,
      'qrDuitNow1': qrDuitNow1,
      'qrDuitNow2': qrDuitNow2,
    };
  }

  factory StoreModel.fromJson(json) {
    return StoreModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      phone: json['phone'],
      footer: json['footer'],
      subFooter: json['subFooter'],
      ownerPin: json['ownerPin'],
      qrDuitNow1: json['qrDuitNow1'],
      qrDuitNow2: json['qrDuitNow2'],
    );
  }
}
