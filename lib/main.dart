import 'package:flutter/material.dart';
import 'HomePage.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo.shade50),
        useMaterial3: true,
          scaffoldBackgroundColor:Colors.indigo.shade50
      ),
      home: const HomePage(),
    );
  }
}

