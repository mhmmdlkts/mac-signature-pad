import 'package:macsignaturepad/services/firestore_paths_service.dart';

import '../services/message_service.dart';

class MessageRequest {
  final String id;

  final List<String> customerIds;
  final DateTime timestamp;
  final DateTime? sentAt;

  final String messageTitle;
  final String messageContent;

  final SendType sendType;
  final bool messageSent;

  MessageRequest({
    required this.id,
    required this.timestamp,
    required this.sentAt,
    required this.messageSent,
    required this.customerIds,
    required this.messageTitle,
    required this.messageContent,
    required this.sendType,
  });

  factory MessageRequest.create({
    required List<String> customerIds,
    required String messageTitle,
    required String messageContent,
    required SendType sendType,
  }) {
    return MessageRequest(
      id: FirestorePathsService.getMessageRequestsCol().doc().id,
      timestamp: DateTime.now(),
      customerIds: customerIds,
      messageSent: false,
      sentAt: null,
      messageTitle: messageTitle,
      messageContent: messageContent,
      sendType: sendType,
    );
  }

  factory MessageRequest.fromMap(Map<String, dynamic> map, String id) {
    return MessageRequest(
      id: id,
      timestamp: map['timestamp'].toDate(),
      customerIds: List<String>.from(map['customerIds'] ?? []),
      messageTitle: map['messageTitle'],
      messageContent: map['messageContent'],
      messageSent: map['messageSent'],
      sentAt: map['sentAt']?.toDate(),
      sendType: SendType.values.firstWhere((e) => e.toString() == map['sendType'], orElse: () => SendType.unknown),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerIds': customerIds,
      'messageTitle': messageTitle,
      'messageContent': messageContent,
      'sendType': sendType.name,
      'timestamp': timestamp,
      'messageSent': messageSent,
      'sentAt': sentAt,
    };
  }
}