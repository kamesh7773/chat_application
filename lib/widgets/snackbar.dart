import 'package:flutter/material.dart';

class SnackBars {
  static void normalSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
