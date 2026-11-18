import 'package:flutter/material.dart';
import 'package:sales_management/pages/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'NunitoSans',
        scaffoldBackgroundColor: Colors.white,
        ),
      home: Login(),
      debugShowCheckedModeBanner: false,
      title: 'SamKaha - Basic',
    );
  }
}