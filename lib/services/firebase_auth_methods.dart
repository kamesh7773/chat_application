import 'package:chat_application/services/firebase_firestore_methods.dart';

import 'message_encrption_service.dart';

import 'zego_methods.dart';

import '../routes/rotues_names.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/internet_checker.dart';
import '../widgets/diolog_box.dart';
import '../widgets/progress_indicator.dart';
import 'email_auth_backend.dart';

class FirebaseAuthMethods {
  // Variables related to Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestoreDB = FirebaseFirestore.instance;

  // Helper method to update shared preferences with user data
  static Future<void> _updateSharedPreferences(Map<String, dynamic> userData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("name", userData["name"]);
    await prefs.setString("email", userData["email"]);
    await prefs.setString("imageUrl", userData["imageUrl"]);
    await prefs.setString("provider", userData["provider"]);
    await prefs.setString("userID", userData["userID"]);
    await prefs.setBool('isLogin', true);
  }

  // --------------------
  // Email Authentication
  // --------------------

  //! Email & Password Sign-Up Method
  static Future<void> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Show progress indicator
      ProgressIndicators.showProgressIndicator(context);

      // Check if the email exists with the "Email & Password" provider in the users collection
      QuerySnapshot queryForEmailAndProvider = await _firestoreDB.collection('users').where("email", isEqualTo: email).where("provider", isEqualTo: "Email & Password").get();

