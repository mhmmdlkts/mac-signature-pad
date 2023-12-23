import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../models/advisor.dart';
import 'firebase_service.dart';
import 'firestore_paths_service.dart';

class AdvisorService {

  static bool _isInited = false;
  static Advisor? advisor;
  static List<Advisor> allAdvisors = [];

  static bool get isAdmin => _isInited && (advisor?.isAdmin??false);
  static bool get isOffice => _isInited && (advisor?.isOffice??false);

  static Future initAdvisor() async {
    DocumentSnapshot snapshot = await FirestorePathsService.getAdvisorDoc().get();
    advisor = Advisor.fromJson(snapshot.data() as Map<String, dynamic>, snapshot.id);
    _isInited = true;
  }

  static Future initAllAdvisors() async {
    if (!isAdmin) {
      return;
    }
    QuerySnapshot querySnapshot = await FirestorePathsService.getAdvisorCol().get();
    allAdvisors = querySnapshot.docs.map((doc) => Advisor.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  static Future setAdvisorRole(Advisor advisor, String newRole) async {
    if ((newRole != 'admin' && newRole != 'advisor') || advisor.role != newRole) {
      return;
    }
    advisor.role = newRole;
    await advisor.push();
  }

  static Future addNewAdvisor(Advisor advisor) async {
    allAdvisors.add(advisor);
    await advisor.push();
  }


  static Future removeAdvisor(Advisor advisorToDelete) async {
    if (!isAdmin || advisor!.id == advisorToDelete.id) {
      return;
    }

    Response response = await Dio().post(
      FirebaseService.getUri('removeAdvisor').toString(),
      data: {
        'myId': advisor!.id,
        'idToDelete': advisorToDelete.id,
      },
    );

    if (response.statusCode == 200) {
      allAdvisors.remove(advisorToDelete);
      return true;
    } else {
      return false;
    }
  }

}