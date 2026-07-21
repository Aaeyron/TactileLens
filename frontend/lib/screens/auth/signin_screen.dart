import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../styles/auth/signin_styles.dart';
import '../../utils/session_manager.dart';
import '../main/main_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool isPasswordVisible = false;

  final TextEditingController emailController =
    TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  @override
    void dispose() {
      emailController.dispose();
      passwordController.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SignInStyles.backgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: SignInStyles.backgroundColor,
        foregroundColor: Colors.black,
      ),

      body: SafeArea(
        child: Padding(
          padding: SignInStyles.pagePadding,

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const SizedBox(height: 20),

                Text(
                  "Sign In",
                  style: SignInStyles.titleStyle,
                ),

                const SizedBox(height: 10),

                Text(
                  "Sign in to sync your scan history across devices.",
                  style: SignInStyles.descriptionStyle,
                ),

                const SizedBox(height: 40),

                TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,

                  onChanged: (value) {
                    setState(() {});
                  },

                  decoration: InputDecoration(
                    labelText: "Password",

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    prefixIcon: const Icon(Icons.lock_outline),

                    suffixIcon: passwordController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible =
                                    !isPasswordVisible;
                              });
                            },
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 15),

                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {
                      // TODO:
                      // Forgot Password
                    },

                    child: const Text("Forgot Password?"),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () async {
                        if (emailController.text.isEmpty ||
                            passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill in all fields."),
                            ),
                          );
                          return;
                        }

                        final response = await AuthService.loginUser(
                          email: emailController.text.trim(),
                          password: passwordController.text,
                        );

                        if (response.statusCode == 200) {
                              final data = jsonDecode(response.body);

                              await SessionManager.saveUser(
                                id: data["user"]["id"],
                                firstName: data["user"]["first_name"],
                                lastName: data["user"]["last_name"],
                                email: data["user"]["email"],
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Login successful!"),
                                ),
                              );

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(),
                                ),
                              );
                            } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Invalid email or password."),
                            ),
                          );
                        }
                      },

                    child: const Text("Sign In"),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    const Text(
                      "Don't have an account?",
                    ),

                    TextButton(
                      onPressed: () {
                        // TODO:
                        // Navigate to Sign Up
                      },

                      child: const Text("Sign Up"),
                    ),

                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}