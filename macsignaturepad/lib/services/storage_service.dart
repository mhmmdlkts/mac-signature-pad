import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static Future<String> uploadPdf(Uint8List pdfBytes, String userId, String fileName) async {
    // Create a Reference to the file
    Reference ref = FirebaseStorage.instance
        .ref()
        .child(userId)
        .child('pdfs')
        .child(fileName);

    // Start upload of the PDF file
    UploadTask uploadTask = ref.putData(pdfBytes, SettableMetadata(contentType: 'application/pdf'));

    // Wait for the upload to complete
    TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

    // Get the download URL
    String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

}
