import 'package:flutter/material.dart';

import '../../styles/auth/signup_styles.dart';
import '../../services/auth/auth_service.dart';
import 'signin_screen.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final TextEditingController firstNameController =
    TextEditingController();
final TextEditingController lastNameController =
    TextEditingController();
final TextEditingController emailController =
    TextEditingController();

final TextEditingController passwordController =
    TextEditingController();

final TextEditingController confirmPasswordController =
    TextEditingController();

@override
void dispose() {
  firstNameController.dispose();
  lastNameController.dispose();
  emailController.dispose();
  passwordController.dispose();
  confirmPasswordController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SignUpStyles.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: SignUpStyles.backgroundColor,
        foregroundColor: Colors.black,
      ),

      body: SafeArea(
        child: Padding(
          padding: SignUpStyles.pagePadding,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 20),
                Text(
                  "Create Account",
                  style: SignUpStyles.titleStyle,
                ),

                const SizedBox(height: 10),
                Text(
                  "Create an account to securely back up and synchronize your scan history.",
                  style: SignUpStyles.descriptionStyle,
                ),

                const SizedBox(height: 35),
                TextField(
                controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: "First Name",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
               TextField(
                controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: "Last Name",
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
               TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    )
                    : null,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                TextField(
                      controller: confirmPasswordController,
                      obscureText: !isConfirmPasswordVisible,

                      onChanged: (value) {
                        setState(() {});
                      },

                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: confirmPasswordController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isConfirmPasswordVisible =
                                        !isConfirmPasswordVisible;
                                  });
                                },
                              )
                            : null,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                   onPressed: () async {
                          if (firstNameController.text.isEmpty ||
                              lastNameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please fill in all fields."),
                              ),
                            );
                            return;
                          }

                          final emailRegex = RegExp(
                              r'^[\w\.-]+@([\w-]+\.)+[a-zA-Z]{2,}$',
                            );
                            if (!emailRegex.hasMatch(emailController.text.trim())) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter a valid email address."),
                                ),
                              );
                              return;
                            }
                          if (passwordController.text !=
                              confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Passwords do not match."),
                              ),
                            );
                            return;
                          }

                          final response = await AuthService.registerUser(
                            firstName: firstNameController.text.trim(),
                            lastName: lastNameController.text.trim(),
                            email: emailController.text.trim(),
                            password: passwordController.text,
                          );

                          if (response.statusCode == 201) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Account created successfully!"),
                              ),
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                            );
                          } else if (response.statusCode == 409) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("This email is already registered."),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Registration failed. Please try again."),
                              ),
                            );
                          }
                        },

                    child: const Text("Create Account"),
                  ),
                ),

                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                    ),

                    TextButton(
                      onPressed: () {
                        // TODO:
                        // Navigate to Sign In
                      },
                      child: const Text("Sign In"),
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