import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:macsignaturepad/models/customer.dart';
import 'firebase_service.dart';

const currentBprotokollVersion = 'v1';
const currentVollmachtVersion = 'v1';

class PdfService {

  static Uint8List? _vollmachtPdfBytes;
  static Uint8List? _beratungsprotokollPdfBytes;
  static Future<Map<String, dynamic>> createBeratungsprotokolPDF({required Customer customer, required String? signature, required String version}) async {
    if (_beratungsprotokollPdfBytes != null) {
      return {
        "success": true,
        "error": "",
        "counter": 0,
        "data": _beratungsprotokollPdfBytes
      };
    }

    Response response = await Dio().post(
      FirebaseService.getUri('getPdf').toString(),
      data: {
        "token": customer.token,
        "customer_id": customer.id,
        "pdf_name": "protokoll_$version"
      },
    );


    if (response.statusCode == 200) {
      Uint8List pdfBytes = base64Decode(response.data["base64Pdf"]);
      _beratungsprotokollPdfBytes = pdfBytes;
      return {
        "success": true,
        "error": "",
        "counter": 0,
        "data": pdfBytes
      };
    }
    else {
      return {
        "success": false,
        "error": "response.statusCode: ${response.statusCode}",
        "counter": 0,
        "data": null
      };
    }
  }

  static Future<Map<String, dynamic>> createVollmachtPDF({required Customer customer, String? signature, required String version}) async {
    if (_vollmachtPdfBytes != null) {
      return {
        "success": true,
        "error": "",
        "counter": 0,
        "data": _vollmachtPdfBytes
      };
    }

    Response response = await Dio().post(
      FirebaseService.getUri('getPdf').toString(),
      data: {
        "token": customer.token,
        "customer_id": customer.id,
        "pdf_name": "vollmacht_$version"
      },
    );


    if (response.statusCode == 200) {
      Uint8List pdfBytes = base64Decode(response.data["base64Pdf"]);
      _vollmachtPdfBytes = pdfBytes;
      return {
        "success": true,
        "error": "",
        "counter": 0,
        "data": pdfBytes
      };
    }
    else {
      return {
        "success": false,
        "error": "response.statusCode: ${response.statusCode}",
        "counter": 0,
        "data": null
      };
    }
  }
}