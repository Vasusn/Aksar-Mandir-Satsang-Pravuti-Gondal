import 'dart:async';

import 'package:aksar_mandir_gondal/Screens/initial_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const InitialScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            height: MediaQuery.of(context).size.height,
            "assets/splash_screen.png",
            fit: BoxFit.cover,
          ),
          const Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 207, 29, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
