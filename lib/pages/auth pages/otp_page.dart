import 'dart:async';

import '../../services/firebase_auth_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

class OtpPage extends StatefulWidget {
  final String fullname;
  final String email;
  final String password;

  const OtpPage({
    super.key,
    required this.fullname,
    required this.email,
    required this.password,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  // Variable declaration.
  late TextEditingController pinputController;

  // Variables for OTP Timer.
  bool resentButton = true;
  int minutes = 0;
  int seconds = 0;
  Duration duration = const Duration(seconds: 5);
  Timer? timer;
  int incrementSecond = 0;

  void startTimer() {
    duration = Duration(seconds: 120 + incrementSecond);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (duration.inSeconds > 0) {
        duration -= const Duration(seconds: 1);
        minutes = duration.inMinutes;
        seconds = duration.inSeconds % 60;
        setState(() {});
      } else {
        timer.cancel();
        resentButton = true;
        incrementSecond += 240;
        duration = Duration(seconds: 120 + incrementSecond);
        setState(() {});
      }
    });
  }

  // Method to reset the timer and buttons to default when the user clicks the back button.
  // This handles cases where the user accidentally presses the back button.
  void resetTimerAndBtn() {
    timer!.cancel();
    resentButton = false;
    duration = Duration(seconds: 120 + incrementSecond);
  }

  // Method to verify the OTP.
  void verifyOTP() {
    FirebaseAuthMethods.verifyEmailOTP(
      context: context,
      fullName: widget.fullname,
      email: widget.email,
      password: widget.password,
      emailOTP: pinputController.text.trim(),
    );
  }

  // Method to resend the OTP.
  void resentOTP() {
    // Restart the timer and disable the OTP resend button.
    startTimer();
    resentButton = false;

    // Uncomment the following lines to enable OTP resend functionality.
    FirebaseAuthMethods.resentEmailOTP(
      email: widget.email,
      context: context,
    );
  }

  @override
  void initState() {
    super.initState();
    pinputController = TextEditingController();
  }

  @override
  void dispose() {
    pinputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int initialMinutes = incrementSecond ~/ 60;
    int initialSeconds = incrementSecond % 60;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              //! App Logo
              Image.asset(
                MediaQuery.of(context).platformBrightness == Brightness.light ? "assets/logo/Logo_light_theme.png" : "assets/logo/Logo_dark_theme.png",
                height: 120,
              ),
              const SizedBox(height: 30),
              const Text(
                "Check your email for a code",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Please enter the code sent to your email address.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 104, 101, 101) : const Color.fromARGB(255, 216, 204, 204),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              // Pinput Widget.
              Pinput(
                autofocus: true,
                controller: pinputController,
                length: 6,
                keyboardType: TextInputType.number,
                onCompleted: (value) {
                  verifyOTP();
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                defaultPinTheme: const PinTheme(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Color.fromARGB(255, 179, 179, 179)),
                      right: BorderSide(color: Color.fromARGB(255, 179, 179, 179)),
                      top: BorderSide(color: Color.fromARGB(255, 179, 179, 179)),
                      bottom: BorderSide(color: Color.fromARGB(255, 179, 179, 179)),
                    ),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: Color.fromARGB(184, 217, 250, 250),
                  ),
                  textStyle: TextStyle(fontSize: 24, color: Colors.black),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                resentButton ? "${initialMinutes.toString().padLeft(2, '0')} : ${initialSeconds.toString().padLeft(2, '0')}" : "${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}",
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code?",
                    style: TextStyle(fontSize: 15),
                  ),
                  GestureDetector(
                    onTapDown: (_) {
                      if (resentButton) {
                        resentOTP();
                      }
                    },
                    child: const Text(
                      " Resend code",
                      style: TextStyle(
                        color: Color.fromARGB(255, 2, 239, 159),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
