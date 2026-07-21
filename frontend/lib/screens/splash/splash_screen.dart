import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  double progress = 0.0;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    startLoading();
  }

  void startLoading() {

    Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {

        setState(() {
          progress += 0.01;
        });

        if (progress >= 1.0) {

          timer.cancel();

          Future.delayed(
            const Duration(milliseconds: 500),
            () {

              if (mounted) {
                setState(() {
                  isLoaded = true;
                });
              }
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: SafeArea(

        child: Center(

          child: Padding(

            padding: const EdgeInsets.all(24.0),

            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                const Text(
                  "Welcome to TactileLens",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 15),

                const Text(
                  "AI-assisted printed math OCR and "
                  "LaTeX-to-Nemeth Braille translator "
                  "for accessible learning.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 40),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),

                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },

                  child: isLoaded

                      ? ElevatedButton(
                          key: const ValueKey("button"),

                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(),
                              ),
                            );
                          },

                          child: const Text(
                            "Get Started",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )


                      : Column(
                          key: const ValueKey("loading"),

                          children: [

                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                            ),

                            const SizedBox(height: 15),

                            Text(
                              "${(progress * 100).toInt()}%",
                              style: const TextStyle(
                                fontSize: 16,
                      ),
                     ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}