import 'package:flutter/material.dart';

class TypingStatusProvider extends ChangeNotifier {
  bool isTypingStatus = false;

  void changeStatus({required bool status}) {
    isTypingStatus = status;
    notifyListeners();
  }
}
