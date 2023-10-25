import 'package:flutter/material.dart';
import 'package:macsignaturepad/decoration/colors.dart';
import 'package:macsignaturepad/screens/sign_screen.dart';

class NoSignatureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SignScreen.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.check_circle_outline,
              color: firstColor,
              size: 100,
            ),
            SizedBox(height: 20), // Ein kleiner Abstand zwischen dem Icon und dem Text.
            Text(
              "Es gibt nichts zum Unterschreiben.",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
