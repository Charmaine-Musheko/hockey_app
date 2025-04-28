import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hockey_union_app/ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // <-- NO options here
  runApp(HockeyUnionApp());
}


class HockeyUnionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namibia Hockey Union',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}
