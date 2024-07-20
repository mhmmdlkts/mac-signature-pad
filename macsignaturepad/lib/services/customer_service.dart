import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:macsignaturepad/services/advisor_service.dart';

import '../models/customer.dart';
import '../models/signature.dart';
import 'firebase_service.dart';
import 'firestore_paths_service.dart';

class CustomerService {
  // static final List<Customer> customers = [];
  static final Map<int, Function> _listeners = {};
  static final Map<String, List<Customer>> customersMap = {
    
  };

  static Future initCustomers({int? id, Function? function, int year = 0, int month = 0, bool force = false}) async {
    if ((year == 0 || month == 0) && year + month != 0) {
      return;
    }

    String key = '$month-$year';
    
    if (id != null && function != null) {
      _listeners[id] = function;
    }
    if (customersMap[key] != null && !force) {
      return;
    }

    CollectionReference col = FirestorePathsService.getCustomerCol();
    Query? query;
    Query? query2;
    if (year == 0 && month == 0) {
      DateTime expiryLimit = DateTime.now().add(const Duration(days: Signature.warnDay));
      query = col.where('vollmachtExp', isNull: true);
      query2 = col.where('vollmachtExp', isLessThanOrEqualTo: expiryLimit);
    } else {
      DateTime startOfMonth = DateTime(year, month);
      DateTime endOfMonth = DateTime(year, month + 1).subtract(const Duration(days: 1));
      query = col.where('ts', isGreaterThanOrEqualTo: startOfMonth)
          .where('ts', isLessThanOrEqualTo: endOfMonth);
    }


    QuerySnapshot? querySnapshot;
    QuerySnapshot? querySnapshot2;
    if (AdvisorService.isAdmin) {
      querySnapshot = await query.get();
      querySnapshot2 = await query2?.get();
    } else if (FirebaseAuth.instance.currentUser != null) {
      querySnapshot = await query.where('advisorId', isEqualTo: FirebaseAuth.instance.currentUser!.uid).get();
      querySnapshot2 = await query2?.where('advisorId', isEqualTo: FirebaseAuth.instance.currentUser!.uid).get();
    } else {
      return;
    }
    customersMap[key]?.clear();
    customersMap[key] ??= [];
    for (var doc in querySnapshot.docs) {
      Customer customer = Customer.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      customersMap[key]?.add(customer);
    }
    for (var doc in querySnapshot2?.docs??[]) {
      Customer customer = Customer.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      customersMap[key]?.add(customer);
    }
    List<Future> futures = [];

    customersMap[key]?.forEach((customer) {
      futures.add(customer.initLastSignature());
    });

    await Future.wait(futures);
    customersMap[key]?.sort();
  }

  static Future<bool> sendNotificationToCustomer({
    required Customer customer,
    required bool email,
    required bool sms
  }) async {
    Response response = await Dio().post(
      FirebaseService.getUri('sendCustomerNotification').toString(),
      data: {
        'customerId': customer.id,
        'token': Customer.generateToken(),
        'email': email,
        'sms': sms
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      if (kDebugMode) {
        print('Error: ${response.statusCode}');
      }
      return false;
    }
  }

  static Future removeCustomer(Customer customer) async {
    for (var customers in customersMap.values) {
      customers.remove(customer);
    }
    FirestorePathsService.getCustomerDoc(customerId: customer.id).delete();
    // notifyListeners();
  }

  static Future addNewCustomer(Customer customer, {bool sms = false, bool email = false, Uint8List? bprotokolManuellBytes, Uint8List? vollmachtManuelBytes}) async {
    await customer.push();
    String key = '${DateTime.now().month}-${DateTime.now().year}';
    customersMap[key] ??= [];
    customersMap[key]?.add(customer);
    customersMap[key]?.sort();
    try {
      if (email || sms) {
        await sendNotificationToCustomer(customer: customer, email: email, sms: sms);
      }
      String vollmachtDownloadUrl = '';
      String protokollDownloadUrl = '';
      FirebaseStorage storage = FirebaseStorage.instance;
      // Upload für Protokoll PDF
      if (bprotokolManuellBytes != null) {
        try {
          Reference ref = storage.ref('${customer.id}/pdfs/protokoll_v1.pdf');
          await ref.putData(bprotokolManuellBytes);
          protokollDownloadUrl = await ref.getDownloadURL();
          print('Protokoll hochgeladen');
        } catch (e) {
          print('Fehler beim Hochladen des Protokolls: $e');
        }
      }

      // Upload für Vollmacht PDF
      if (vollmachtManuelBytes != null) {
        try {
          Reference ref = storage.ref('${customer.id}/pdfs/vollmacht_v1.pdf');
          await ref.putData(vollmachtManuelBytes);
          vollmachtDownloadUrl = await ref.getDownloadURL();
          print('Vollmacht hochgeladen');
        } catch (e) {
          print('Fehler beim Hochladen der Vollmacht: $e');
        }
      }

      if (vollmachtDownloadUrl.isNotEmpty || protokollDownloadUrl.isNotEmpty) {
        Signature signature = Signature.manuel(customer.id, protokollDownloadUrl, vollmachtDownloadUrl);
        await signature.push(customer.id);
        await FirestorePathsService.getCustomerDoc(customerId: customer.id).update({
          'lastSignatureId': signature.id
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  static cleanCache() {
    customersMap.clear();
  }

  static Future<List<Customer>> searchCustomers(String query) async {
    List<Customer> results = [];
    CollectionReference col = FirestorePathsService.getCustomerCol();
    try {

      QuerySnapshot snapshot = await col
          .where('searchKey', arrayContains: query.toLowerCase())
          .get();
      for (var doc in snapshot.docs) {
        Customer customer = Customer.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        results.add(customer);
      }
    } catch (e) {
      print(e);
    }
    results.sort();
    List<Future> futures = [];

    for (var customer in results) {
      futures.add(customer.initLastSignature());
    }

    await Future.wait(futures);
    return results;
  }
}