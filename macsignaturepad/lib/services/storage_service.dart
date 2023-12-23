import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static Future<String> uploadPdf(Uint8List pdfBytes, String userId, String fileName) async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child(userId)
        .child('pdfs')
        .child(fileName);

    UploadTask uploadTask = ref.putData(pdfBytes, SettableMetadata(contentType: 'application/pdf'));

    TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

    String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

}
