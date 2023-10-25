import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Signature {
  late String id;
  late String signature;
  late String advisorName;
  late String advisorId;
  late String vollmachtVersion;
  late String bprotokollVersion;
  late String bprotokollPdfUrl;
  late String vollmachtPdfUrl;
  late Timestamp signedAt;
  late Timestamp vollmachtExp;
  late Timestamp bprotokollExp;

  Signature({
    required this.id,
    required this.signature,
    required this.advisorName,
    required this.advisorId,
    required this.vollmachtVersion,
    required this.bprotokollVersion,
    required this.bprotokollPdfUrl,
    required this.vollmachtPdfUrl,
    required this.signedAt,
    required this.vollmachtExp,
    required this.bprotokollExp,
  });

  factory Signature.fromJson(Map<String, dynamic> json, String id) => Signature(
    id: id,
    signature: json['signature'],
    advisorName: json['advisorName'],
    advisorId: json['advisorId'],
    vollmachtVersion: json['vollmachtVersion'],
    bprotokollVersion: json['bprotokollVersion'],
    bprotokollPdfUrl: json['bprotokollPdfUrl'],
    vollmachtPdfUrl: json['vollmachtPdfUrl'],
    signedAt: json['signedAt'],
    vollmachtExp: json['vollmachtExp'],
    bprotokollExp: json['bprotokollExp'],
  );



  Color get bprotokollExpiresDateColor => _getColorByDate(bprotokollExp);
  Color get vollmachtExpiresDateColor => _getColorByDate(vollmachtExp);
  String get readableExpBprotokoll => bprotokollExp==null?'----------':DateFormat('dd.MM.yyyy').format(bprotokollExp!.toDate());
  String get readableExpVollmacht => vollmachtExp==null?'----------':DateFormat('dd.MM.yyyy').format(vollmachtExp!.toDate());

  Color _getColorByDate(Timestamp? date) {
    if (date == null || date.toDate().isBefore(DateTime.now())) return Colors.red;
    if (date.toDate().isBefore(DateTime.now().add(const Duration(days: 30)))) return Colors.orange;
    return Colors.green;
  }
}