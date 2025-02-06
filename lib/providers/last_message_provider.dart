import '../services/firebase_firestore_methods.dart';
import 'package:flutter/foundation.dart';

class LastMessageProvider extends ChangeNotifier {
  final FirebaseFireStoreMethods _firebaseFireStoreMethods = FirebaseFireStoreMethods();

  // Map to store the last messages for each user
  final Map<String, String> lastMessages = {};

  // This method is called from the Home Page ListView. We pass the userID via indexing, and this method returns the last message of the user from the map.
  String getLastMsg(String userId) {
    return lastMessages[userId] ?? ""; // Return an empty string if no message exists for userId
  }

  Future<void> fetchLastMsg({required String otherUserID}) async {
    try {
      // Fetch the last message of the other user based on the provided user ID and store it in a variable named lastMessage.
      final lastMessage = await _firebaseFireStoreMethods.updateLastMessage(otherUserID: otherUserID);
      // Store the last message in the map with the key as the other user's ID, so the last message of the other user is saved in the map with their ID as the key.
      lastMessages[otherUserID] = lastMessage!; // Store the last message for this user
      notifyListeners();
    } catch (error) {
      throw "Error fetching last message for user $otherUserID: $error";
    }
  }
}
