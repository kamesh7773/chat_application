import '../services/firebase_firestore_methods.dart';
import 'package:flutter/foundation.dart';

class LastMessageProvider extends ChangeNotifier {
  final FirebaseFireStoreMethods _firebaseFireStoreMethods = FirebaseFireStoreMethods();

  // Map to store last messages for each user
  final Map<String, String> lastMessages = {};

  // This Message is called from the Home Page ListView and we pass the userID in via indexing and this method return the lastMsg of user from the Map.
  String getLastMsg(String userId) {
    return lastMessages[userId] ?? ""; // Return empty if no message for userId
  }

  Future<void> fetchLastMsg({required String otherUserID}) async {
    try {
      // Here we are fething the Last Message of otherUser basaed provided other user ID and we store varible name last User.
      final lastMessage = await _firebaseFireStoreMethods.updateLastMessage(otherUserID: otherUserID);
      // Here we store the lastMessage on map and store the last Message and named the key as otherUser ID so now the lastMessage of Other User is saved on map and the key named will be the his ID.
      lastMessages[otherUserID] = lastMessage; // Store last message for this user
      notifyListeners();
    } catch (error) {
      throw "Error fetching last message for user $otherUserID: $error";
    }
  }
}
