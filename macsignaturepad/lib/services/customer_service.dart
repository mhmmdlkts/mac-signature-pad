import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../models/customer.dart';
import 'firebase_service.dart';
import 'firestore_paths_service.dart';

class CustomerService {
  static final List<Customer> customers = [];
  static Map<int, Function> _listeners = {};

  static Future initCustomers({required int id, required Function function}) async {
    _listeners[id] = function;
    CollectionReference col = FirestorePathsService.getCustomerCol();
    QuerySnapshot querySnapshot = await col.get();
    customers.clear();
    querySnapshot.docs.forEach((doc) {
      Customer customer = Customer.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      customers.add(customer);
    });
    List<Future> futures = [];
    customers.forEach((customer) {
      futures.add(customer.initLastSignature());
    });
    await Future.wait(futures);
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

  static Future addNewCustomer(Customer customer) async {
    await customer.push();
    customers.add(customer);
    notifyListeners();
  }

  static cleanCache() {
    customers.clear();
  }
}