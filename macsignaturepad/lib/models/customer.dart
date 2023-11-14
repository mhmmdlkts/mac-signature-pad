import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:macsignaturepad/models/service_details.dart';
import 'package:macsignaturepad/models/signature.dart';
import 'package:macsignaturepad/services/customer_service.dart';

import '../services/advisor_service.dart';
import '../services/firestore_paths_service.dart';

class Customer implements Comparable {
  late String id;
  late Timestamp ts;
  late String advisorId;
  late String advisorName;
  late String name;
  late String surname;
  late String zip;
  late String city;
  late String street;
  late Timestamp birthdate;
  late String phone;
  Timestamp? nextTermin;
  Timestamp? smsSentTime;
  Timestamp? emailSentTime;
  String? lastSignatureId;
  Signature? lastSignature;
  String? token;
  String? email;
  String? uid;
  String? stnr;
  List<ServiceDetails>? details;

  factory Customer.create({
    required String name,
    required String surname,
    required Timestamp birthdate,
    required String zip,
    required String city,
    required String street,
    required String phone,
    Timestamp? nextTermin,
    String? email,
    String? uid,
    String? stnr,
    List<ServiceDetails>? details,
  }) => Customer(
    advisorId: AdvisorService.advisor?.id??'',
    advisorName: AdvisorService.advisor?.name??'',
    name: name,
    surname: surname,
    birthdate: birthdate,
    zip: zip,
    city: city,
    street: street,
    phone: phone,
    email: email,
    uid: uid,
    nextTermin: nextTermin,
    stnr: stnr,
    details: details,
    token: generateToken(),
    ts: Timestamp.now(),
  );

  Customer({
    String? id,
    required this.name,
    required this.surname,
    required this.advisorName,
    required this.advisorId,
    required this.birthdate,
    required this.zip,
    required this.city,
    required this.street,
    required this.ts,
    required this.phone,
    this.smsSentTime,
    this.nextTermin,
    this.emailSentTime,
    this.lastSignatureId,
    this.email,
    this.uid,
    this.stnr,
    this.token,
    this.details,
  }) {
    id ??= FirestorePathsService.getCustomerCol().doc().id;
    this.id = id;
  }


  Color get bprotokollExpiresDateColor => lastSignature?.bprotokollExpiresDateColor??Colors.red;
  Color get vollmachtExpiresDateColor => lastSignature?.vollmachtExpiresDateColor??Colors.red;
  String get readableExpBprotokoll => lastSignature?.readableExpBprotokoll==null?'----------':lastSignature!.readableExpBprotokoll!;
  String get readableExpVollmacht => lastSignature?.readableExpVollmacht==null?'----------':lastSignature!.readableExpVollmacht!;

  factory Customer.fromJson(Map<String, dynamic> json, String id) {
    Timestamp birthdate = json['birthdate'] is Timestamp ? json['birthdate'] : convertMapToTimestamp(json['birthdate']);
    Timestamp? smsSentTime = json['smsSentTime']==null?null:(json['smsSentTime'] is Timestamp ? json['smsSentTime'] : convertMapToTimestamp(json['smsSentTime']));
    Timestamp? emailSentTime = json['emailSentTime']==null?null:(json['emailSentTime'] is Timestamp ? json['emailSentTime'] : convertMapToTimestamp(json['emailSentTime']));
    Timestamp ts = json['ts'] is Timestamp ? json['ts'] : convertMapToTimestamp(json['ts']);
    Timestamp? nextTermin = json['nextTermin']==null?null:(json['nextTermin'] is Timestamp ? json['nextTermin'] : convertMapToTimestamp(json['nextTermin']));
    List<ServiceDetails>? details = json['details'] == null ? null : List<ServiceDetails>.from(json['details'].map((x) => ServiceDetails.fromJson(x)));
    String street = json['street']??(json['country']??''); // because of old customers
    return Customer(
      id: id,
      name: json['name'],
      surname: json['surname'],
      phone: json['phone'],
      email: json['email'],
      advisorName: json['advisorName'],
      advisorId: json['advisorId'],
      birthdate: birthdate,
      zip: json['zip'],
      city: json['city'],
      street: street,
      lastSignatureId: json['lastSignatureId'],
      smsSentTime: smsSentTime,
      emailSentTime: emailSentTime,
      uid: json['uid'],
      stnr: json['stnr'],
      token: json['token'],
      details: details,
      nextTermin: nextTermin,
      ts: ts,
    );
  }

