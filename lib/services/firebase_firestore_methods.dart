import 'package:firebase_messaging/firebase_messaging.dart';

import 'message_encrption_service.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';

import '../models/message_model.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseFireStoreMethods {
  // Firebase instance variables
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const String usersCollection = "users";
  static const String chatRoomsCollection = "chatRooms";
  static const String messagesCollection = "messages";

  //! Fetches all users from Firestore, excluding the current user.
  Stream<List<UserModel>> fetchingUsers() {
    final CollectionReference users = _db.collection(usersCollection);

    try {
      String currentUserId = _auth.currentUser!.uid;

      // Query to exclude the current user
      return users.where('userID', isNotEqualTo: currentUserId).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Fetches all online users from Firestore, excluding the current user.
  Stream<List<UserModel>> fetchingOnlineUsers() {
    final CollectionReference users = _db.collection(usersCollection);

    try {
      String currentUserId = _auth.currentUser!.uid;

      // Query to fetch online users
      return users.where('isOnline', isNotEqualTo: false).snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
            .where((user) => user.userID != currentUserId) // Exclude current user locally
            .toList();
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Fetches the current user's details for the profile page.
  Stream<UserModel> fetchingCurrentUserDetails() {
    final String currentUserID = _auth.currentUser!.uid;
    final CollectionReference users = _db.collection(usersCollection);

    try {
      return users.snapshots().asyncMap((snapshot) async {
        final doc = snapshot.docs.firstWhere(
          (doc) => (doc.data() as Map<String, dynamic>)['userID'] == currentUserID,
        );

        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Fetches user details based on userID.
  Future<UserModel> fetchingCurrentUserDetail({required String userID}) async {
    final DocumentReference currentUserDoc = _db.collection("users").doc(userID);
    final DocumentSnapshot docSnapshot = await currentUserDoc.get();
    final UserModel user = UserModel.fromJson(docSnapshot.data() as Map<String, dynamic>);

    return user;
  }

  //! Searches users based on their name.
  Stream<List<UserModel>> searchingUserBasedOnName({required String keyword}) {
    final CollectionReference users = _db.collection(usersCollection);

    try {
      String currentUserId = _auth.currentUser!.uid;

      // Query to search users by name
      return users.where('userID', isNotEqualTo: currentUserId).orderBy("name").startAt([keyword]).endAt(["$keyword\uf8ff"]).snapshots().map((snapshot) {
            return snapshot.docs.map((doc) {
              return UserModel.fromJson(doc.data() as Map<String, dynamic>);
            }).toList();
          });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Sends a message to a user.
  Future<void> sendMessage({required String receiverID, required String message, required String recipientPublicKey}) async {
    final String currentUserID = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();
    final DocumentReference<Map<String, dynamic>> receiverDoc = _db.collection(usersCollection).doc(receiverID);

    try {
      final data = (await receiverDoc.get()).data()!;
      final bool otherSideUserInsideChatroom = data["isInsideChatRoom"];
      final bool isOnline = data["isOnline"];

      // Parse the recipient's RSA public key from PEM format.
      RsaKeyHelper helper = RsaKeyHelper();
      final RSAPublicKey publicKey = helper.parsePublicKeyFromPem(recipientPublicKey);

      // Encrypt the message using AES
      final result = await MessageEncrptionService().encryptMessage(message: message);

      // Encrypt AES Key & IV using the recipient's public RSA key
      String encryptedAESKey = MessageEncrptionService().rsaEncrypt(data: result.aesKey.bytes, publicKey: publicKey);
      String encryptedIV = MessageEncrptionService().rsaEncrypt(data: result.iv.bytes, publicKey: publicKey);

      // If the other user is inside the chat room, set isSeen to true
      if (otherSideUserInsideChatroom && isOnline) {
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

        List<String> ids = [currentUserID, receiverID];
        ids.sort();
        String chatRoomID = ids.join("_");

        await _db.collection(chatRoomsCollection).doc(chatRoomID).collection("messages").add(newMessage.toMap());
      } else {
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

        List<String> ids = [currentUserID, receiverID];
        ids.sort();
        String chatRoomID = ids.join("_");

        await _db.collection(chatRoomsCollection).doc(chatRoomID).collection("messages").add(newMessage.toMap());

        await updateUnseenMessage(userID: currentUserID, otherUserID: receiverID);
      }
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Updates the last message in the user's database for display on the home screen.
  Future<void> updateUnseenMessage({required String userID, required String otherUserID}) async {
    try {
      final DocumentReference currentUserDoc = _db.collection(usersCollection).doc(userID);

      List<String> ids = [userID, otherUserID];
      ids.sort();
      String chatRoomID = ids.join("_");

      final CollectionReference messages = _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection);

      Future<QuerySnapshot<Object?>> snapshot = messages.orderBy("timestamp", descending: false).get();

      snapshot.then((value) async {
        Map<String, dynamic> lastMessageData = value.docs.last.data() as Map<String, dynamic>;

        Map<String, dynamic> newMessage = {
          "msg": lastMessageData["message"] ?? "",
          "senderID": userID,
          "reciverId": otherUserID,
          "timeStamp": DateTime.now(),
        };

        await currentUserDoc.update({
          "unSeenMessages": FieldValue.arrayUnion([newMessage]),
        });
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Retrieves messages from a chat room.
  Stream<List<MessageModel>> getMessages({required String otherUserID}) {
    List<String> ids = [_auth.currentUser!.uid, otherUserID];
    ids.sort();
    String chatRoomID = ids.join("_");

    final CollectionReference messages = _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection);

    try {
      return messages.orderBy("timestamp", descending: false).snapshots().asyncMap((snapshot) async {
        final List<MessageModel> messageList = await Future.wait(snapshot.docs.map((doc) async {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          final String senderID = data['senderID'];
          final String encryptedMessage = data['message'];
          final String encryptedAESKey = data['encryptedAESKey'];
          final String encryptedIV = data['encryptedIV'];

          final String decryptedMessage = await MessageEncrptionService().mesageDecrypation(
            currentUserID: _auth.currentUser!.uid,
            senderID: senderID,
            encryptedMessage: encryptedMessage,
            encryptedAESKey: encryptedAESKey,
            encryptedIV: encryptedIV,
          );

          data['message'] = decryptedMessage;

          return MessageModel.fromJson(data);
        }).toList());

        return messageList;
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Updates the user's online/offline status.
  Future<void> isOnlineStatus({required bool isOnline, required DateTime datetime}) async {
    try {
      final DocumentReference currentUserDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

      await currentUserDoc.update({
        "isOnline": isOnline,
        "lastSeen": datetime,
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Updates whether the user is typing.
  Future<void> isUserTyping({required String userID, required bool isTyping}) async {
    try {
      final DocumentReference userDoc = _db.collection(usersCollection).doc(userID);

      await userDoc.update({
        "isTyping": isTyping,
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Updates whether the user is inside the chat room.
  Future<void> isInsideChatRoom({required bool status}) async {
    try {
      final DocumentReference userDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

      await userDoc.update({
        "isInsideChatRoom": status,
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Retrieves the last message sent or received by the user.
  Future<String> updateLastMessage({required String otherUserID}) async {
    try {
      String decryptedMessage = "";
      List<String> ids = [_auth.currentUser!.uid, otherUserID];
      ids.sort();
      String chatRoomID = ids.join("_");

      final CollectionReference messages = _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection);

      QuerySnapshot<Object?> snapshot = await messages.orderBy("timestamp", descending: false).get();

      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> lastMessageData = snapshot.docs.last.data() as Map<String, dynamic>;

        final String senderID = lastMessageData['senderID'];
        final String encryptedMessage = lastMessageData['message'];
        final String encryptedAESKey = lastMessageData['encryptedAESKey'];
        final String encryptedIV = lastMessageData['encryptedIV'];
        final bool? isVideoCall = lastMessageData['isVideoCall'];

        if (isVideoCall == null) {
          decryptedMessage = await MessageEncrptionService().mesageDecrypation(
            currentUserID: _auth.currentUser!.uid,
            senderID: senderID,
            encryptedMessage: encryptedMessage,
            encryptedAESKey: encryptedAESKey,
            encryptedIV: encryptedIV,
          );
        } else if (isVideoCall == true) {
          decryptedMessage = "Video Call";
        } else if (isVideoCall == false) {
          decryptedMessage = "Audio Call";
        }
        return decryptedMessage;
      } else {
        return decryptedMessage;
      }
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Updates unseen messages to seen when the other user is present in the chat room.
  Future<void> getAllUnseenMessagesAndUpdateToSeen({
    required String userID,
    required String otherUserID,
    required bool isOtherUserInsideChatRoom,
    required bool isOnline,
  }) async {
    if (isOtherUserInsideChatRoom && isOnline) {
      List<String> ids = [userID, otherUserID];
      ids.sort();
      String chatRoomID = ids.join("_");

      _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection);

      final Query<Map<String, dynamic>> currentUserMessagesRef = _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection).where('isSeen', isEqualTo: false).limit(50);

      final querySnapshotOfCurrentUser = await currentUserMessagesRef.get();

      final WriteBatch batch = _db.batch();

      for (var doc in querySnapshotOfCurrentUser.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }

      await batch.commit();
    }
  }

  //! Clears unseen messages from the user's collection.
  Future<void> deleteUnseenMessages({required String userID}) async {
    try {
      final DocumentReference userDoc = _db.collection(usersCollection).doc(userID);

      await userDoc.update({
        "unSeenMessages": [],
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Updates the call logs in the user's collection.
  Future<void> updateCallLogs({
    required String userID,
    required String userName,
    required String imageUrl,
    required bool isVideoCall,
    required bool isInComing,
  }) async {
    try {
      final DocumentReference currentUserDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

      Map<String, dynamic> callInfo = {
        "userID": userID,
        "userName": userName,
        "imageUrl": imageUrl,
        "isInComing": isInComing,
        "isVideoCall": isVideoCall,
        "timeStamp": DateTime.now(),
      };

      await currentUserDoc.update({
        "callLogs": FieldValue.arrayUnion([callInfo]),
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Updates the FCM Token for the current user.
  Future<void> updateFcmToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();

      final DocumentReference userDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

      await userDoc.update({
        "fcmToken": token,
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }
}
