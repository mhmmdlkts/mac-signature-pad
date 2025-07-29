import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:macsignaturepad/enums/required_documents.dart';
import 'package:macsignaturepad/models/service_details.dart';
import 'package:macsignaturepad/models/signature.dart';
import 'package:macsignaturepad/services/customer_service.dart';

import '../services/advisor_service.dart';
import '../services/firestore_paths_service.dart';
import 'analysis_details.dart';

class Customer implements Comparable {
  late String id;
  late Timestamp ts;
  late String advisorId;
  late String advisorName;
  late String? title;
  late String? anrede;
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
  Timestamp? vollmachtExp;
  Timestamp? bprotokollExp;
  String? lastSignatureId;
  Signature? lastSignature;
  String? token;
  String? email;
  String? uid;
  String? stnr;
  bool allowMarketing;
  List<ServiceDetails>? details;
  List<AnalysisDetails>? analysisOptions;
  Map<String, Map>? extraInfo;
  List<RequiredDocument> actions;
  Map<RequiredDocument, String> documents;

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
    String? title,
    String? anrede,
    String? uid,
    String? stnr,
    List<ServiceDetails>? details,
    List<AnalysisDetails>? analysisOptions,
    Map<String, Map>? extraInfo,
    bool allowMarketing = false,
    List<RequiredDocument> actions = const [],
    Map<RequiredDocument, String> documents = const {},
  }) => Customer(
    advisorId: AdvisorService.advisor?.id??'',
    advisorName: AdvisorService.advisor?.name??'',
    title: title,
    anrede: anrede,
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
    analysisOptions: analysisOptions,
    extraInfo: extraInfo,
    token: generateToken(),
    ts: Timestamp.now(),
    allowMarketing: allowMarketing,
    actions: actions,
    documents: documents,
  );

  Customer({
    String? idd,
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
    required this.allowMarketing,
    required this.actions,
    required this.documents,
    this.title,
    this.anrede,
    this.smsSentTime,
    this.nextTermin,
    this.vollmachtExp,
    this.bprotokollExp,
    this.emailSentTime,
    this.lastSignatureId,
    this.email,
    this.uid,
    this.stnr,
    this.token,
    this.details,
    this.analysisOptions,
    this.extraInfo,
  }) {
    idd ??= FirestorePathsService.getCustomerCol().doc().id;
    id = idd;
  }


  Color get bprotokollExpiresDateColor => lastSignature==null && lastSignatureId!=null?Colors.green:(lastSignature?.bprotokollExpiresDateColor??Colors.red);
  Color get vollmachtExpiresDateColor => lastSignature==null && lastSignatureId!=null?Colors.green:(lastSignature?.vollmachtExpiresDateColor??Colors.red);

  String get readableExpBprotokoll => lastSignature?.readableExpBprotokoll==null?'----------':lastSignature!.readableExpBprotokoll;
  String get readableExpVollmacht => lastSignature?.readableExpVollmacht==null?'----------':lastSignature!.readableExpVollmacht;

  factory Customer.fromJson(Map<String, dynamic> json, String id) {
    Timestamp birthdate = json['birthdate'] is Timestamp ? json['birthdate'] : convertMapToTimestamp(json['birthdate']);
    Timestamp? vollmachtExp = json['vollmachtExp']==null?null:(json['vollmachtExp'] is Timestamp ? json['vollmachtExp'] : convertMapToTimestamp(json['vollmachtExp']));
    Timestamp? bprotokollExp = json['bprotokollExp']==null?null:(json['bprotokollExp'] is Timestamp ? json['bprotokollExp'] : convertMapToTimestamp(json['bprotokollExp']));
    Timestamp? smsSentTime = json['smsSentTime']==null?null:(json['smsSentTime'] is Timestamp ? json['smsSentTime'] : convertMapToTimestamp(json['smsSentTime']));
    Timestamp? emailSentTime = json['emailSentTime']==null?null:(json['emailSentTime'] is Timestamp ? json['emailSentTime'] : convertMapToTimestamp(json['emailSentTime']));
    Timestamp ts = json['ts'] is Timestamp ? json['ts'] : convertMapToTimestamp(json['ts']);
    Timestamp? nextTermin = json['nextTermin']==null?null:(json['nextTermin'] is Timestamp ? json['nextTermin'] : convertMapToTimestamp(json['nextTermin']));
    List<ServiceDetails>? details = json['details'] == null ? null : List<ServiceDetails>.from(json['details'].map((x) => ServiceDetails.fromJson(x)));
    // RequiredDocument is an enum, so we need to convert it properly
    List<RequiredDocument> actions = json['actions'] == null ? [] : List<RequiredDocument>.from(
      json['actions'].map((x) => RequiredDocument.values.firstWhere((e) => e.name == x))
    );

    List<AnalysisDetails>? analysisOptions = json['analysisOptions'] == null ? null : List<AnalysisDetails>.from(json['analysisOptions'].map((x) => AnalysisDetails.fromJson(x)));
    String street = json['street'];
    return Customer(
      idd: id,
      title: json['title'],
      anrede: json['anrede'],
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
      bprotokollExp: bprotokollExp,
      vollmachtExp: vollmachtExp,
      smsSentTime: smsSentTime,
      emailSentTime: emailSentTime,
      uid: json['uid'],
      stnr: json['stnr'],
      token: json['token'],
      allowMarketing: json['allowMarketing']??false,
      details: details,
      analysisOptions: analysisOptions,
      nextTermin: nextTermin,
      ts: ts,
      actions: actions,
      documents: json['documents'] == null ? {} : Map<RequiredDocument, String>.from(
        json['documents'].map((key, value) => MapEntry(
          RequiredDocument.values.firstWhere((e) => e.name == key),
          value,
        )),
      ),
    );
  }

  bool get isDownloaded => lastSignature?.isDownloaded??true;
  bool get hasBackOfficeDownloaded => lastSignature?.officeDownloaded??true;

  String get readableSmsSentTime => smsSentTime==null?'----------':DateFormat('dd.MM.yyyy HH:mm').format(smsSentTime!.toDate());
  String get readableEmailSentTime => emailSentTime==null?'----------':DateFormat('dd.MM.yyyy HH:mm').format(emailSentTime!.toDate());

  Color get smsSentDateColor => (smsSentTime?.toDate().isAfter(DateTime.now().subtract(const Duration(minutes: 15)))??false)?Colors.green:Colors.red;
  Color get emailSentDateColor => (emailSentTime?.toDate().isAfter(DateTime.now().subtract(const Duration(minutes: 15)))??false)?Colors.green:Colors.red;

  String fileName(String originalName) {
    originalName = '$surname $name $originalName';
    var nameWithoutSpecialChars = originalName
        .replaceAllMapped(RegExp(r'[ÄäÖöÜüẞß]'), (match) {
      switch (match[0]) {
        case 'Ä': case 'ä': return 'ae';
        case 'Ö': case 'ö': return 'oe';
        case 'Ü': case 'ü': return 'ue';
        case 'ẞ': case 'ß': return 'ss';
        default: return '';
      }
    }).replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_').toLowerCase();

    return nameWithoutSpecialChars;
  }

  Future initLastSignature() async {
    try {
      if (lastSignatureId == null || lastSignatureId!.isEmpty) return;
      DocumentSnapshot doc = await FirestorePathsService.getSignatureDoc(signatureId: lastSignatureId!, customerId: id).get();
      if (!doc.exists) return;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      lastSignature = Signature.fromJson(data, doc.id);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
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
    if (phone.isEmpty) return '-';
    return phone;
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
    String time = DateTime.now().add(const Duration(days: 3)).microsecondsSinceEpoch.toString();
    String characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Random random = Random();
    return time + List.generate(24, (index) => characters[random.nextInt(characters.length)]).join();
  }

  Map<String, dynamic> toJson() => {
    'title': title?.trim(),
    'anrede': anrede?.trim(),
    'name': name.trim(),
    'surname': surname.trim(),
    'phone': phone.trim(),
    'email': email?.trim(),
    'advisorId': advisorId.trim(),
    'advisorName': advisorName.trim(),
    'ts': ts,
    'birthdate': birthdate,
    'zip': zip.trim(),
    'city': city.trim(),
    'street': street.trim(),
    'uid': uid,
    'stnr': stnr,
    'vollmachtExp': vollmachtExp,
    'bprotokollExp': bprotokollExp,
    'token': token,
    'nextTermin': nextTermin,
    'details': details?.map((e) => e.toJson()).toList(),
    'analysisOptions': analysisOptions?.map((e) => e.toJson()).toList(),
    'extraInfo': extraInfo,
    'searchKey': searchKey,
    'actions': actions.map((e) => e.name).toList(),
    'documents': documents.map((key, value) => MapEntry(key.name, value)),
  };

  List<String> get searchKey {
    List<String> keys = [];
    keys.addAll(name.trim().toLowerCase().split(' '));
    keys.addAll(surname.trim().toLowerCase().split(' '));
    keys.add(phone.trim().toLowerCase());
    if (email != null) keys.add(email!.trim().toLowerCase());
    return keys;
  }

  String get readableName {
    String totalName = '${name.trim()} ${surname.trim()}';
    if (anrede != null && anrede!.isNotEmpty) {
      totalName = '$anrede $totalName';
    }
    if (title != null && title!.isNotEmpty) {
      totalName = '$title $totalName';
    }
    return totalName;
  }

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
    if (lastSignatureId != null && other.lastSignatureId == null) {
      return 1;
    }
    if (lastSignatureId == null && other.lastSignatureId != null) {
      return -1;
    }
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
    title = customer.title;
    anrede = customer.anrede;
    name = customer.name;
    surname = customer.surname;
    phone = customer.phone;
    email = customer.email;
    advisorId = customer.advisorId;
    advisorName = customer.advisorName;
    ts = customer.ts;
    birthdate = customer.birthdate;
    zip = customer.zip;
    city = customer.city;
    street = customer.street;
    uid = customer.uid;
    stnr = customer.stnr;
    token = customer.token;
    nextTermin = customer.nextTermin;
    details = customer.details;
    lastSignatureId = customer.lastSignatureId;
    smsSentTime = customer.smsSentTime;
    emailSentTime = customer.emailSentTime;
    await initLastSignature();
  }

  Future<bool> setIsDownloaded() async => await lastSignature?.setIsDownloaded(id)??false;

  Future unsubscribeNewsletter() async {
    await FirestorePathsService.getCustomerDoc(customerId: id).update({
      'allowMarketing': false,
    });
    allowMarketing = false;
  }
}