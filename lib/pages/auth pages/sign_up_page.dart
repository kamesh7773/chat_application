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
  // variable declaration
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();
  bool _isPasswordVisible = true;
  bool _isConfirmPasswordVisible = true;
  String? errorText;

  // Textediting Controllars declaration
  late TextEditingController _fullNameControllar;
  late TextEditingController _emailControllar;
  late TextEditingController _passwordControllar;
  late TextEditingController _confirmPasswordControllar;

  // Method for Email & Password Sign UP._
  void emailPasswordSignUP() {
    // First we validated that both password and confirmpassword textfeild text are same
    if (_passwordControllar.value.text == _confirmPasswordControllar.value.text && _signUpFormKey.currentState!.validate()) {
      setState(() {
        errorText = null;
      });

      FirebaseAuthMethods.signUpWithEmail(
        context: context,
        fullName: _fullNameControllar.text.trim(),
        email: _emailControllar.text.trim(),
        password: _confirmPasswordControllar.text.trim(),
      );
    } else {
      setState(() {
        errorText = "Password does not match";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fullNameControllar = TextEditingController();
    _emailControllar = TextEditingController();
    _passwordControllar = TextEditingController();
    _confirmPasswordControllar = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameControllar.dispose();
    _emailControllar.dispose();
    _passwordControllar.dispose();
    _confirmPasswordControllar.dispose();
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
                //! App Logo
                Image.asset(
                  "assets/images/App Logo.png",
                ),
                SizedBox(height: 30),
                //! Text
                Text(
                  "Sign Up",
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
                  child: Column(
                    children: [
                      TextFeildWidget(
                        controller: _fullNameControllar,
                        hintText: "Full name",
                        validator: FormValidator.firstNameValidator,
                      ),
                      SizedBox(height: 16),
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
                        errorText: errorText,
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
                      SizedBox(height: 16),
                      TextFeildWidget(
                        controller: _confirmPasswordControllar,
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
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: Color.fromARGB(255, 2, 239, 159),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                  ),
                  child: CustomButton(
                    voidCallback: emailPasswordSignUP,
                    text: "Sign up",
                  ),
                ),
                SizedBox(height: 25),
                //! Don't have account?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 104, 101, 101),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RoutesNames.signInPage,
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Text(
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
