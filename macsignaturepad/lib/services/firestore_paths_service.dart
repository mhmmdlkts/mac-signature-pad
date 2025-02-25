import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestorePathsService {

  static const String _advisorsKey = "advisors";
  static const String _customersKey = "customers";
  static const String _signaturesKey = "signatures";
  static const String _messageRequestKey = "messageRequests";

  static CollectionReference getAdvisorCol() => FirebaseFirestore.instance.collection(_advisorsKey);
  static DocumentReference getAdvisorDoc({String? advisorId}) => getAdvisorCol().doc(advisorId??FirebaseAuth.instance.currentUser!.uid);

  static CollectionReference getCustomerCol() => FirebaseFirestore.instance.collection(_customersKey);
  static DocumentReference getCustomerDoc({required String customerId}) => getCustomerCol().doc(customerId);

  static CollectionReference getSignatureCol({required String customerId}) => getCustomerDoc(customerId: customerId).collection(_signaturesKey);
  static DocumentReference getSignatureDoc({required String customerId, required String signatureId}) => getSignatureCol(customerId: customerId).doc(signatureId);

  static CollectionReference getMessageRequestsCol() => FirebaseFirestore.instance.collection(_messageRequestKey);
  static DocumentReference getMessageRequestDoc({required String messageRequestId}) => getMessageRequestsCol().doc(messageRequestId);
}