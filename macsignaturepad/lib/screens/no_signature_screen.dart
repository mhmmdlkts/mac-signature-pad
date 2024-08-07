import 'package:flutter/material.dart';
import 'package:macsignaturepad/decoration/colors.dart';
import 'package:macsignaturepad/screens/sign_screen.dart';

import '../services/init_service.dart';

class NoSignatureScreen extends StatelessWidget {
  const NoSignatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SignScreen.backgroundColor,
      body: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.check_circle_outline,
                  color: firstColor,
                  size: 100,
                ),
                SizedBox(height: 20),
                Text(
                  "Geschafft",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Es gibt nichts zum Unterschreiben",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Text(
              InitService.version,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onLongPress: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const SizedBox(
                width: 100,
                height: 100,
              ),
            )
          )
        ],
      ),
    );
  }
}
