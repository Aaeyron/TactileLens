import 'package:flutter/material.dart';

import '../../styles/auth/auth_styles.dart';
import '../main/main_screen.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthStyles.backgroundColor,

      body: SafeArea(
        child: Padding(
          padding: AuthStyles.pagePadding,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              // Logo (Placeholder)
              Icon(
                Icons.menu_book_rounded,
                size: 90,
                color: AuthStyles.primaryColor,
              ),

              const SizedBox(height: 25),

              Text(
                "Welcome to TactileLens",
                style: AuthStyles.titleStyle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              Text(
                "Use TactileLens offline for free or sign in to sync your scan history across devices.",
                style: AuthStyles.descriptionStyle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 45),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    );
                  },

                  child: const Text("Sign In"),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,

                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },

                  child: const Text("Sign Up"),
                ),
              ),

              const SizedBox(height: 30),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Continue without an account",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}