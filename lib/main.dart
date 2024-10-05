import 'package:aksar_mandir_gondal/Screens/splash_screen.dart';
import 'package:aksar_mandir_gondal/firebase_options.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aksar Mandir Satsang Pravuti - Gondal',
      theme: ThemeData(
        fontFamily: 'regularFont',
        useMaterial3: false,
      ),
      // home: const UserList(),
       home: const SplashScreen(),
    );
  }
}
