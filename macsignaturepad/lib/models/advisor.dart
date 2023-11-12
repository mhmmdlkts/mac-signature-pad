import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_paths_service.dart';

class Advisor {
  late String id;
  String name;
  String email;
  String phone;
  String role;

  Advisor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  }): assert(role == 'admin' || role == 'advisor');

  factory Advisor.create({
    required String name,
    required String email,
    required String phone,
    required String role,
  }) => Advisor(
    id: FirestorePathsService.getAdvisorCol().doc().id,
    name: name,
    email: email,
    phone: phone,
    role: role,
  );

  factory Advisor.fromJson(Map<String, dynamic> json, String id) {
    return Advisor(
      id: id,
      name: json['name'],
      email: json['email'],
      role: json['role'],
      phone: json['phone'],
    );
  }

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
  };

  Future push() async => await FirestorePathsService.getAdvisorDoc(advisorId: id).set(toJson());
}