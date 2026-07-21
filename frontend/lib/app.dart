import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';

class TactileLensApp extends StatelessWidget {
  const TactileLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TactileLens',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}