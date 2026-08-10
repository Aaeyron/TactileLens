import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../styles/screens/auth/signin_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../main/main_screen.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() =>
      _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool isPasswordVisible = false;
  bool _isSigningIn = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isSigningIn) return;

    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      final response = await AuthService.loginUser(
        email: email,
        password: password,
      );

      final Map<String, dynamic> responseData =
          _decodeResponse(response.body);

      if (response.statusCode != 200) {
        throw SignInException(
          _readServerMessage(responseData) ??
              'Unable to sign in. Please try again.',
        );
      }

      final dynamic rawUser = responseData['user'];
      final dynamic rawToken = responseData['token'];

      if (rawUser is! Map) {
        throw const SignInException(
          'The server returned invalid user information.',
        );
      }

      if (rawToken is! String ||
          rawToken.trim().isEmpty) {
        throw const SignInException(
          'The server did not return an authentication token.',
        );
      }

      final Map<String, dynamic> user =
          Map<String, dynamic>.from(rawUser);

      final dynamic rawUserId = user['id'];

      if (rawUserId is! num) {
        throw const SignInException(
          'The server returned an invalid user ID.',
        );
      }

      final String firstName =
          _readRequiredString(user, 'first_name');
      final String lastName =
          _readRequiredString(user, 'last_name');
      final String userEmail =
          _readRequiredString(user, 'email');
      final String role =
          _readRequiredString(user, 'role');

      await SessionManager.saveAccessToken(
        rawToken,
      );

      try {
        await SessionManager.saveUser(
          id: rawUserId.toInt(),
          firstName: firstName,
          lastName: lastName,
          email: userEmail,
          role: role,
        );
      } catch (_) {
        // Prevent a partial session when profile persistence fails.
        await SessionManager.logout();
        rethrow;
      }

      if (!mounted) return;

      _showMessage('Login successful!');

      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return const MainScreen();
          },
        ),
      );
    } on SignInException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } on FormatException {
      if (!mounted) return;

      _showMessage(
        'The server returned an invalid response.',
      );
    } catch (error, stackTrace) {
      debugPrint('Sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        'Unable to sign in. Check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Map<String, dynamic> _decodeResponse(
    String responseBody,
  ) {
    if (responseBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(responseBody);

    if (decoded is! Map) {
      throw const FormatException(
        'Invalid server response.',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  String _readRequiredString(
    Map<String, dynamic> source,
    String key,
  ) {
    final dynamic value = source[key];

    if (value is! String || value.trim().isEmpty) {
      throw const SignInException(
        'The server returned incomplete user information.',
      );
    }

    return value.trim();
  }

  String? _readServerMessage(
    Map<String, dynamic> responseData,
  ) {
    final dynamic message = responseData['message'];

    if (message is String &&
        message.trim().isNotEmpty) {
      return message.trim();
    }

    return null;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 20),
                Text(
                  'Sign In',
                  style: SignInStyles.titleStyle,
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to sync your scan history across devices.',
                  style: SignInStyles.descriptionStyle,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: emailController,
                  enabled: !_isSigningIn,
                  keyboardType:
                      TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[
                    AutofillHints.email,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  enabled: !_isSigningIn,
                  obscureText: !isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[
                    AutofillHints.password,
                  ],
                  onSubmitted: (_) {
                    _signIn();
                  },
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon:
                        passwordController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: _isSigningIn
                                    ? null
                                    : () {
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
                    onPressed: _isSigningIn
                        ? null
                        : () {
                            // TODO: Forgot password.
                          },
                    child: const Text(
                      'Forgot Password?',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isSigningIn ? null : _signIn,
                    child: Text(
                      _isSigningIn
                          ? 'Signing In...'
                          : 'Sign In',
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Don't have an account?",
                    ),
                    TextButton(
                      onPressed: _isSigningIn
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder:
                                      (BuildContext context) {
                                    return const SignUpScreen();
                                  },
                                ),
                              );
                            },
                      child: const Text('Sign Up'),
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

class SignInException implements Exception {
  const SignInException(this.message);

  final String message;

  @override
  String toString() => message;
}