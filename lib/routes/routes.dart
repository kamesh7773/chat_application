import '../pages/auth%20pages/forgot_page.dart';
import '../pages/auth%20pages/otp_page.dart';
import '../pages/auth%20pages/sign_in_page.dart';
import '../pages/auth%20pages/sign_up_page.dart';
import '../pages/basic pages/active_users.dart';
import '../pages/basic pages/bottom_navigation_bar.dart';
import '../pages/basic pages/calls_page.dart';
import '../pages/basic pages/chat_screen.dart';
import '../pages/basic pages/home_page.dart';
import '../pages/basic pages/people_page.dart';
import '../pages/basic pages/profile_page.dart';
import '../pages/basic pages/search_page.dart';
import 'rotues_names.dart';
import 'package:flutter/material.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      //! Sign-In Page
      case RoutesNames.signInPage:
        return MaterialPageRoute(
          builder: (context) => const SignInPage(),
        );

      //! Sign-Up Page
      case RoutesNames.signUpPage:
        return MaterialPageRoute(
          builder: (context) => const SignUpPage(),
        );

      //! Forgot Password Page
      case RoutesNames.forgotPasswordPage:
        return MaterialPageRoute(
          builder: (context) => const ForgotPasswordPage(),
        );

      //! OTP Page
      case RoutesNames.otpPage:
        // Retrieving data
        final args = settings.arguments as Map<String, dynamic>;

        return MaterialPageRoute(
          builder: (context) => OtpPage(
            fullname: args["fullName"],
            email: args["email"],
            password: args["password"],
          ),
        );

      //! Bottom Navigation Bar Page
      case RoutesNames.bottomNavigationBar:
        return MaterialPageRoute(
          builder: (context) => const BottomNavigationBarPage(),
        );

      //! Home Page
      case RoutesNames.homePage:
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
        );

      //! Search Page
      case RoutesNames.searchPage:
        // Retrieving the heading
        final heading = settings.arguments as String;

        return MaterialPageRoute(
          builder: (context) => SearchPage(
            heading: heading,
          ),
        );

      //! Chat Screen Page
      case RoutesNames.chatScreenPage:
        // Retrieving data
        final args = settings.arguments as Map<String, dynamic>;

        return MaterialPageRoute(
          builder: (context) => ChatScreen(
            userID: args["userID"],
            name: args["name"],
            currentUserName: args["currentUsername"],
            email: args["email"],
            imageUrl: args["imageUrl"],
            rsaPublicKey: args["rsaPublicKey"],
            fcmToken: args["fcmToken"],
          ),
        );

      //! Active Users Page
      case RoutesNames.activeUserPage:
        return MaterialPageRoute(
          builder: (context) => const ActiveUsers(),
        );

      //! People Page
      case RoutesNames.peoplePage:
        return MaterialPageRoute(
          builder: (context) => const PeoplePage(),
        );

      //! Calls Page
      case RoutesNames.callsPage:
        return MaterialPageRoute(
          builder: (context) => const CallsPage(),
        );

      //! Profile Page
      case RoutesNames.profilePage:
        return MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        );

      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text("No Route Found"),
            ),
          ),
        );
    }
  }
}
