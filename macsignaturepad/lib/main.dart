import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:macsignaturepad/decoration/colors.dart';
import 'package:macsignaturepad/screens/admin_screen.dart';
import 'package:macsignaturepad/screens/advisors_screen.dart';
import 'package:macsignaturepad/screens/create_customer_screen.dart';
import 'package:macsignaturepad/screens/login_screen.dart';
import 'package:macsignaturepad/screens/no_signature_screen.dart';
import 'package:macsignaturepad/screens/sign_screen.dart';
import 'package:macsignaturepad/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Map<String, String> args;
  MyApp({args, super.key}) : args = args ?? {};

  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: isSignedIn?'/admin':'/',
      routes: {
        '/': (context) => isSignedIn?AdminScreen():NoSignatureScreen(),
        '/sign': (context) => SignScreen(),
        '/login': (context) => LoginScreen(),
        '/admin': (context) => isSignedIn?AdminScreen():LoginScreen(),
        '/admin/createCustomer': (context) => CreateCustomerScreen(),
        '/admin/advisors': (context) => AdvisorsScreen(),
      },
      title: 'Mac Signature Pad',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: firstColor),
        useMaterial3: true,
      ),
    );
  }
}