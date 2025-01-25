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
  // Variable declarations
  final GlobalKey _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = true;

  // Text editing controllers
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  // Method to sign in using Firebase Email & Password Provider
  void signIn() {
    FirebaseAuthMethods.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      context: context,
    );
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              // App logo
              Image.asset(
                MediaQuery.of(context).platformBrightness == Brightness.light ? "assets/logo/Logo_light_theme.png" : "assets/logo/Logo_dark_theme.png",
                height: 120,
              ),
              const SizedBox(height: 50),
              // Page title
              Text(
                "Sign In",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              // Input fields
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
                        controller: _emailController,
                        hintText: "E-mail",
                        validator: FormValidator.emailValidator,
                      ),
                      const SizedBox(height: 16),
                      TextFeildWidget(
                        controller: _passwordController,
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
                            color: const Color.fromARGB(255, 2, 239, 159),
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
                  voidCallback: signIn,
                  text: "Sign in",
                ),
              ),
              const SizedBox(height: 25),
              // Forgot password link
              InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(RoutesNames.forgotPasswordPage);
                },
                child: Text(
                  "Forgot password?",
                  style: TextStyle(
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 104, 101, 101) : const Color.fromARGB(255, 216, 204, 204),
                  ),
                ),
              ),
              const SizedBox(height: 26),

              Text(
                "Or continue with",
                style: TextStyle(
                  color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 104, 101, 101) : const Color.fromARGB(255, 216, 204, 204),
                ),
              ),

              const SizedBox(height: 26),

              // Continue with Google or Facebook
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      FirebaseAuthMethods.signInWithGoogle(context: context);
                    },
                    child: MediaQuery.of(context).platformBrightness == Brightness.light
                        ? Card(
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
                          )
                        : Card(
                            color: const Color.fromARGB(255, 235, 229, 229),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                            elevation: 8,
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
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      FirebaseAuthMethods.signInwithFacebook(context: context);
                    },
                    child: MediaQuery.of(context).platformBrightness == Brightness.light
                        ? Card(
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
                                    "assets/images/Facebook_logo.png",
                                    height: 40,
                                    width: 40,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Card(
                            color: const Color.fromARGB(255, 235, 229, 229),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                            elevation: 8,
                            child: Padding(
                              padding: const EdgeInsets.all(7),
                              child: Image.asset(
                                "assets/images/Facebook_logo.png",
                                height: 40,
                                width: 40,
                              ),
                            ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              // Sign up prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 104, 101, 101) : const Color.fromARGB(255, 216, 204, 204),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(RoutesNames.signUpPage);
                    },
                    child: const Text(
                      " Sign up",
                      style: TextStyle(
                        color: Color.fromARGB(255, 2, 239, 159),
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
