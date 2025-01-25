import '../../services/firebase_auth_methods.dart';
import '../../utils/form_validators.dart';

import '../../widgets/button.dart';
import '../../widgets/textfeild.dart';
import '../../routes/rotues_names.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Key for validating the sign-up form
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();
  bool _isPasswordVisible = true;
  bool _isConfirmPasswordVisible = true;
  String? errorText;

  // Controllers for text input fields
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // Method to handle sign-up with email and password
  void emailPasswordSignUp() {
    // Validate that the password and confirm password fields match
    if (_passwordController.value.text == _confirmPasswordController.value.text && _signUpFormKey.currentState!.validate()) {
      setState(() {
        errorText = null;
      });

      FirebaseAuthMethods.signUpWithEmail(
        context: context,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _confirmPasswordController.text.trim(),
      );
    } else {
      setState(() {
        errorText = "Passwords do not match";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _signUpFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display the app logo
                Image.asset(
                  MediaQuery.of(context).platformBrightness == Brightness.light ? "assets/logo/Logo_light_theme.png" : "assets/logo/Logo_dark_theme.png",
                  height: 120,
                ),
                const SizedBox(height: 60),
                // Display the page title
                Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                // Input fields for user details
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    children: [
                      TextFeildWidget(
                        controller: _fullNameController,
                        hintText: "Full name",
                        validator: FormValidator.firstNameValidator,
                      ),
                      const SizedBox(height: 16),
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
                        errorText: errorText,
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
                      const SizedBox(height: 16),
                      TextFeildWidget(
                        controller: _confirmPasswordController,
                        hintText: "Confirm password",
                        validator: FormValidator.passwordValidator,
                        isPasswordVisible: _isConfirmPasswordVisible,
                        errorText: errorText,
                        iconbutton: IconButton(
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: const Color.fromARGB(255, 2, 239, 159),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Button to submit the sign-up form
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                  ),
                  child: CustomButton(
                    voidCallback: emailPasswordSignUp,
                    text: "Sign up",
                  ),
                ),
                const SizedBox(height: 25),
                // Prompt for users who already have an account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(
                        color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 104, 101, 101) : const Color.fromARGB(255, 216, 204, 204),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RoutesNames.signInPage,
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: const Text(
                        " Sign in",
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
      ),
    );
  }
}