  Future initLastSignature() async {
    try {
      if (lastSignatureId == null || lastSignatureId!.isEmpty) return;
      DocumentSnapshot doc = await FirestorePathsService.getSignatureDoc(signatureId: lastSignatureId!, customerId: id).get();
      if (!doc.exists) return;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      lastSignature = Signature.fromJson(data, doc.id);
    } catch (e) {
      print(e);
    }
  }

  String get getReadableUid {
    if (uid == null || uid!.isEmpty) return '-';
    return uid!;
  }

  String get getReadableStnr {
    if (stnr == null || stnr!.isEmpty) return '-';
    return stnr!;
  }
  String get getReadablePhone {
    if (phone == null || phone!.isEmpty) return '-';
    return phone!;
  }

  String get getReadableEmail {
    if (email == null || email!.isEmpty) return '-';
    return email!;
  }

  static Timestamp convertMapToTimestamp(Map<String, dynamic> map) {
    return Timestamp(
      map['_seconds'],
      map['_nanoseconds'],
    );
  }

  String get readableNextTermin => nextTermin==null?'-':DateFormat('dd.MM.yyyy').format(nextTermin!.toDate());
  String get readableBirthdate => DateFormat('dd.MM.yyyy').format(birthdate.toDate());
  String get readableCreateTime => DateFormat('dd.MM.yyyy HH:mm').format(ts.toDate());

  String get readableAddress => '$zip, $city, $street';

  static String generateToken() {
    String time = DateTime.now().add(Duration(days: 3)).microsecondsSinceEpoch.toString();
    String characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Random random = Random();
    return time + List.generate(24, (index) => characters[random.nextInt(characters.length)]).join();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'surname': surname,
    'phone': phone,
    'email': email,
    'advisorId': advisorId,
    'advisorName': advisorName,
    'ts': ts,
    'birthdate': birthdate,
    'zip': zip,
    'city': city,
    'street': street,
    'uid': uid,
    'stnr': stnr,
    'token': token,
    'nextTermin': nextTermin,
    'details': details?.map((e) => e.toJson()).toList(),
  };

  Future push() async => await FirestorePathsService.getCustomerDoc(customerId: id).set(toJson());

  Future sendSms() async {
    await CustomerService.sendNotificationToCustomer(
      customer: this,
      email: false,
      sms: true,
    );
  }

  Future sendEmail() async {
    await CustomerService.sendNotificationToCustomer(
      customer: this,
      email: true,
      sms: false,
    );
  }

  @override
  int compareTo(other) {
    if (lastSignature != null && other.lastSignature == null) {
      return 1;
    }
    if (lastSignature == null && other.lastSignature != null) {
      return -1;
    }
    if (lastSignature != null && other.lastSignature != null) {
      return lastSignature!.compareTo(other.lastSignature!);
    }
    return ts.compareTo(other.ts);
  }

  Future refresh() async {
    DocumentSnapshot doc = await FirestorePathsService.getCustomerDoc(customerId: id).get();
    if (!doc.exists) return;
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Customer customer = Customer.fromJson(data, doc.id);
    this.name = customer.name;
    this.surname = customer.surname;
    this.phone = customer.phone;
    this.email = customer.email;
    this.advisorId = customer.advisorId;
    this.advisorName = customer.advisorName;
    this.ts = customer.ts;
    this.birthdate = customer.birthdate;
    this.zip = customer.zip;
    this.city = customer.city;
    this.street = customer.street;
    this.uid = customer.uid;
    this.stnr = customer.stnr;
    this.token = customer.token;
    this.nextTermin = customer.nextTermin;
    this.details = customer.details;
    this.lastSignatureId = customer.lastSignatureId;
    this.smsSentTime = customer.smsSentTime;
    this.emailSentTime = customer.emailSentTime;
    await initLastSignature();
  }
}