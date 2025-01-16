import 'package:flutter/material.dart';

@immutable
class MyColors extends ThemeExtension<MyColors> {
  //! Declaring varible for custom color for
  final Color? commanColor;
  final Color? buttonColor;
  final Color? googleFacebook;
  final Color? drawerListTileColor;
  final Color? appBar;
  final Color? notePage;

  const MyColors({
    this.googleFacebook,
    this.buttonColor,
    this.commanColor,
    this.drawerListTileColor,
    this.appBar,
    this.notePage,
  });

  @override
  ThemeExtension<MyColors> copyWith({
    Color? commanColor,
    Color? buttonColor,
    Color? googleFacebook,
    Color? drawerListTileColor,
    Color? appBar,
    Color? notePage,
  }) {
    return MyColors(
      commanColor: commanColor ?? this.commanColor,
      buttonColor: buttonColor ?? this.buttonColor,
      googleFacebook: buttonColor ?? this.googleFacebook,
      drawerListTileColor: buttonColor ?? this.drawerListTileColor,
      appBar: buttonColor ?? this.appBar,
      notePage: buttonColor ?? this.notePage,
    );
  }

  @override
  ThemeExtension<MyColors> lerp(ThemeExtension<MyColors>? other, double t) {
    if (other is! MyColors) {
      return this;
    }
    return MyColors(
      commanColor: Color.lerp(commanColor, other.commanColor, t),
      buttonColor: Color.lerp(buttonColor, other.buttonColor, t),
      googleFacebook: Color.lerp(googleFacebook, other.googleFacebook, t),
      drawerListTileColor:
          Color.lerp(drawerListTileColor, other.drawerListTileColor, t),
      appBar: Color.lerp(appBar, other.appBar, t),
      notePage: Color.lerp(notePage, other.notePage, t),
    );
  }

  //! variable Colors for Dark Theme.
  static final dark = MyColors(
    commanColor: Colors.white,
    buttonColor: const Color.fromARGB(255, 100, 100, 100),
    googleFacebook: const Color.fromARGB(255, 209, 206, 206),
    drawerListTileColor: Colors.grey[400],
    appBar: Colors.black,
    notePage: const Color(0xFF181818),
  );

  //! variable Colors for light Theme.
  static final light = MyColors(
    commanColor: Colors.black,
    buttonColor: Colors.black,
    googleFacebook: Colors.grey.shade300,
    drawerListTileColor: Colors.grey[400],
    appBar: Colors.white,
    notePage: Colors.white,
  );
}
