import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OnlineOfflineStatusProvider extends ChangeNotifier {
  bool isOnline = false;
  Timestamp userLastSeen = Timestamp.now();

  void changeStatus({required bool status, required Timestamp lastSeen}) {
    isOnline = status;

    userLastSeen = lastSeen;
    notifyListeners();
  }
}
