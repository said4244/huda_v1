import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'intro_page.dart';
import 'language_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Huda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Tufuli Arabic',
        primaryColor: const Color(0xFF4D382D),
      ),
      home: const IntroPage(),
    );
  }
}