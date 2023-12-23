import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  bool freeze;
  SplashScreen({this.freeze = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: Center(
        child: freeze?Container():const CircularProgressIndicator(),
      ),
    );
  }
}