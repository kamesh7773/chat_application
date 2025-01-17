import 'dart:ui';
import 'package:chat_application/theme/themes.dart';
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  //! Variable declarations
  ThemeData themeData = ChatAppTheme.lightMode;

  //! ThemeProvider Class Constructor
  ThemeProvider(String savedLevel) {
    // After initializing the radio button value, we call setTheme() to set the application theme according to the initialized value
    setTheme();
    // This code executes the setTheme() method when Android System brightness changes.
    // This is used when the user has set the App Theme to "System". When "System" is selected,
    // if the system theme changes from dark to light (or vice versa), setTheme() is called to
    // update the application theme accordingly.
    PlatformDispatcher.instance.onPlatformBrightnessChanged = setTheme;
  }

  //! Method that changes the theme
  void setTheme() {
    if (PlatformDispatcher.instance.platformBrightness == Brightness.light) {
      themeData = ChatAppTheme.lightMode;
    } else {
      themeData = ChatAppTheme.darkMode;
    }
    notifyListeners();
  }
}
