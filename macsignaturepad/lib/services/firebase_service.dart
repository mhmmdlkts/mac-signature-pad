import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'init_service.dart';

class FirebaseService {
  static const bool useEmulator = false;
  static const firebaseProjectName = 'mac-signature';
  static const functionLocation = 'europe-west1';
  static const localHostString = '127.0.0.1';
  static const authPort = 9099;
  static const functionsPort = 5001;
  static const firestorePort = 8080;
  static const storagePort = 9199;

  static Future _connectToFirebaseEmulator() async {

    FirebaseFirestore.instance.settings = Settings(
      host: '$localHostString:$firestorePort',
      sslEnabled: false,
      persistenceEnabled: false
    );

    await FirebaseAuth.instance.useAuthEmulator(localHostString, authPort);
  }

  static Uri getUri(String functionName, {bool test=false}) => Uri(
    port: (test || useEmulator)?functionsPort:null,
    scheme: (test || useEmulator)?'http':'https',
    host: (test || useEmulator)?localHostString:'$functionLocation-$firebaseProjectName.cloudfunctions.net',
    path: (test || useEmulator)?'$firebaseProjectName/$functionLocation/$functionName':functionName,
  );

  static initializeApp() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (useEmulator) {
      await _connectToFirebaseEmulator();
    }
  }

  static Future signOut() async {
    InitService.cleanCache();
    await FirebaseAuth.instance.signOut();
  }
}