import 'dart:ui';
import '../theme/themes.dart';
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  //! Variable declarations
  ThemeData themeData = ChatAppTheme.lightMode;

  //! ThemeProvider Class Constructor
  ThemeProvider(String savedLevel) {
    // After initializing the radio button value, call setTheme() to set the application theme according to the initialized value.
    setTheme();
    // This code executes the setTheme() method when the Android system brightness changes.
    // It is used when the user has set the app theme to "System". When "System" is selected,
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
