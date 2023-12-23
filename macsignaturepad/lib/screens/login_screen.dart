import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:macsignaturepad/screens/admin_screen.dart';
import 'package:macsignaturepad/screens/splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int i = 0;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // auth.FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return loading();
          }
          final user = snapshot.data;
          if (user == null) {
            return welcomeScreen();
          } else {
            return const AdminScreen();
          }
        }
    );
  }

  Widget loading() => SplashScreen(freeze: false);

  Widget welcomeScreen() => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Mac Signature Pad',
    home: Scaffold(
        body: SignInScreen(
            showAuthActionSwitch: false,
            providers: [
              EmailAuthProvider()
            ]
        )
    ),
  );
}
