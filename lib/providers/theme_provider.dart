import 'dart:ui';
import 'package:chat_application/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  //! Variable declarations
  String _level = "System";
  String _theme = "System";
  ThemeData _themeData = ChatAppTheme.lightMode;

  //! ThemeProvider Class Constructor
  ThemeProvider(String savedLevel) {
    // Initializing radio button value retrieved from SharedPreferences at application startup
    _level = savedLevel;
    _theme = savedLevel;
    // After initializing the radio button value, we call setTheme() to set the application theme according to the initialized value
    setTheme();
    // This code executes the setTheme() method when Android System brightness changes.
    // This is used when the user has set the App Theme to "System". When "System" is selected,
    // if the system theme changes from dark to light (or vice versa), setTheme() is called to
    // update the application theme accordingly.
    PlatformDispatcher.instance.onPlatformBrightnessChanged = setTheme;
  }

  String get level => _level;
  String get theme => _theme;
  ThemeData get themeData => _themeData;

  //! Method that toggles the RadioButton on user interaction
  void toggleRadiobtn(value) {
    _level = value;
    notifyListeners();
  }

  //! Method that changes the theme
  void setTheme() {
    _theme = _level;
    // If user has selected the "System" theme
    if (_level == "System") {
      if (PlatformDispatcher.instance.platformBrightness == Brightness.light) {
        _themeData = ChatAppTheme.lightMode;
      } else {
        _themeData = ChatAppTheme.darkMode;
      }
    }
    // If user has selected the "Light" theme
    else if (_level == "Light") {
      _themeData = ChatAppTheme.lightMode;
    }
    // If user has selected the "Dark" theme
    else if (_level == "Dark") {
      _themeData = ChatAppTheme.darkMode;
    }
    // Return if no valid theme is selected
    else {
      return;
    }
    _saveToPrefs();
    notifyListeners();
  }

  //! This method resets the selected radio theme value when user cancels the theme selection
  void resetRadiobtn() {
    _level = _theme;
  }

  //! This method saves the user-selected radio button level in SharedPreferences
  void _saveToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("savedTheme", _level);
  }

  //! Retrieves the previously saved radio button level from SharedPreferences
  //! [This method is called from main() method]
  static Future<String> currentTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('savedTheme') ?? "System";
  }
}
