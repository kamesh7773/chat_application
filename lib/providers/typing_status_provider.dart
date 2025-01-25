import 'package:flutter/material.dart';

class TypingStatusProvider extends ChangeNotifier {
  bool isTypingStatus = false;

  // Method to update the typing status
  void changeStatus({required bool status}) {
    isTypingStatus = status;
    notifyListeners(); // Notify listeners about the change in typing status
  }
}
