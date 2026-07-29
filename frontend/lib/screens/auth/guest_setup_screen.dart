import 'package:flutter/material.dart';
import '../../styles/screens/auth/guest_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../main/main_screen.dart';

class GuestSetupScreen extends StatefulWidget {
  const GuestSetupScreen({super.key});

  @override
  State<GuestSetupScreen> createState() => _GuestSetupScreenState();
}

class _GuestSetupScreenState extends State<GuestSetupScreen> {
  final TextEditingController _nicknameController =
      TextEditingController();

  String _selectedRole = "Student";

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: GuestStyles.backgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: GuestStyles.backgroundColor,
        foregroundColor: GuestStyles.primaryColor,
        title: Text(
          "Continue Offline",
          style: GuestStyles.roleTitleStyle.copyWith(
            color: GuestStyles.primaryColor,
          ),
        ),
      ),

      body: SafeArea(
  child: SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    child: Padding(
      padding: GuestStyles.pagePadding,

      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              48,
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

             const SizedBox(
                height: GuestStyles.titleTopSpacing,
              ),

              const Text(
              "Use TactileLens without creating an account.",
              style: GuestStyles.titleStyle,
              ),

             const SizedBox(
              height: GuestStyles.titleBottomSpacing,
              ),

              const Text(
              "Choose a nickname and your role. Your data will only be stored on this device.",
              style: GuestStyles.descriptionStyle,
            ),

             const SizedBox(
              height: GuestStyles.descriptionBottomSpacing,
            ),

              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: "Nickname",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

             const SizedBox(
              height: GuestStyles.nicknameBottomSpacing,
            ),

             const Text(
              "Select your role",
              style: GuestStyles.roleTitleStyle,
            ),

             const SizedBox(
              height: GuestStyles.roleTitleBottomSpacing,
            ),

              RadioListTile<String>(
                value: "Student",
                groupValue: _selectedRole,
                title: const Text("Student"),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),

              RadioListTile<String>(
                value: "Educator",
                groupValue: _selectedRole,
                title: const Text("Educator"),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),

              const SizedBox(
                height: GuestStyles.buttonTopSpacing,
              ),

              SizedBox(
                width: double.infinity,
                height: GuestStyles.buttonHeight,
                child: ElevatedButton(
                  onPressed: () async {
                    final nickname = _nicknameController.text.trim();

                    if (nickname.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter a nickname."),
                        ),
                      );
                      return;
                    }

                    await SessionManager.saveGuest(
                      nickname: nickname,
                      role: _selectedRole,
                    );

                    if (!mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GuestStyles.primaryColor,
                  ),
                  child: const Text(
                    "Continue",
                    style: GuestStyles.buttonTextStyle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}