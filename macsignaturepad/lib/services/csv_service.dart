import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../secrets/secrets.dart';
import 'firebase_service.dart';

class CSVService {
  static Future getCSV() async {
    try {
      Response response = await Dio().get(
        FirebaseService.getUri('getAllUsers').toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $FUNCTIONS_KEY',
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        _createDownloadLink(response.data);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  static void _createDownloadLink(Uint8List data) {
    final blob = html.Blob([data]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "mac_signature.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
