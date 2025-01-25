import 'package:chat_application/services/message_encrption_service.dart';
import 'package:colored_print/colored_print.dart';
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

  static const String usersCollection = "users";
  static const String chatRoomsCollection = "chatRooms";
  static const String messagesCollection = "messages";

  //! Method for fetching all the users from Firestore database except the current user.
  Stream<List<UserModel>> fetchingUsers() {
    // Get the users collection
    final CollectionReference users = _db.collection(usersCollection);

    try {
      // Retrieve the current user's ID
      String currentUserId = _auth.currentUser!.uid;

      // Filter out the current user using a Firestore query (Here we are only fetcing the user that userID is not same as current userID)
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

  //! Method for fetching all the users from Firestore database except the current user.
  Stream<List<UserModel>> fetchingOnlineUsers() {
    // Get the users collection
    final CollectionReference users = _db.collection(usersCollection);

    try {
      // Retrieve the current user's ID
      String currentUserId = _auth.currentUser!.uid;

      // Fetch all users where isOnline is not false
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

  //! Method for fetching current User Details for Profile Page.
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

  //! Method for seraching user based on their name.
  Stream<List<UserModel>> searchingUserBasedOnName({required String keyword}) {
    // Get the users collection
    final CollectionReference users = _db.collection(usersCollection);

    try {
      // Retrieve the current user's ID
      String currentUserId = _auth.currentUser!.uid;

      // Filter out the current user using a Firestore query (Here we are only fetcing the user that userID is not same as current userID)
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

  //! Method for sending the Messages.
  Future<void> sendMessage({required String receiverID, required String message, required String recipientPublicKey}) async {
    // get current userID
    final String currentUserID = _auth.currentUser!.uid;

    final Timestamp timestamp = Timestamp.now();

    // get the other side of user collection feild value "isInsideChatRoom"
    final DocumentReference<Map<String, dynamic>> receiverDoc = _db.collection(usersCollection).doc(receiverID);

    try {
      final data = (await receiverDoc.get()).data()!;
      final bool otherSideUserInsideChatroom = data["isInsideChatRoom"];
      final bool isOnline = data["isOnline"];

      // Parse the RSA public key of recipient from PEM format.
      RsaKeyHelper helper = RsaKeyHelper();
      final RSAPublicKey publicKey = helper.parsePublicKeyFromPem(recipientPublicKey);

      // Encrypt the message using AES
      final result = await MessageEncrptionService().encryptMessage(message: message);

      // Encrypt AES Key & IV using the recipient's public RSA key
      String encryptedAESKey = MessageEncrptionService().rsaEncrypt(data: result.aesKey.bytes, publicKey: publicKey);
      String encryptedIV = MessageEncrptionService().rsaEncrypt(data: result.iv.bytes, publicKey: publicKey);

      // If Other Side of User InSide the ChatRoom Then we setSeen to True
      if (otherSideUserInsideChatroom && isOnline) {
        // create a new message
        MessageModel newMessage = MessageModel(
          senderID: currentUserID,
          reciverID: receiverID,
          message: result.encryptedMessage,
          encryptedAESKey: encryptedAESKey,
          encryptedIV: encryptedIV,
          isSeen: true,
          timestamp: timestamp,
        );

        // construt chatRoom ID for two users (sorted to ensure uniqueness)
        List<String> ids = [currentUserID, receiverID];
        ids.sort();
        // Creating the chatRoomID by combining currentUserID and reciverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
        String chatRoomID = ids.join("_");

        // add new message to database.
        await _db.collection(chatRoomsCollection).doc(chatRoomID).collection("messages").add(newMessage.toMap());
      }
      // else we set isSeen to false and add the send message to UnseenMessage List of Map to ther User document.
      else {
        // create a new message
        MessageModel newMessage = MessageModel(
          senderID: currentUserID,
          reciverID: receiverID,
          message: result.encryptedMessage,
          encryptedAESKey: encryptedAESKey,
          encryptedIV: encryptedIV,
          isSeen: false,
          timestamp: timestamp,
        );

        // construt chatRoom ID for two users (sorted to ensure uniqueness)
        List<String> ids = [currentUserID, receiverID];
        ids.sort();
        // Creating the chatRoomID by combining currentUserID and reciverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
        String chatRoomID = ids.join("_");

        // add new message to database.
        await _db.collection(chatRoomsCollection).doc(chatRoomID).collection("messages").add(newMessage.toMap());

        await updateUnseenMessage(userID: currentUserID, otherUserID: receiverID);
      }
    } catch (error) {
      ColoredPrint.warning(error);
      throw Exception(error.toString());
    }
  }

  //! Method updating last message on user database. (showing the last msg on home screen)
  Future<void> updateUnseenMessage({required String userID, required String otherUserID}) async {
    try {
      // Reference to the others user's document in the main collection
      final DocumentReference currentUserDoc = _db.collection(usersCollection).doc(userID);

      // construt chatRoom ID for two users (sorted to ensure uniqueness)
      List<String> ids = [userID, otherUserID];
      ids.sort();
      // Creating the chatRoomID by combining currentUserID and reciverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
      String chatRoomID = ids.join("_");

      // get the messages collection that is inside the chatRooms collection
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

        // Updating lastMessage feild at OtherUser "users" firestore collection.
        await currentUserDoc.update({
          "unSeenMessages": FieldValue.arrayUnion([newMessage]),
        });
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method for getting the Messages.
  Stream<List<MessageModel>> getMessages({required String otherUserID}) {
    // Construct chatRoom ID for two users (sorted to ensure uniqueness)
    List<String> ids = [_auth.currentUser!.uid, otherUserID];
    ids.sort();
    String chatRoomID = ids.join("_");

    // Get the messages collection inside chatRooms collection
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
      ColoredPrint.warning(error);
      throw Exception(error.toString());
    }
  }

  //! Methods that updates the user Online/Offine Status.
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

  //! Methods that updates the is user Typing.
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

  //! Methods that updates the is user inside the chat room or not.
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

  //! Method fot getting Last Message by user or from other user.
  Future<String> updateLastMessage({required String otherUserID}) async {
    try {
      // construt chatRoom ID for two users (sorted to ensure uniqueness)
      List<String> ids = [_auth.currentUser!.uid, otherUserID];
      ids.sort();
      // Creating the chatRoomID by combining currentUserID and reciverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
      String chatRoomID = ids.join("_");

      // get the messages collection that is inside the chatRooms collection
      final CollectionReference messages = _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection);

      QuerySnapshot<Object?> snapshot = await messages.orderBy("timestamp", descending: false).get();

      // Check if there are any messages
      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> lastMessageData = snapshot.docs.last.data() as Map<String, dynamic>;

        return lastMessageData["message"];
      } else {
        return "";
      }
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  //! Method that update the Unseen msg to Seen. ( We run this method when other side of user presented in the chatRoom and once it get inside the chat room we updated all the Unseen Msg to Seen)
  Future<void> getAllUnseenMessagesAndUpdateToSeen({
    required String userID,
    required String otherUserID,
    required bool isOtherUserInsideChatRoom,
    required bool isOnline,
  }) async {
    // if other side of user present inside the chat room then we update the IsSeen of message status of our message is to true
    if (isOtherUserInsideChatRoom && isOnline) {
      // construt chatRoom ID for two users (sorted to ensure uniqueness)
      List<String> ids = [userID, otherUserID];
      ids.sort();
      // Creating the chatRoomID by combining currentUserID and reciverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
      String chatRoomID = ids.join("_");

      _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection);

      // Here we are fething current Users Collection "chatRooms" --> "messages" where sendId is current login user and "isSeen" == false.
      final Query<Map<String, dynamic>> currentUserMessagesRef = _db.collection(chatRoomsCollection).doc(chatRoomID).collection(messagesCollection).where('isSeen', isEqualTo: false).limit(50);

      // here we are getting all the refernce of thoese document inside the messages collection thoese isSeen is false. (current user)
      final querySnapshotOfCurrentUser = await currentUserMessagesRef.get();

      // Create a batch instance so we can update the all the documents that contains isSeen is false.
      final WriteBatch batch = _db.batch();

      // here we loop through all the documents and update the isSeen to true.
      for (var doc in querySnapshotOfCurrentUser.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }

      // here we Commit the batch
      await batch.commit();
    }
  }

  //! Method that clear the UnSeenMessages form Users collection that user have not seen.
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

  //! Method that update the callLogs on user Collection.
  Future<void> updateCallLogs({
    required String userName,
    required String imageUrl,
    required bool isVideoCall,
    required bool isInComing,
  }) async {
    try {
      // Reference to the current user's document in the main collection
      final DocumentReference currentUserDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

      // Construct the new message map
      Map<String, dynamic> callInfo = {
        "userName": userName,
        "imageUrl": imageUrl,
        "isInComing": isInComing,
        "isVideoCall": isVideoCall,
        "timeStamp": DateTime.now(),
      };

      // Updating lastMessage feild at OtherUser "users" firestore collection.
      await currentUserDoc.update({
        "callLogs": FieldValue.arrayUnion([callInfo]),
      });
    } catch (error) {
      throw Exception(error.toString());
    }
  }
}
