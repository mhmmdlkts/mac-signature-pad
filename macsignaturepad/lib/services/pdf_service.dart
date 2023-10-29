import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:macsignaturepad/models/customer.dart';
import 'package:macsignaturepad/services/placeholder_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';

import '../models/service_details.dart';

const List<String> _versionHistoryBprotokoll = ['v1'];
const List<String> _versionHistoryVollmacht = ['v1'];
const currentBprotokollVersion = 'v1';
const currentVollmachtVersion = 'v1';

class PdfService {
  static Future<Uint8List> createBeratungsprotokolPDF({required Customer customer, required String? signature, required String version}) async {
    if (!_versionHistoryBprotokoll.contains(version)) {
      throw Exception('Version $version not supported');
    }
    final ByteData data = await rootBundle.load('assets/protokoll_$version.pdf');
    final PdfDocument document = PdfDocument(inputBytes: data.buffer.asUint8List(), conformanceLevel: PdfConformanceLevel.a3b);

    //return Uint8List.fromList([]);
    String now = DateFormat('dd.MM.yyyy').format(DateTime.now());

    Map<String, dynamic> dataMap = {
      'name': {
        'val': '${customer.name} ${customer.surname}',
        'type': 'text',
      },
      'phone_email': {
        'val': '${customer.getReadablePhone??''} / ${customer.getReadableEmail??''}',
        'type': 'text',
      },
      'uid_stnr': {
        'val': '${customer.getReadableUid??''} / ${customer.getReadableStnr??''}',
        'type': 'text',
      },
      'birthdate': {
        'val': customer.readableBirthdate,
        'type': 'text',
      },
      'next_termin': {
        'val': customer.readableNextTermin,
        'type': 'text',
      },
      'advisor_name': {
        'val': customer.advisorName,
        'type': 'text',
      },
      'signature_name': {
        'val': '${customer.name} ${customer.surname}',
        'type': 'text',
        'align': 'center'
      },
      'city_date_customer': {
        'val': '${customer.city}, $now',
        'type': 'text',
        'align': 'center'
      },
      'city_date_company': {
        'val': 'Villach, $now',
        'type': 'text',
        'align': 'center'
      },
      'address': {
        'val': customer.readableAddress,
        'type': 'text'
      },
      'date': {
        'val': now,
        'type': 'text'
      },
      'signature': {
        'val': signature,
        'type': 'base64Image',
      },
    };

    for (var element in customer.details??[]) {
      if (element.status == 0) {
        dataMap['${element.code}-yes'] = {
          'val': 'x',
          'type': 'text',
          'align': 'center'
        };
      }
      if (element.status == 1) {
        dataMap['${element.code}-no'] = {
          'val': 'x',
          'type': 'text',
          'align': 'center'
        };
      }
      if (element.status == 2) {
        dataMap['${element.code}-change'] = {
          'val': 'x',
          'type': 'text',
          'align': 'center'
        };
      }
      if (element.notes != null && element.notes!.isNotEmpty) {
        dataMap['${element.code}-note'] = {
          'val': element.notes??'Test Note',
          'type': 'text',
        };
      }
    }

    // /?token=1698394976264000uYnaXnRfqDaGUPbwUuawbLwy#/sign

    final Map<String, List<Map<String, dynamic>>> metadata = PlaceholdersService.getPlaceholders('protokoll', version);

    metadata.forEach((key, v) {
      for (var value in v) {
        final int pageIndex = value['page'];
        final double keyLeft = value['x'];
        final double keyTop =  value['y'];
        final double keyWidth = value['width'];
        final double keyHeight = value['height'];

        final PdfPage page = document.pages[pageIndex];
        bool isCentered = dataMap[key]?['align'] == 'center';
        String val = dataMap[key]?['val']??'';
        String type = dataMap[key]?['type']??'';

        if (type == 'text') {
          // print(val);
          PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
          double textWidth = font.measureString(val).width;

          double x = isCentered ? keyLeft + (keyWidth - textWidth) / 2 : keyLeft;
          double y = keyTop + (keyHeight - font.height) / 2;

          page.graphics.drawString(
            val,
            font,
            brush: PdfSolidBrush(PdfColor(0, 0, 0)),
            bounds: Rect.fromLTWH(x, y, 0, 0),
          );
        } else if (type == 'base64Image' && val != null && val.isNotEmpty) {
          double width = 180;
          double height = width/2;
          double x = keyLeft + (keyWidth - width) / 2;
          double y = keyTop + (keyHeight - height) / 2;
          // Konvertieren Sie den Base64-String in ein Uint8List-Objekt.
          Uint8List imageBytes = base64.decode(val);

          // Laden Sie das Bild mit der PdfBitmap-Klasse.
          PdfBitmap image = PdfBitmap(imageBytes);

          // Zeichnen Sie das Bild auf der PDF-Seite.
          page.graphics.drawImage(
            image,
            Rect.fromLTWH(x, y, width, height),
          );
        }

      }
    });

    List<int> bytes = await document.save();

    document.dispose();

    return Uint8List.fromList(bytes);
  }

