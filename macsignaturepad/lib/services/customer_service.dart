import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macsignaturepad/services/advisor_service.dart';

import '../models/customer.dart';
import 'firebase_service.dart';
import 'firestore_paths_service.dart';

class CustomerService {
  static final List<Customer> customers = [];
  static final Map<int, Function> _listeners = {};

  static Future initCustomers({int? id, Function? function}) async {
    if (id != null && function != null) {
      _listeners[id] = function;
    }
    CollectionReference col = FirestorePathsService.getCustomerCol();

    QuerySnapshot? querySnapshot;
    if (AdvisorService.isAdmin) {
      querySnapshot = await col.get();
    } else if (FirebaseAuth.instance.currentUser != null) {
      querySnapshot = await col.where('advisorId', isEqualTo: FirebaseAuth.instance.currentUser!.uid).get();
    } else {
      return;
    }
    customers.clear();
    querySnapshot?.docs.forEach((doc) {
      Customer customer = Customer.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      customers.add(customer);
    });
    List<Future> futures = [];

    customers.forEach((customer) {
      futures.add(customer.initLastSignature());
    });

    await Future.wait(futures);
    customers.sort();
  }

  static Future notifyListeners() async {
    _listeners.forEach((key, value) {
      value();
    });
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
      print('Error: ${response.statusCode}');
      return false;
    }
  }

  static Future removeCustomer(Customer customer) async {
    customers.remove(customer);
    FirestorePathsService.getCustomerDoc(customerId: customer.id!).delete();
    notifyListeners();
  }

  static Future addNewCustomer(Customer customer, {bool sms = false}) async {
    await customer.push();
    customers.add(customer);
    customers.sort();
    if (sms) {
      await sendNotificationToCustomer(customer: customer, email: false, sms: true);
    }
    notifyListeners();
  }

  static cleanCache() {
    customers.clear();
  }
}