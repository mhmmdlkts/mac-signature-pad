import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/advisor_service.dart';
import '../services/firestore_paths_service.dart';

class Signature implements Comparable {

  static const int warnDay = 45;

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
  late bool advisorDownloaded;
  late bool officeDownloaded;

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
    required this.advisorDownloaded,
    required this.officeDownloaded,
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
    advisorDownloaded: json['advisorDownloaded']??false,
    officeDownloaded: json['officeDownloaded']??false,
  );

  Color get bprotokollExpiresDateColor => _getColorByDate(bprotokollExp);
  Color get vollmachtExpiresDateColor => _getColorByDate(vollmachtExp);
  String get readableExpBprotokoll => DateFormat('dd.MM.yyyy').format(bprotokollExp.toDate());
  String get readableExpVollmacht => DateFormat('dd.MM.yyyy').format(vollmachtExp.toDate());

  Color _getColorByDate(Timestamp? date) {
    if (date == null || date.toDate().isBefore(DateTime.now())) return Colors.red;
    if (date.toDate().isBefore(DateTime.now().add(const Duration(days: warnDay)))) return Colors.orange;
    return Colors.green;
  }

  DateTime get expiresDate => vollmachtExp.toDate().isAfter(bprotokollExp.toDate())?vollmachtExp.toDate():bprotokollExp.toDate();

  @override
  int compareTo(other) {
    if (other is! Signature) return 0;
    if (isDownloaded && !other.isDownloaded) return 1;
    if (!isDownloaded && other.isDownloaded) return -1;
    return expiresDate.compareTo(other.expiresDate);
  }

  bool get isDownloaded {
    if (AdvisorService.isOffice) {
      return officeDownloaded;
    } else {
      if (advisorId == AdvisorService.advisor?.id) {
        return advisorDownloaded;
      }
      return true;
    }
  }

  Future<bool> setIsDownloaded(customerId) async {
    if (AdvisorService.isOffice) {
      if (officeDownloaded) return false;
      officeDownloaded = true;
      await FirestorePathsService.getSignatureDoc(customerId: customerId, signatureId: id).update({
        'officeDownloaded': true,
      });
      return true;
    } else {
      if (advisorDownloaded) return false;
      advisorDownloaded = true;
      await FirestorePathsService.getSignatureDoc(customerId: customerId, signatureId: id).update({
        'advisorDownloaded': true,
      });
      return true;
    }
  }
}