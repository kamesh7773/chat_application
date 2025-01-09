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
  // Textediting controllars
  late final TextEditingController _emailControllar;

  @override
  void initState() {
    super.initState();
    _emailControllar = TextEditingController();
  }

  @override
  void dispose() {
    _emailControllar.dispose();
    super.dispose();
  }

  // Method that sends password reset link on users email.
  void sentPasswordResetEmail() {
    FirebaseAuthMethods.forgotEmailPassword(
      email: _emailControllar.text.trim(),
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
              SizedBox(height: 60),
              //! App Logo
              Image.asset(
                "assets/images/App Logo.png",
              ),
              SizedBox(height: 30),
              //! Text
              Text(
                "Forgot Password",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Don't worry, sometimes people forget too. Enter your email, and we will send you a password reset link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
              //! Textfeilds
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 20.0,
                ),
                child: Column(
                  children: [
                    TextFeildWidget(
                      controller: _emailControllar,
                      hintText: "Email",
                      validator: FormValidator.emailValidator,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                child: CustomButton(
                  voidCallback: sentPasswordResetEmail,
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
