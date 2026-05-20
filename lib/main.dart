import 'package:flutter/material.dart';
import 'view/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 0, 149, 255),
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  textTheme: const TextTheme(
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startistics',
      theme: appTheme,
      home: const ProfileScreen(),
    );
  }
}
