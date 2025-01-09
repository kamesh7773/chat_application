import 'package:chat_application/pages/video%20&%20audio%20pages/audio_and_video_page.dart';

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
      //! Sign-In Page.
      case RoutesNames.signInPage:
        return MaterialPageRoute(
          builder: (context) => const SignInPage(),
        );

      //! Sign-In Page.
      case RoutesNames.signUpPage:
        return MaterialPageRoute(
          builder: (context) => const SignUpPage(),
        );

      //! Forgot Password Page.
      case RoutesNames.forgotPasswordPage:
        return MaterialPageRoute(
          builder: (context) => const ForgotPasswordPage(),
        );

      //! OTP Page.
      case RoutesNames.otpPage:
        // Retriving Data.
        final args = settings.arguments as Map<String, dynamic>;

        return MaterialPageRoute(
          builder: (context) => OtpPage(
            fullname: args["fullName"],
            email: args["email"],
            password: args["password"],
          ),
        );

      //! BottomNavigationBar Page.
      case RoutesNames.bottomNavigationBar:
        return MaterialPageRoute(
          builder: (context) => const BottomNavigationBarPage(),
        );

      //! Home Page.
      case RoutesNames.homePage:
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
        );

      //! Search Page.
      case RoutesNames.searchPage:
        // Retriving the heading.
        final heading = settings.arguments as String;

        return MaterialPageRoute(
          builder: (context) => SearchPage(
            heading: heading,
          ),
        );

      //! Chat Screen Page.
      case RoutesNames.chatScreenPage:
        // Retriving Data.
        final args = settings.arguments as Map<String, dynamic>;

        return MaterialPageRoute(
          builder: (context) => ChatScreen(
            userID: args["userID"],
            name: args["name"],
            email: args["email"],
            imageUrl: args["imageUrl"],
          ),
        );

      //! Active User Screen Page.
      case RoutesNames.activeUserPage:
        return MaterialPageRoute(
          builder: (context) => const ActiveUsers(),
        );

      //! People Screen Page.
      case RoutesNames.peoplePage:
        return MaterialPageRoute(
          builder: (context) => const PeoplePage(),
        );

      //! People Screen Page.
      case RoutesNames.callsPage:
        return MaterialPageRoute(
          builder: (context) => const CallsPage(),
        );

      //! Profile Screen Page.
      case RoutesNames.profilePage:
        return MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        );

      //! Call Screen Page.
      case RoutesNames.audioAndVideoPage:
        // Retriving Data.
        final args = settings.arguments as Map<String, dynamic>;

        return MaterialPageRoute(
          builder: (context) =>  AudioAndVideoPage(
            userName: args["userName"],
            callID: args["callID"],
          ),
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
