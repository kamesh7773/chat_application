import 'package:firebase_messaging/firebase_messaging.dart';

import 'message_encrption_service.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';

import '../models/message_model.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseFireStoreMethods {
  // Variables related to Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const String usersCollection = "users";
  static const String chatRoomsCollection = "chatRooms";
  static const String messagesCollection = "messages";

  //! Method for fetching all users from the Firestore database except the current user.
  Stream<List<UserModel>> fetchingUsers() {
    // Get the users collection
    final CollectionReference users = _db.collection(usersCollection);

    try {
      // Retrieve the current user's ID
      String currentUserId = _auth.currentUser!.uid;

      // Filter out the current user using a Firestore query (Here we are only fetching users whose userID is not the same as the current userID)
      return users.where('userID', isNotEqualTo: currentUserId).snapshots().map((snapshot) {
        // Map the snapshot documents into a list of UserModel
        return snapshot.docs.map((doc) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();
      });
    } catch (error) {
      // Handle any errors that occur
      throw Exception(error.toString());
    }
  }

  //! Method for fetching all online users from the Firestore database except the current user.
  Stream<List<UserModel>> fetchingOnlineUsers() {
    // Get the users collection
    final CollectionReference users = _db.collection(usersCollection);

    try {
      // Retrieve the current user's ID
      String currentUserId = _auth.currentUser!.uid;

      // Fetch all users where isOnline is true
      return users.where('isOnline', isNotEqualTo: false).snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
            .where((user) => user.userID != currentUserId) // Exclude current user locally
            .toList();
      });
    } catch (error) {
      // Handle any errors that occur
      throw Exception(error.toString());
    }
  }

  //! Method for fetching current user details for the profile page.
  Stream<UserModel> fetchingCurrentUserDetails() {
    // Get the current user ID
    final String currentUserID = _auth.currentUser!.uid;

    // Get the user collection
    final CollectionReference users = _db.collection(usersCollection);

    try {
      // Fetch the current user's details as a Stream<UserModel>
      return users.snapshots().asyncMap((snapshot) async {
        // Find the matching user document
        final doc = snapshot.docs.firstWhere(
          (doc) => (doc.data() as Map<String, dynamic>)['userID'] == currentUserID,
        );

        // Return the UserModel for the current user
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method for fetching the user details based on 2
  Future<UserModel> fetchingCurrentUserDetail({required String userID}) async {
    final DocumentReference currentUserDoc = _db.collection("users").doc(userID);
    final DocumentSnapshot docSnapshot = await currentUserDoc.get();
    final UserModel user = UserModel.fromJson(docSnapshot.data() as Map<String, dynamic>);

    return user;
  }

  //! Method for searching users based on their name.
  Stream<List<UserModel>> searchingUserBasedOnName({required String keyword}) {
    // Get the users collection
    final CollectionReference users = _db.collection(usersCollection);

    try {
      // Retrieve the current user's ID
      String currentUserId = _auth.currentUser!.uid;

      // Filter out the current user using a Firestore query (Here we are only fetching users whose userID is not the same as the current userID)
      return users.where('userID', isNotEqualTo: currentUserId).orderBy("name").startAt([keyword]).endAt(["$keyword\uf8ff"]).snapshots().map((snapshot) {
            // Map the snapshot documents into a list of UserModel
            return snapshot.docs.map((doc) {
              return UserModel.fromJson(doc.data() as Map<String, dynamic>);
            }).toList();
          });
    } catch (error) {
      // Handle any errors that occur
      throw Exception(error.toString());
    }
  }

  //! Method for sending messages.
  Future<void> sendMessage({required String receiverID, required String message, required String recipientPublicKey}) async {
    // Get current userID
    final String currentUserID = _auth.currentUser!.uid;

    final Timestamp timestamp = Timestamp.now();

    // Get the other user's document field value "isInsideChatRoom"
    final DocumentReference<Map<String, dynamic>> receiverDoc = _db.collection(usersCollection).doc(receiverID);

    try {
      final data = (await receiverDoc.get()).data()!;
      final bool otherSideUserInsideChatroom = data["isInsideChatRoom"];
      final bool isOnline = data["isOnline"];

      // Parse the RSA public key of the recipient from PEM format.
      RsaKeyHelper helper = RsaKeyHelper();
      final RSAPublicKey publicKey = helper.parsePublicKeyFromPem(recipientPublicKey);

      // Encrypt the message using AES
      final result = await MessageEncrptionService().encryptMessage(message: message);

      // Encrypt AES Key & IV using the recipient's public RSA key
      String encryptedAESKey = MessageEncrptionService().rsaEncrypt(data: result.aesKey.bytes, publicKey: publicKey);
      String encryptedIV = MessageEncrptionService().rsaEncrypt(data: result.iv.bytes, publicKey: publicKey);

      // If the other user is inside the chat room, set isSeen to true
      if (otherSideUserInsideChatroom && isOnline) {
        // Create a new message
        MessageModel newMessage = MessageModel(
          senderID: currentUserID,
          reciverID: receiverID,
          isVideoCall: null,
          message: result.encryptedMessage,
          encryptedAESKey: encryptedAESKey,
          encryptedIV: encryptedIV,
          isSeen: true,
          timestamp: timestamp,
        );

        // Construct chatRoom ID for two users (sorted to ensure uniqueness)
        List<String> ids = [currentUserID, receiverID];
        ids.sort();
        // Create the chatRoomID by combining currentUserID and receiverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
        String chatRoomID = ids.join("_");

        // Add new message to the database.
        await _db.collection(chatRoomsCollection).doc(chatRoomID).collection("messages").add(newMessage.toMap());
      }
      // Otherwise, set isSeen to false and add the sent message to the UnseenMessage list of maps in the other user's document.
      else {
        // Create a new message
        MessageModel newMessage = MessageModel(
          senderID: currentUserID,
          reciverID: receiverID,
          isVideoCall: null,
          message: result.encryptedMessage,
          encryptedAESKey: encryptedAESKey,
          encryptedIV: encryptedIV,
          isSeen: false,
          timestamp: timestamp,
        );

        // Construct chatRoom ID for two users (sorted to ensure uniqueness)
        List<String> ids = [currentUserID, receiverID];
        ids.sort();
        // Create the chatRoomID by combining currentUserID and receiverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
        String chatRoomID = ids.join("_");

        // Add new message to the database.
        await _db.collection(chatRoomsCollection).doc(chatRoomID).collection("messages").add(newMessage.toMap());

        await updateUnseenMessage(userID: currentUserID, otherUserID: receiverID);
      }
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method for updating the last message on the user database (showing the last message on the home screen).
  Future<void> updateUnseenMessage({required String userID, required String otherUserID}) async {
    try {
      // Reference to the other user's document in the main collection
      final DocumentReference currentUserDoc = _db.collection(usersCollection).doc(userID);

      // Construct chatRoom ID for two users (sorted to ensure uniqueness)
      List<String> ids = [userID, otherUserID];
      ids.sort();
      // Create the chatRoomID by combining currentUserID and receiverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
      String chatRoomID = ids.join("_");

      // Get the messages collection that is inside the chatRooms collection
      final CollectionReference messages = _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection);

      Future<QuerySnapshot<Object?>> snapshot = messages.orderBy("timestamp", descending: false).get();

      snapshot.then((value) async {
        Map<String, dynamic> lastMessageData = value.docs.last.data() as Map<String, dynamic>;

        // Construct the new message map
        Map<String, dynamic> newMessage = {
          "msg": lastMessageData["message"] ?? "",
          "senderID": userID,
          "reciverId": otherUserID,
          "timeStamp": DateTime.now(),
        };

        // Update the lastMessage field in the other user's "users" Firestore collection.
        await currentUserDoc.update({
          "unSeenMessages": FieldValue.arrayUnion([newMessage]),
        });
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method for getting messages.
  Stream<List<MessageModel>> getMessages({required String otherUserID}) {
    // Construct chatRoom ID for two users (sorted to ensure uniqueness)
    List<String> ids = [_auth.currentUser!.uid, otherUserID];
    ids.sort();
    String chatRoomID = ids.join("_");

    // Get the messages collection inside the chatRooms collection
    final CollectionReference messages = _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection);

    try {
      // Use asyncMap to handle asynchronous operations
      return messages.orderBy("timestamp", descending: false).snapshots().asyncMap((snapshot) async {
        // Fetch and process each document asynchronously
        final List<MessageModel> messageList = await Future.wait(snapshot.docs.map((doc) async {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Fetch encrypted fields
          final String senderID = data['senderID'];
          final String encryptedMessage = data['message'];
          final String encryptedAESKey = data['encryptedAESKey'];
          final String encryptedIV = data['encryptedIV'];

          // Decrypt the message asynchronously
          final String decryptedMessage = await MessageEncrptionService().mesageDecrypation(
            currentUserID: _auth.currentUser!.uid,
            senderID: senderID,
            encryptedMessage: encryptedMessage,
            encryptedAESKey: encryptedAESKey,
            encryptedIV: encryptedIV,
          );

          // Replace the encrypted message with the decrypted message
          data['message'] = decryptedMessage;

          // Convert the updated map to a MessageModel
          return MessageModel.fromJson(data);
        }).toList());

        return messageList;
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method to update the user's online/offline status.
  Future<void> isOnlineStatus({required bool isOnline, required DateTime datetime}) async {
    try {
      // Reference to the current user's document in the main collection
      final DocumentReference currentUserDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

      await currentUserDoc.update({
        "isOnline": isOnline,
        "lastSeen": datetime,
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method to update whether the user is typing.
  Future<void> isUserTyping({required String userID, required bool isTyping}) async {
    try {
      // Reference to the current user's document in the main collection
      final DocumentReference userDoc = _db.collection(usersCollection).doc(userID);

      await userDoc.update({
        "isTyping": isTyping,
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method to update whether the user is inside the chat room or not.
  Future<void> isInsideChatRoom({required bool status}) async {
    try {
      // Reference to the current user's document in the main collection
      final DocumentReference userDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

      await userDoc.update({
        "isInsideChatRoom": status,
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method for getting the last message by the user or from another user.
  Future<String> updateLastMessage({required String otherUserID}) async {
    try {
      // Construct chatRoom ID for two users (sorted to ensure uniqueness)
      List<String> ids = [_auth.currentUser!.uid, otherUserID];
      ids.sort();
      // Create the chatRoomID by combining currentUserID and receiverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
      String chatRoomID = ids.join("_");

      // Get the messages collection that is inside the chatRooms collection
      final CollectionReference messages = _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection);

      QuerySnapshot<Object?> snapshot = await messages.orderBy("timestamp", descending: false).get();

      // Check if there are any messages
      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> lastMessageData = snapshot.docs.last.data() as Map<String, dynamic>;

        // Fetch encrypted fields
        final String senderID = lastMessageData['senderID'];
        final String encryptedMessage = lastMessageData['message'];
        final String encryptedAESKey = lastMessageData['encryptedAESKey'];
        final String encryptedIV = lastMessageData['encryptedIV'];

        // Decrypt the message asynchronously
        final String decryptedMessage = await MessageEncrptionService().mesageDecrypation(
          currentUserID: _auth.currentUser!.uid,
          senderID: senderID,
          encryptedMessage: encryptedMessage,
          encryptedAESKey: encryptedAESKey,
          encryptedIV: encryptedIV,
        );

        return decryptedMessage;
      } else {
        return "";
      }
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method to update unseen messages to seen. (We run this method when the other user is present in the chat room, and once they enter the chat room, we update all unseen messages to seen)
  Future<void> getAllUnseenMessagesAndUpdateToSeen({
    required String userID,
    required String otherUserID,
    required bool isOtherUserInsideChatRoom,
    required bool isOnline,
  }) async {
    // If the other user is present inside the chat room, then we update the isSeen status of our messages to true
    if (isOtherUserInsideChatRoom && isOnline) {
      // Construct chatRoom ID for two users (sorted to ensure uniqueness)
      List<String> ids = [userID, otherUserID];
      ids.sort();
      // Create the chatRoomID by combining currentUserID and receiverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
      String chatRoomID = ids.join("_");

      _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection);

      // Here we are fetching current users' collection "chatRooms" --> "messages" where senderID is the current logged-in user and "isSeen" == false.
      final Query<Map<String, dynamic>> currentUserMessagesRef = _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection).where('isSeen', isEqualTo: false).limit(50);

      // Here we are getting all the references of those documents inside the messages collection where isSeen is false. (current user)
      final querySnapshotOfCurrentUser = await currentUserMessagesRef.get();

      // Create a batch instance so we can update all the documents that contain isSeen as false.
      final WriteBatch batch = _db.batch();

      // Here we loop through all the documents and update isSeen to true.
      for (var doc in querySnapshotOfCurrentUser.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }

      // Here we commit the batch
      await batch.commit();
    }
  }

  //! Method to clear unseen messages from the user's collection that the user has not seen.
  Future<void> deleteUnseenMessages({required String userID}) async {
    try {
      // Reference to the current user's document in the main collection
      final DocumentReference userDoc = _db.collection(usersCollection).doc(userID);

      await userDoc.update({
        "unSeenMessages": [],
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method to update the call logs in the user's collection.
  Future<void> updateCallLogs({
    required String userName,
    required String imageUrl,
    required bool isVideoCall,
    required bool isInComing,
  }) async {
    try {
      // Reference to the current user's document in the main collection
      final DocumentReference currentUserDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

      // Construct the new call log map
      Map<String, dynamic> callInfo = {
        "userName": userName,
        "imageUrl": imageUrl,
        "isInComing": isInComing,
        "isVideoCall": isVideoCall,
        "timeStamp": DateTime.now(),
      };

      // Update the callLogs field in the user's "users" Firestore collection.
      await currentUserDoc.update({
        "callLogs": FieldValue.arrayUnion([callInfo]),
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method to update the FCM Token
  Future<void> updateFcmToken() async {
    try {
      // retriving the token from firebase instance.
      String? token = await _firebaseMessaging.getToken();

      // Reference to the current user's document in the main collection
      final DocumentReference userDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

      // updating or adding the FCM Token on currentUser DB.
      await userDoc.update({
        "fcmToken": token,
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }
}
