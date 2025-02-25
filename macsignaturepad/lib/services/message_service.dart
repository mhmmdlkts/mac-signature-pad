import 'package:dio/dio.dart';
import 'package:macsignaturepad/models/customer.dart';
import 'package:macsignaturepad/services/firestore_paths_service.dart';

import '../models/message_request.dart';
import '../secrets/secrets.dart';
import 'firebase_service.dart';

class MessageService {
  static final Map<Customer, bool> allCustomers = {};

  static Future init() async {
    await FirestorePathsService.getCustomerCol().where('allowMarketing', isEqualTo: true).get().then((snapshot) {
      allCustomers.clear();
      for (var doc in snapshot.docs) {
        Customer c = Customer.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        allCustomers[c] = false;
      }
    });
  }

  static Future<String?> createMessageRequest({
    required List<String> customerIds,
    required String messageTitle,
    required String messageContent,
    required SendType sendType,
  }) async {
    MessageRequest messageRequest = MessageRequest.create(
      customerIds: customerIds,
      messageTitle: messageTitle,
      messageContent: messageContent,
      sendType: sendType,
    );
    await FirestorePathsService.getMessageRequestsCol().doc(messageRequest.id).set(messageRequest.toMap());

    Response response = await Dio().post(
      FirebaseService.getUri('sendMessages').toString(),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $FUNCTIONS_KEY',
        },
      ),
      data: {
        'messageRequestId': messageRequest.id,
      },
    );

    return response.data;
  }
}

enum SendType {
  sms,
  email,
  unknown,
}