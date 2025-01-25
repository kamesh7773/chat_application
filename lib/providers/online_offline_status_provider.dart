import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OnlineOfflineStatusProvider extends ChangeNotifier {
  bool isOnline = false;
  Timestamp userLastSeen = Timestamp.now();

  // Method to change the online status and update the last seen timestamp
  void changeStatus({required bool status, required Timestamp lastSeen}) {
    isOnline = status;
    userLastSeen = lastSeen;
    notifyListeners(); // Notify listeners about the status change
  }
}
