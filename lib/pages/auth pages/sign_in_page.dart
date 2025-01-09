import 'dart:ui';

import '../../services/firebase_auth_methods.dart';
import '../../utils/form_validators.dart';

import '../../widgets/button.dart';
import '../../widgets/textfeild.dart';
import '../../routes/rotues_names.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // variable declaration
  final GlobalKey _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = true;

  // Textediting Controllars
  late TextEditingController _emailControllar;
  late TextEditingController _passwordControllar;

  // Firebase Email & Passoword Provider Sign IN.
  void signIN() {
    FirebaseAuthMethods.signInWithEmail(
      email: _emailControllar.text.trim(),
      password: _passwordControllar.text.trim(),
      context: context,
    );
  }

  @override
  void initState() {
    super.initState();
    _emailControllar = TextEditingController();
    _passwordControllar = TextEditingController();
  }

  @override
  void dispose() {
    _emailControllar.dispose();
    _passwordControllar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //! App Logo
              Image.asset(
                "assets/images/App Logo.png",
              ),
              SizedBox(height: 30),
              //! Text
              Text(
                "Sign In",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              //! Textfeilds
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 20.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFeildWidget(
                        controller: _emailControllar,
                        hintText: "E-mail",
                        validator: FormValidator.emailValidator,
                      ),
                      SizedBox(height: 16),
                      TextFeildWidget(
                        controller: _passwordControllar,
                        hintText: "Password",
                        validator: FormValidator.passwordValidator,
                        isPasswordVisible: _isPasswordVisible,
                        iconbutton: IconButton(
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: Color.fromARGB(255, 2, 239, 159),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                child: CustomButton(
                  voidCallback: signIN,
                  text: "Sign in",
                ),
              ),
              SizedBox(height: 25),
              //! Sign In Button
              InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(RoutesNames.forgotPasswordPage);
                },
                child: Text(
                  "Forgot password?",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 104, 101, 101),
                  ),
                ),
              ),
              SizedBox(height: 26),

              const Text("Or continue with"),

              const SizedBox(height: 26),

              // continue with Google or Facebook
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      FirebaseAuthMethods.signInWithGoogle(context: context);
                    },
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      elevation: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Image.asset(
                              "assets/images/Google_logo.png",
                              height: 40,
                              width: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      FirebaseAuthMethods.signInwithFacebook(context: context);
                    },
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              "assets/images/Facebook_logo.png",
                              height: 40,
                              width: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              //! Don't have account?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 104, 101, 101),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(RoutesNames.signUpPage);
                    },
                    child: Text(
                      " Sign up",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 2, 239, 159),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
