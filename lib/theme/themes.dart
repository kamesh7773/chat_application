import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatAppTheme {
  ChatAppTheme._();

  //? ----------------
  //? LIGHT MODE THEME
  //? ----------------

  static final ThemeData lightMode = ThemeData(
    brightness: Brightness.light,

    //! AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
    ),

    scaffoldBackgroundColor: Colors.white,

    //! ColorScheme Theme
    colorSchemeSeed: const Color.fromARGB(255, 2, 239, 159),

    //! TextTheme
    textTheme: GoogleFonts.latoTextTheme(const TextTheme(
      bodyLarge: TextStyle(color: Colors.black), // Set text color for light theme
      bodyMedium: TextStyle(color: Colors.black),
      bodySmall: TextStyle(color: Colors.black),
    )),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color.fromARGB(255, 2, 239, 159),
    ),

    //! InputDecoration Theme
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color.fromARGB(255, 225, 247, 237),
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

  //? ---------------
  //? DARK MODE THEME
  //? ---------------

  static final ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,

    //! AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 29, 29, 53),
    ),
    scaffoldBackgroundColor: const Color.fromARGB(255, 29, 29, 53),

    //! ColorScheme Theme
    colorSchemeSeed: const Color.fromARGB(255, 2, 239, 159),

    //! TextTheme
    textTheme: GoogleFonts.latoTextTheme(const TextTheme(
      bodyLarge: TextStyle(color: Colors.white), // Set text color for dark theme
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white),
    )),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color.fromARGB(255, 2, 239, 159),
    ),

    //! InputDecoration Theme
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