  static Future<Uint8List> createVollmachtPDF({required Customer customer, String? signature, required String version}) async {
    if (!_versionHistoryVollmacht.contains(version)) {
      throw Exception('Version $version not supported');
    }
    final ByteData data = await rootBundle.load('assets/vollmacht_$version.pdf');
    final PdfDocument document = PdfDocument(inputBytes: data.buffer.asUint8List());
    String now = DateFormat('dd.MM.yyyy').format(DateTime.now());

    Map<String, dynamic> dataMap = {
      'name': {
        'val': '${customer.name} ${customer.surname}',
        'type': 'text',
      },
      'phone_email': {
        'val': '${customer.getReadablePhone??''} / ${customer.getReadableEmail??''}',
        'type': 'text',
      },
      'uid_stnr': {
        'val': '${customer.getReadableUid??''} / ${customer.getReadableStnr??''}',
        'type': 'text',
      },
      'birthdate': {
        'val': customer.readableBirthdate,
        'type': 'text',
      },
      'signature_name': {
        'val': '${customer.name} ${customer.surname}',
        'type': 'text',
        'align': 'center'
      },
      'city_date_customer': {
        'val': '${customer.city}, $now',
        'type': 'text',
        'align': 'center'
      },
      'city_date_company': {
        'val': 'Villach, $now',
        'type': 'text',
        'align': 'center'
      },
      'address': {
        'val': customer.readableAddress,
        'type': 'text'
      },
      'date': {
        'val': now,
        'type': 'text'
      },
      'signature': {
        'val': signature,
        'type': 'base64Image',
      },
    };
    final Map<String, List<Map<String, dynamic>>> metadata = PlaceholdersService.getPlaceholders('vollmacht', version);

    metadata.forEach((key, v) {
      for (var value in v) {
        final int pageIndex = value['page'];
        final double keyLeft = value['x'];
        final double keyTop =  value['y'];
        final double keyWidth = value['width'];
        final double keyHeight = value['height'];

        final PdfPage page = document.pages[pageIndex];
        bool isCentered = dataMap[key]?['align'] == 'center';
        String val = dataMap[key]?['val']??'';
        String type = dataMap[key]?['type']??'';

        if (type == 'text') {
          // print(val);
          PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
          double textWidth = font.measureString(val).width;

          double x = isCentered ? keyLeft + (keyWidth - textWidth) / 2 : keyLeft;
          double y = keyTop + (keyHeight - font.height) / 2;

          page.graphics.drawString(
            val,
            font,
            brush: PdfSolidBrush(PdfColor(0, 0, 0)),
            bounds: Rect.fromLTWH(x, y, 0, 0),
          );
        } else if (type == 'base64Image' && val != null && val.isNotEmpty) {
          double width = 180;
          double height = width/2;
          double x = keyLeft + (keyWidth - width) / 2;
          double y = keyTop + (keyHeight - height) / 2;
          // Konvertieren Sie den Base64-String in ein Uint8List-Objekt.
          Uint8List imageBytes = base64.decode(val);

          // Laden Sie das Bild mit der PdfBitmap-Klasse.
          PdfBitmap image = PdfBitmap(imageBytes);

          // Zeichnen Sie das Bild auf der PDF-Seite.
          page.graphics.drawImage(
            image,
            Rect.fromLTWH(x, y, width, height),
          );
        }

      }
    });

    List<int> bytes = await document.save();

    document.dispose();

    return Uint8List.fromList(bytes);
  }
}