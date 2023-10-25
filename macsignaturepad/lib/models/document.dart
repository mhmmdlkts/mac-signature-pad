import 'package:cloud_firestore/cloud_firestore.dart';

class Document {
  String customerId;
  String name;
  String detail;
  String? sign;
  Timestamp ts;

  Document({
    required this.customerId,
    required this.name,
    required this.detail,
    required this.ts,
    this.sign
  });

  factory Document.fromJson(Map<String, dynamic> json, String customerId) {
    return Document(
      customerId: customerId,
      name: json['name'],
      detail: json['detail'],
      ts: json['ts'],
      sign: json['sign']
    );
  }
}