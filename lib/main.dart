import 'package:flutter/material.dart';
import 'screens/home.dart';

void main() {
  runApp(const NdaCalculatorApp());
}

class NdaCalculatorApp extends StatelessWidget {
  const NdaCalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Night Duty Calculator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