      // If the email already exists with the Email & Password provider
      if (queryForEmailAndProvider.docs.isNotEmpty && context.mounted) {
        Navigator.of(context).pop();
        PopUpWidgets.diologbox(
          context: context,
          title: "Email already used",
          content: "The email address is already in use by another account.",
        );
      }
      // If the email doesn't exist or uses a different provider
      else {
        if (context.mounted) {
          try {
            // Send OTP to the user's email address
            await EmailOtpAuth.sendOTP(email: email);

            if (context.mounted) {
              Navigator.pop(context);
            }

            // Check internet connection before proceeding
            bool isInternet = await InternetChecker.checkInternet();

            // Show error if no internet connection
            if (isInternet && context.mounted) {
              PopUpWidgets.diologbox(
                context: context,
                title: "Sign up failed",
                content: "Connection failed. Please check your network connection and try again.",
              );
            }
            // If internet is available, redirect to the OTP page
            else if (!isInternet && context.mounted) {
              Navigator.of(context).pushNamed(
                RoutesNames.otpPage,
                arguments: {
                  "fullName": fullName,
                  "email": email,
                  "password": password,
                },
              );
            }
          }
          //? Handling email OTP errors
          catch (error) {
            if (error == "ClientException with SocketException: Failed host lookup: 'definite-emilee-kamesh-564a9766.koyeb.app' (OS Error: No address associated with hostname, errno = 7), uri=https://definite-emilee-kamesh-564a9766.koyeb.app/api/send-otp") {
              if (context.mounted) {
                // Popping out the progress indicator
                Navigator.of(context).pop();

                PopUpWidgets.diologbox(
                  context: context,
                  title: "Network failure",
                  content: "Connection failed. Please check your network connection and try again.",
                );
              }
            } else {
              if (context.mounted) {
                // Popping out the progress indicator
                Navigator.of(context).pop();

                PopUpWidgets.diologbox(
                  context: context,
                  title: "Network Error",
                  content: error.toString(),
                );
              }
            }
          }
        }
      }
    }
    // Handle Firebase Firestore exceptions
    on FirebaseException catch (error) {
      if (error.message == "A network error (such as timeout, interrupted connection or unreachable host) has occurred." && context.mounted) {
        // Popping out the progress indicator
        Navigator.of(context).pop();

        PopUpWidgets.diologbox(
          context: context,
          title: "Email already used",
          content: "The email address is already in use by another account.",
        );
      } else {
        if (context.mounted) {
          // Popping out the progress indicator
          Navigator.of(context).pop();

          PopUpWidgets.diologbox(
            context: context,
            title: error.toString(),
            content: error.message!,
          );
        }
      }
    }
  }

  //! Verify Email OTP and create user account
  static Future<void> verifyEmailOTP({
    required String fullName,
    required String email,
    required String password,
    required emailOTP,
    required BuildContext context,
  }) async {
    // Try and catch block for Email OTP Auth API
    try {
      ProgressIndicators.showProgressIndicator(context);

      // Verify the email OTP
      var res = await EmailOtpAuth.verifyOtp(otp: emailOTP);

      // If OTP verification is successful, create user account and store data
      if (res["message"] == "OTP Verified") {
        // Try and catch block for Firebase Email Sign-Up Auth
        try {
          // Create user account in Firebase Auth
          await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Method for creating RSA Public and Private keys for Message Encryption.
          await MessageEncrptionService().generateKeys();

          // Retrieving the RSA Key
          final key = await MessageEncrptionService().returnKeys();

          // Store user data in Firestore
          await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).set({
            "name": fullName,
            "email": email,
            "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSQq6gaTf6N93kzolH98ominWZELW881HqCgw&s",
            "isOnline": true,
            "isTyping": false,
            "isInsideChatRoom": false,
            "lastSeen": DateTime.now(),
            "unSeenMessages": [],
            "provider": "Email & Password",
            "rsaPublicKey": key.rsaPublicKey,
            "userID": _auth.currentUser!.uid,
            "callLogs": [],
          });

          // Fetch current user info from Firestore
          final currentUserInfo = await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).get();

          final userData = currentUserInfo.data();

          // Store user data in SharedPreferences
          await _updateSharedPreferences(userData!);

          // Method for initializing Zego package services.
          await ZegoMethods.onUserLogin();

          // adding the FCM Token in user DB.
          FirebaseFireStoreMethods().updateFcmToken();

          // Redirect to HomePage after successful signup
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.of(context).pushNamedAndRemoveUntil(
              RoutesNames.bottomNavigationBar,
              (Route<dynamic> route) => false,
            );
          }
        }
        // Handle Firebase Auth exceptions during account creation
        on FirebaseAuthException catch (error) {
          if (error.message == "A network error (such as timeout, interrupted connection or unreachable host) has occurred." && context.mounted) {
            Navigator.of(context).pop();
            PopUpWidgets.diologbox(
              context: context,
              title: "Sign up failed",
              content: "Connection failed. Please check your network connection and try again.",
            );
          } else {
            if (context.mounted) {
              Navigator.of(context).pop();
              PopUpWidgets.diologbox(
                context: context,
                title: "Network Error",
                content: error.toString(),
              );
            }
          }
        }
      } else if (res["data"] == "Invalid OTP" && context.mounted) {
        Navigator.of(context).pop();
        PopUpWidgets.diologbox(
          context: context,
          title: "Invalid OTP",
          content: "It seems like the OTP is incorrect. Please try again or resend the OTP.",
        );
      } else if (res["data"] == "OTP Expired" && context.mounted) {
        Navigator.of(context).pop();
        PopUpWidgets.diologbox(
          context: context,
          title: "OTP Expired",
          content: "Your OTP has expired. Please request a new code to proceed.",
        );
      }
    }
    // Handle OTP verification errors
    catch (error) {
      if (error == "ClientException with SocketException: Failed host lookup: 'definite-emilee-kamesh-564a9766.koyeb.app' (OS Error: No address associated with hostname, errno = 7), uri=https://definite-emilee-kamesh-564a9766.koyeb.app/api/verify-otp") {
        if (context.mounted) {
          Navigator.pop(context);
          PopUpWidgets.diologbox(
            context: context,
            title: "Sign up failed",
            content: "Connection failed. Please check your network connection and try again.",
          );
        }
      } else {
        if (context.mounted) {
          Navigator.pop(context);
          PopUpWidgets.diologbox(
            context: context,
            title: "Network Error",
            content: error.toString(),
          );
        }
      }
    }
  }

  //! Resend OTP to Email Method
  static Future<void> resentEmailOTP({required email, required BuildContext context}) async {
    try {
      // Show the progress indicator
      ProgressIndicators.showProgressIndicator(context);
      await EmailOtpAuth.sendOTP(email: email);
      // Pop the progress indicator
      if (context.mounted) {
        Navigator.pop(context);

        PopUpWidgets.diologbox(
          context: context,
          title: "OTP sent",
          content: "Your OTP has been successfully sent to your registered email address. Please check your inbox.",
        );
      }
    }
    //? Handling email OTP errors
    catch (error) {
      if (error == "ClientException with SocketException: Failed host lookup: 'definite-emilee-kamesh-564a9766.koyeb.app' (OS Error: No address associated with hostname, errno = 7), uri=https://definite-emilee-kamesh-564a9766.koyeb.app/api/send-otp") {
        if (context.mounted) {
          // Pop the progress indicator
          Navigator.of(context).pop();

          PopUpWidgets.diologbox(
            context: context,
            title: "Network failure",
            content: "Connection failed. Please check your network connection and try again.",
          );
        }
      } else {
        if (context.mounted) {
          // Pop the progress indicator
          Navigator.of(context).pop();
        }
      }
    }
  }

  //! Email & Password Login Method
  static Future<void> signInWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Show CircularProgressIndicator
      ProgressIndicators.showProgressIndicator(context);

      // Method for signing in the user with email & password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch current userId info from the "users" collection
      final currentUserInfo = await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).get();

      // Reference to the current user's document in the main collection
      final DocumentReference user = _firestoreDB.collection("users").doc(_auth.currentUser!.uid);

      await user.update({
        "isOnline": true,
        "isTyping": false,
        "isInsideChatRoom": false,
        "lastSeen": DateTime.now(),
      });

      final userData = currentUserInfo.data();

      // Create an instance of Shared Preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Write current user info data to SharedPreferences
      await prefs.setString("name", userData!["name"]);
      await prefs.setString("email", userData["email"]);
      await prefs.setString("imageUrl", userData["imageUrl"]);
      await prefs.setBool("isOnline", userData["isOnline"]);
      await prefs.setString("lastSeen", userData["lastSeen"].toString());
      await prefs.setString("provider", userData["provider"]);
      await prefs.setString("userID", userData["userID"]);

      // Set isLogin to "true"
      await prefs.setBool('isLogin', true);

      // Method for initializing Zego package services.
      await ZegoMethods.onUserLogin();

      // adding the FCM Token in user DB.
      await FirebaseFireStoreMethods().updateFcmToken();

      // After successful login, redirect the user to the HomePage
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.of(context).pushNamedAndRemoveUntil(
          RoutesNames.bottomNavigationBar,
          (Route<dynamic> route) => false,
        );
      }
    }
    // Handle login auth exceptions
    on FirebaseAuthException catch (error) {
      if (error.message == "A network error (such as timeout, interrupted connection or unreachable host) has occurred." && context.mounted) {
        Navigator.pop(context);
        PopUpWidgets.diologbox(
          context: context,
          title: "Sign up failed",
          content: "Connection failed. Please check your network connection and try again.",
        );
      } else if (error.message == "The supplied auth credential is incorrect, malformed or has expired." && context.mounted) {
        Navigator.pop(context);
        PopUpWidgets.diologbox(
          context: context,
          title: "Invalid credentials",
          content: "Your entered email and password are invalid. Please check your email & password and try again.",
        );
      } else {
        if (context.mounted) {
          Navigator.pop(context);
          PopUpWidgets.diologbox(
            context: context,
            title: "Network Error",
            content: error.toString(),
          );
        }
      }
    }
  }

  //! Email & Password Forgot Password/Reset Method
  static Future<bool> forgotEmailPassword({
    required String email,
    required BuildContext context,
  }) async {
    // Variable declaration
    late bool associatedEmail;
    try {
      // Show Progress Indicator
      ProgressIndicators.showProgressIndicator(context);
      //* First, we check if the entered email address is already present & its provider is "Email & Password" in the "users" collection by querying Firestore's "users" Collection.
      // Search for Email Address & "Email & Password" provider in the "users" collection at once
      QuerySnapshot queryForEmailAndProvider = await _firestoreDB.collection('users').where("email", isEqualTo: email).where("provider", isEqualTo: "Email & Password").get();

      // If the entered Email address is already present in the "users" collection and the Provider is "Email & Password"
      // it means that the user has entered the correct email address, and we can send the Forgot password link to the user's Email Address.
      if (queryForEmailAndProvider.docs.isNotEmpty && context.mounted) {
        // Method for sending forgot password link to the user
        await _auth.sendPasswordResetEmail(email: email);
        // Pop the Progress Indicator
        if (context.mounted) {
          Navigator.pop(context);
        }
        // Redirect user to ForgotPasswordHoldPage
        if (context.mounted) {
          PopUpWidgets.diologbox(
            context: context,
            title: "Email Sent",
            content: "Check your email for the password reset link and follow the steps to reset your password.",
          );
        }

        associatedEmail = true;
      }
      // If the entered Email address is not present in the "users" collection or the entered email Provider is not "Email & Password" in the "users" collection
      // that means the user entered an Email that does not have an associated account in Firebase related to the "Email & Password" Provider.
      else {
        if (context.mounted) {
          // Pop the Progress Indicator
          Navigator.of(context).pop();

          PopUpWidgets.diologbox(
            context: context,
            title: "Email not found",
            content: "There is no associated account found with the entered Email.",
          );
        }
        associatedEmail = false;
      }
    }
    // Handle forgot password auth exceptions
    on FirebaseAuthException catch (error) {
      if (error.message == "A network error (such as timeout, interrupted connection or unreachable host) has occurred." && context.mounted) {
        Navigator.pop(context);
        PopUpWidgets.diologbox(
          context: context,
          title: "Network failure",
          content: "Connection failed. Please check your network connection and try again.",
        );
      } else if (error.message == "The supplied auth credential is incorrect, malformed or has expired." && context.mounted) {
        Navigator.pop(context);
        PopUpWidgets.diologbox(
          context: context,
          title: "Invalid email",
          content: "Your entered email is invalid. Please check your email and try again.",
        );
      } else {
        if (context.mounted) {
          Navigator.pop(context);
          PopUpWidgets.diologbox(
            context: context,
            title: "Network Error",
            content: error.toString(),
          );
        }
      }
    }

    // Return email value
    return associatedEmail;
  }

  // ------------------------------------------
  // Methods related to Google Auth (OAuth 2.0)
  // ------------------------------------------

  //! Method for Google Sign-In/Sign-Up (For Google, we don't have separate methods for signIn/signUp)
  static Future<void> signInWithGoogle({required BuildContext context}) async {
    try {
      //? ------------------------
      //? Google Auth code for Web
      //? ------------------------
      // (For running Google Auth on a Web Browser, we need to add the Web Client ID (Web Client ID is available on Google Cloud Console
      //  Index.html file example: <meta name="google-signin-client_id" content="152173321595-lb4qla2alg7q3010hrip1p1i1ok997n9.apps.googleusercontent.com.apps.googleusercontent.com"> )
      //  Google Auth only runs on specific "Port 5000" for running the application example: "flutter run -d edge --web-hostname localhost --web-port 5000"
      if (kIsWeb) {
        //* First, create a googleProvider instance with the help of the GoogleAuthProvider class constructor.
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        //* Second, the provider needs some kind of user Google account info for the sign-in process.
        //*     There are multiple providers available on the Google official website you can check them out.
        googleProvider.addScope("email");

        //* Third, this code pops the Google signIn/signUp interface/UI like showing Google ID that is logged in user's browser
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);

        if (context.mounted) {
          ProgressIndicators.showProgressIndicator(context);
        }

        try {
          //* Fourth here we check the weather users document is already created or not (means if user document that we created with firebase user id is created or not)
          //* if it already not created that means user is signUp for first time if docuemnt named usersId is created or firebase then userID is already signUP and now he is siging up.
          DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.collection("users").doc(_auth.currentUser!.uid).get();

          if (documentSnapshot.exists) {
            // It mean user is already sign up now we updated some feild value on already created user docuemnts.
            // Reference to the current user's document in the main collection
            final DocumentReference user = _firestoreDB.collection("users").doc(_auth.currentUser!.uid);

            await user.update({
              "isOnline": true,
              "isTyping": false,
              "isInsideChatRoom": false,
              "lastSeen": DateTime.now(),
            });

            // Fetch current userId info from "users" collection
            final currentUserInfo = await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).get();

            final userData = currentUserInfo.data();

            // Create an instance of Shared Preferences
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("name", userData!["name"]);
            await prefs.setString("email", userData["email"]);
            await prefs.setString("imageUrl", userData["imageUrl"]);
            await prefs.setString("provider", userData["provider"]);
            await prefs.setString("userID", userData["userID"]);

            //* Sixth, set isLogin to "true"
            await prefs.setBool('isLogin', true);

            //* Seventh, after successfully signing in, redirect the user to the HomePage
            if (context.mounted) {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                RoutesNames.bottomNavigationBar,
                (Route<dynamic> route) => false,
              );
            }
          }
          // else user docuemnt is not present on firestore users collection it mens user is sign up for first time so...
          else {
            // Create "users" collection so we can store user-specific user data
            await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).set({
              "name": userCredential.additionalUserInfo!.profile!["name"],
              "email": userCredential.additionalUserInfo!.profile!["email"],
              "imageUrl": userCredential.additionalUserInfo!.profile!["picture"],
              "isOnline": true,
              "isTyping": false,
              "isInsideChatRoom": false,
              "lastSeen": DateTime.now(),
              "unSeenMessages": [],
              "provider": "Google",
              "userID": _auth.currentUser!.uid,
            });

            // Fetch current userId info from "users" collection
            final currentUserInfo = await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).get();

            final userData = currentUserInfo.data();

            // Create an instance of Shared Preferences
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("name", userData!["name"]);
            await prefs.setString("email", userData["email"]);
            await prefs.setString("imageUrl", userData["imageUrl"]);
            await prefs.setString("provider", userData["provider"]);
            await prefs.setString("userID", userData["userID"]);

            //* Sixth, set isLogin to "true"
            await prefs.setBool('isLogin', true);

            //* Seventh, after successfully signing in, redirect the user to the HomePage
            if (context.mounted) {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                RoutesNames.bottomNavigationBar,
                (Route<dynamic> route) => false,
              );
            }
          }
        }

        //? Handle exceptions for storing user info at Firestore DB
        on FirebaseAuthException catch (error) {
          if (error.message == "A network error (such as timeout, interrupted connection or unreachable host) has occurred." && context.mounted) {
            PopUpWidgets.diologbox(
              context: context,
              title: "Network failure",
              content: "Connection failed. Please check your network connection and try again.",
            );
          } else {
            if (context.mounted) {
              PopUpWidgets.diologbox(
                context: context,
                title: "Network Error",
                content: error.toString(),
              );
            }
          }
        }

        // If "userCredential.additionalUserInfo!.isNewUser" is "isNewUser" it means the user account is not present on our Firebase sign-in
        // console it means the user is being signed in/signed up with Google for the first time so we can store the information in Firestore "users" collection.
        // This code is used to detect when a user logs in with Google Provider for the first time and we can run some kind of logic on it.

        // if (userCredential.additionalUserInfo!.isNewUser) {}
      }
      //? --------------------------------
      //? Google Auth code for Android/IOS
      //? --------------------------------
      else {
        //* First, this code pops the Google signIn/signUp interface/UI like showing Google ID that is logged in user's devices
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        if (context.mounted) {
          ProgressIndicators.showProgressIndicator(context);
        }

        //! If the user clicks on the back button while the Google OAuth Popup is showing or dismisses the Google OAuth Pop by clicking anywhere on the screen then this code
        //! will pop out the Progress Indicator.
        if (googleUser == null && context.mounted) {
          Navigator.of(context).pop();
        }

        //! If the user does nothing and continues to Google OAuth Sign In then this code will be executed.
        else {
          //* Second, when the user clicks on the Pop Google Account then this code retrieves the GoogleSignInTokenData (accessToken/IdToken)
          final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

          // If accessToken or idToken is null then return nothing. (accessToken gets null when the user dismisses the Google account Pop Menu)
          if (googleAuth?.accessToken == null && googleAuth?.idToken == null) {
            return;
          }
          // If accessToken and idToken are not null only then we process to login
          else {
            //* Third, in the upper code (second code) we are retrieving the "GoogleSignInTokenData" Instance (googleAuth) now with the help of googleAuth instance we gonna
            //* retrieve the "accessToken" and idToken
            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth?.accessToken,
              idToken: googleAuth?.idToken,
            );

            //* Fourth, this code helps the user to sign in/sign up with a Google Account.
            // When the user clicks on the Popup Google ID's then this code will return all the User Google account information
            // (Info like: Google account user name, user IMG, user email is verified, etc.)
            UserCredential userCredential = await _auth.signInWithCredential(credential);

            try {
              //* Fifth here we check the weather users document is already created or not (means if user document that we created with firebase user id is created or not)
              //* if it already not created that means user is signUp for first time if docuemnt named usersId is created or firebase then userID is already signUP and now he is siging up.
              DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.collection("users").doc(_auth.currentUser!.uid).get();

              if (documentSnapshot.exists) {
                // It mean user is already sign up now we updated some feild value on already created user docuemnts.
                // Reference to the current user's document in the main collection
                final DocumentReference user = _firestoreDB.collection("users").doc(_auth.currentUser!.uid);

                await user.update({
                  "isOnline": true,
                  "isTyping": false,
                  "isInsideChatRoom": false,
                  "lastSeen": DateTime.now(),
                });

                // Fetch current userId info from "users" collection
                final currentUserInfo = await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).get();

                final userData = currentUserInfo.data();

                // Create an instance of Shared Preferences
                final SharedPreferences prefs = await SharedPreferences.getInstance();

                //* Sixth, write current User info data to SharedPreferences
                await prefs.setString("name", userData!["name"]);
                await prefs.setString("email", userData["email"]);
                await prefs.setString("imageUrl", userData["imageUrl"]);
                await prefs.setString("provider", userData["provider"]);
                await prefs.setString("userID", userData["userID"]);

                //* Seventh, set isLogin to "true"
                await prefs.setBool('isLogin', true);

                // Method for initializing Zego package services.
                await ZegoMethods.onUserLogin();

                // adding the FCM Token in user DB.
                await FirebaseFireStoreMethods().updateFcmToken();

                //* Eighth, after successfully signing in/signing up redirect the user to the HomePage
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    RoutesNames.bottomNavigationBar,
                    (Route<dynamic> route) => false,
                  );
                }
              }
              // else user docuemnt is not present on firestore users collection it mens user is sign up for first time so...
              else {
                // Method for creating RSA Public and Private keys for Message Encryption.
                await MessageEncrptionService().generateKeys();

                // Retrieving the RSA Key
                final key = await MessageEncrptionService().returnKeys();

                // Create "users" collection so we can store user-specific user datastore or user info inside the Firestore "users" collection.
                await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).set({
                  "name": userCredential.additionalUserInfo!.profile!["name"],
                  "email": userCredential.additionalUserInfo!.profile!["email"],
                  "imageUrl": userCredential.additionalUserInfo!.profile!["picture"],
                  "isOnline": true,
                  "isTyping": false,
                  "isInsideChatRoom": false,
                  "lastSeen": DateTime.now(),
                  "unSeenMessages": [],
                  "provider": "Google",
                  "rsaPublicKey": key.rsaPublicKey,
                  "userID": _auth.currentUser!.uid,
                  "callLogs": [],
                });

                // Fetch current userId info from "users" collection
                final currentUserInfo = await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).get();

                final userData = currentUserInfo.data();

                // Create an instance of Shared Preferences
                final SharedPreferences prefs = await SharedPreferences.getInstance();

                //* Sixth, write current User info data to SharedPreferences
                await prefs.setString("name", userData!["name"]);
                await prefs.setString("email", userData["email"]);
                await prefs.setString("imageUrl", userData["imageUrl"]);
                await prefs.setString("provider", userData["provider"]);
                await prefs.setString("userID", userData["userID"]);

                //* Seventh, set isLogin to "true"
                await prefs.setBool('isLogin', true);

                // Method for initializing Zego package services.
                await ZegoMethods.onUserLogin();

                // adding the FCM Token in user DB.
                await FirebaseFireStoreMethods().updateFcmToken();

                //* Eighth, after successfully signing in/signing up redirect the user to the HomePage
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    RoutesNames.bottomNavigationBar,
                    (Route<dynamic> route) => false,
                  );
                }
              }
            }

            //? Handle exceptions for storing user info at Firestore DB
            on FirebaseAuthException catch (error) {
              if (error.message == "A network error (such as timeout, interrupted connection or unreachable host) has occurred." && context.mounted) {
                PopUpWidgets.diologbox(
                  context: context,
                  title: "Network failure",
                  content: "Connection failed. Please check your network connection and try again.",
                );
              } else {
                if (context.mounted) {
                  PopUpWidgets.diologbox(
                    context: context,
                    title: "Network Error",
                    content: error.toString(),
                  );
                }
              }
            }

            //? If "userCredential.additionalUserInfo!.isNewUser" is "isNewUser" it means the user account is not present on our Firebase sign-in
            //? console it means the user is being signed in/signed up with Google for the first time so we can store the information in Firestore "users" collection.
            //? This code is used to detect when a user logs in with Google Provider for the first time and we can run some kind of logic on it.

            // if (userCredential.additionalUserInfo!.isNewUser) {}
          }
        }
      }
    }
    //? Handle errors related to Google SignIn/SignUp
    on FirebaseAuthException catch (error) {
      if (error.message == "A network error (such as timeout, interrupted connection or unreachable host) has occurred." && context.mounted) {
        Navigator.pop(context);
        PopUpWidgets.diologbox(
          context: context,
          title: "Network failure",
          content: "Connection failed. Please check your network connection and try again.",
        );
      } else {
        if (context.mounted) {
          Navigator.pop(context);
          PopUpWidgets.diologbox(
            context: context,
            title: "Network Error",
            content: error.toString(),
          );
        }
      }
    }
  }

  // --------------------------------
  // Methods related to Facebook Auth
  // --------------------------------

  //! Method for Facebook Sign-In/Sign-Up
  static Future<void> signInwithFacebook({required BuildContext context}) async {
    try {
      // Show Progress Indicator
      if (context.mounted) {
        ProgressIndicators.showProgressIndicator(context);
      }

      //* First, this code pops the Facebook signIn/signUp page in the browser on Android
      //* and if we are a web app then open Pop-Up Facebook signIn/signUp interface/UI in the web browser
      final LoginResult loginResult = await FacebookAuth.instance.login();

      //! If the user clicks on the back button while the Facebook Auth Browser Popup is showing or dismisses the Facebook Auth Browser PopUp by clicking anywhere on the screen then this code
      //! will pop out the Progress Indicator.
      if (loginResult.accessToken == null && context.mounted) {
        Navigator.of(context).pop();
      }

      //! If the user does nothing and continues to Facebook Auth browser Sign In then this code will be executed.
      else {
        //* Second, when the user gets login after entering their login password then this code retrieves the FacebookTokenData.
        final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);


        // If accessToken or idToken is null then return nothing.
        if (loginResult.accessToken == null) {
          return;
        }
        // If accessToken and idToken are not null only then we process to login
        else {
          //* Third, this method signs in the user with credentials
          final UserCredential userCredentail = await _auth.signInWithCredential(facebookAuthCredential);


          try {
            //* Fourth here we check the weather users document is already created or not (means if user document that we created with firebase user id is created or not)
            //* if it already not created that means user is signUp for first time if docuemnt named usersId is created or firebase then userID is already signUP and now he is siging up.
            DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.collection("users").doc(_auth.currentUser!.uid).get();

            if (documentSnapshot.exists) {
              // It mean user is already sign up now we updated some feild value on already created user docuemnts.
              // Reference to the current user's document in the main collection
              final DocumentReference user = _firestoreDB.collection("users").doc(_auth.currentUser!.uid);

              await user.update({
                "isOnline": true,
                "isTyping": false,
                "isInsideChatRoom": false,
                "lastSeen": DateTime.now(),
              });

              // Fetch current userId info from "users" collection
              final currentUserInfo = await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).get();

              final userData = currentUserInfo.data();

              // Create an instance of Shared Preferences
              final SharedPreferences prefs = await SharedPreferences.getInstance();

              //* Fifth, write current User info data to SharedPreferences
              await prefs.setString("name", userData!["name"]);
              await prefs.setString("email", userData["email"]);
              await prefs.setString("imageUrl", userData["imageUrl"]);
              await prefs.setString("provider", userData["provider"]);
              await prefs.setString("userID", userData["userID"]);

              //* Sixth, set isLogin to "true"
              await prefs.setBool('isLogin', true);

              // adding the FCM Token in user DB.
              await FirebaseFireStoreMethods().updateFcmToken();

              // Method for initializing Zego package services.
              await ZegoMethods.onUserLogin();

              //* Eighth, after successfully signing in redirect the user to the HomePage
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RoutesNames.bottomNavigationBar,
                  (Route<dynamic> route) => false,
                );
              }
            }
            // else user docuemnt is not present on firestore users collection it mens user is sign up for first time so...
            else {
              // Method for creating RSA Public and Private keys for Message Encryption.
              await MessageEncrptionService().generateKeys();

              // Retrieving the RSA Key
              final key = await MessageEncrptionService().returnKeys();

              // Create "users" collection so we can store user-specific user data
              await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).set({
                "name": userCredentail.additionalUserInfo!.profile!["name"],
                "email": userCredentail.additionalUserInfo!.profile!["email"],
                "imageUrl": userCredentail.additionalUserInfo!.profile!["picture"]["data"]["url"],
                "isOnline": true,
                "isTyping": false,
                "isInsideChatRoom": false,
                "lastSeen": DateTime.now(),
                "unSeenMessages": [],
                "provider": "Facebook",
                "rsaPublicKey": key.rsaPublicKey,
                "userID": _auth.currentUser!.uid,
                "callLogs": [],
              });

              // Fetch current userId info from "users" collection
              final currentUserInfo = await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).get();

              final userData = currentUserInfo.data();

              // Create an instance of Shared Preferences
              final SharedPreferences prefs = await SharedPreferences.getInstance();

              //* Fifth, write current User info data to SharedPreferences
              await prefs.setString("name", userData!["name"]);
              await prefs.setString("email", userData["email"]);
              await prefs.setString("imageUrl", userData["imageUrl"]);
              await prefs.setString("provider", userData["provider"]);
              await prefs.setString("userID", userData["userID"]);

              //* Sixth, set isLogin to "true"
              await prefs.setBool('isLogin', true);

              // adding the FCM Token in user DB.
              await FirebaseFireStoreMethods().updateFcmToken();

              // Method for initializing Zego package services.
              await ZegoMethods.onUserLogin();

              //* Seventh, after successfully signing in redirect the user to the HomePage
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RoutesNames.bottomNavigationBar,
                  (Route<dynamic> route) => false,
                );
              }
            }
          }

          //? Handle exceptions for storing user info at Firestore DB
          on FirebaseAuthException catch (error) {
            if (error.message == "A network error (such as timeout, interrupted connection or unreachable host) has occurred." && context.mounted) {
              PopUpWidgets.diologbox(
                context: context,
                title: "Network failure",
                content: "Connection failed. Please check your network connection and try again.",
              );
            } else {
              if (context.mounted) {
                PopUpWidgets.diologbox(
                  context: context,
                  title: "Network Error",
                  content: error.toString(),
                );
              }
            }
          }
        }
      }
    }

    //? Handle errors related to Facebook SignIn/SignUp
    on FirebaseAuthException catch (error) {
      if (error.message == "A network error (such as timeout, interrupted connection or unreachable host) has occurred." && context.mounted) {
        PopUpWidgets.diologbox(
          context: context,
          title: "Network failure",
          content: "Connection failed. Please check your network connection and try again.",
        );
      } else if (error.message == "[firebase_auth/account-exists-with-different-credential] An account already exists with the same email address but different sign-in credentials. Sign in using a provider associated with this email address." && context.mounted) {
        PopUpWidgets.diologbox(
          context: context,
          title: "Email already used",
          content: "The email address is already in use by another account.",
        );
      } else {
        if (context.mounted) {
          PopUpWidgets.diologbox(
            context: context,
            title: "Network Error",
            content: error.toString(),
          );
        }
      }
    }
  }

  // ----------------------------------------
  // Methods related to Firebase Auth SignOut
  // ----------------------------------------

  //! Method for SignOut Firebase Provider auth account
  static Future<void> singOut({required BuildContext context}) async {
    try {
      // Remove the entries of Shared Preferences data
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('name');
      prefs.remove('email');
      prefs.remove('imageUrl');
      prefs.remove('provider');
      prefs.remove('userID');

      // Set isLogin to false
      await prefs.setBool('isLogin', false);

      // Reference to the current user's document in the main collection
      final DocumentReference user = _firestoreDB.collection("users").doc(_auth.currentUser!.uid);

      await user.update({
        "isOnline": false,
        "isTyping": false,
        "isInsideChatRoom": false,
        "lastSeen": DateTime.now(),
      });

      // SignOut code for Google SignIn/SignUp
      if (await GoogleSignIn().isSignedIn()) {
        // Sign out the user from Google account
        GoogleSignIn().signOut();
      }

      // This method signs out the user from all Firebase auth Providers
      await _auth.signOut();

      // Discarding the zegoCloud running services in background.
      ZegoMethods.onUserLogout();

      // Redirecting user to Welcome Page
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RoutesNames.signInPage,
          (Route<dynamic> route) => false,
        );
      }
    }
    //? Handle errors related to Google SignIn/SignUp
    on FirebaseAuthException catch (error) {
      if (error.message == "A network error (such as timeout, interrupted connection or unreachable host) has occurred." && context.mounted) {
        Navigator.of(context).pop();
        PopUpWidgets.diologbox(
          context: context,
          title: "Sign up failed",
          content: "Connection failed. Please check your network connection and try again.",
        );
      } else {
        if (context.mounted) {
          Navigator.of(context).pop();
          PopUpWidgets.diologbox(
            context: context,
            title: "Network Error",
            content: error.message.toString(),
          );
        }
      }
    }
  }

  // ---------------------------------------------
  // Method to Retrieve User Authentication Status
  // ---------------------------------------------

  //! Method that checks if the user is logged in or not with any Provider.
  static Future<bool> isUserLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLogin = prefs.getBool('isLogin') ?? false;
    return isLogin;
  }

  //! Method for fetching Data.
  static Future<Map<String, dynamic>?> getUserData() async {
    final currentUserInfo = await _firestoreDB.collection("users").doc(_auth.currentUser!.uid).get();
    final userData = currentUserInfo.data();
    return userData;
  }
}
