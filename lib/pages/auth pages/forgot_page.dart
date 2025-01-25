import '../../services/firebase_auth_methods.dart';
import '../../utils/form_validators.dart';

import '../../widgets/button.dart';
import '../../widgets/textfeild.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Controller for managing the email input field
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Method to send a password reset link to the user's email
  void sendPasswordResetEmail() {
    FirebaseAuthMethods.forgotEmailPassword(
      email: _emailController.text.trim(),
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Display the app logo
              Image.asset(
                MediaQuery.of(context).platformBrightness == Brightness.light ? "assets/logo/Logo_light_theme.png" : "assets/logo/Logo_dark_theme.png",
                height: 120,
              ),
              const SizedBox(height: 60),
              // Display the page title
              const Text(
                "Forgot Password",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Don't worry, it happens to the best of us. Enter your email, and we'll send you a password reset link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 104, 101, 101) : const Color.fromARGB(255, 216, 204, 204),
                  ),
                ),
              ),
              // Email input field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 20.0,
                ),
                child: Column(
                  children: [
                    TextFeildWidget(
                      controller: _emailController,
                      hintText: "Email",
                      validator: FormValidator.emailValidator,
                    ),
                  ],
                ),
              ),
              // Button to initiate the password reset process
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                child: CustomButton(
                  voidCallback: sendPasswordResetEmail,
                  text: "Next",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
