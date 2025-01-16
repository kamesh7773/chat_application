import 'package:chat_application/theme/extension.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatAppTheme {
  ChatAppTheme._();

  //? ----------------
  //? LIGHT MODE THEME
  //? ----------------

  static final ThemeData lightMode = ThemeData(
    brightness: Brightness.light,
    fontFamily: "Lato",

    //! Extension's
    extensions: <ThemeExtension<dynamic>>[
      MyColors.light,
    ],

    //! Appbar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade300,
      centerTitle: true,
    ),

    //! ColorScheme Theme
    colorScheme: const ColorScheme.light(),

    //! textTheme Theme
    textTheme: GoogleFonts.latoTextTheme(),
  );

  //? ---------------
  //? DARK MODE THEME
  //? ---------------

  static final ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,

    //! Extension's
    extensions: <ThemeExtension<dynamic>>[
      MyColors.dark,
    ],

    //! Appbar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 29, 29, 53),
    ),
    scaffoldBackgroundColor: const Color.fromARGB(255, 29, 29, 53),

    //! ColorScheme Theme
    colorSchemeSeed: const Color.fromARGB(255, 2, 239, 159),

    //! textTheme Theme
    textTheme: GoogleFonts.latoTextTheme(const TextTheme(
      bodyLarge: TextStyle(color: Colors.white), // Set text color for dark theme
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white),
    )),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color.fromARGB(255, 2, 239, 159),
    ),

    //! Textfromfeild Theme
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color.fromARGB(255, 46, 47, 69),
    ),

    //! Action Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      color: WidgetStateProperty.all<Color?>(Colors.white),
      labelStyle: const TextStyle(
        color: Colors.black,
      ),
    ),
  );
}
