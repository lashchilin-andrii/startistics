import 'package:flutter/material.dart';

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
