import 'dart:convert';

import 'package:chat_application/services/message_encrption_service.dart';
import 'package:colored_print/colored_print.dart';
import 'package:flutter/material.dart';
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
      final publicKey = helper.parsePublicKeyFromPem(recipientPublicKey);

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

        // Get the Document refreence of current user ID.
        final DocumentReference<Map<String, dynamic>> userDoc = _db.collection(usersCollection).doc(currentUserID);

        // Get the Document refreence of current user ID.
        final DocumentReference<Map<String, dynamic>> otherUserDoc = _db.collection(usersCollection).doc(receiverID);

        // add new message collection inside the Users collections.
        // here we are storing chat collection inside the user collection and inside the ChatRoom Collection we are storing our message collection
        await userDoc.collection(chatRoomsCollection).doc(receiverID).collection(messagesCollection).add(newMessage.toMap());

        // add new message collection inside the OtherUser collections.
        // here we are storing chat collection inside the OtherUser collection and inside the ChatRoom Collection we are storing our message collection
        await otherUserDoc.collection(chatRoomsCollection).doc(currentUserID).collection(messagesCollection).add(newMessage.toMap());

        // Here we update the LastMessage.
        // await updateLastMessage(otherUserID: receiverID);
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

        // Get the Document refreence of current user ID.
        final DocumentReference<Map<String, dynamic>> userDoc = _db.collection(usersCollection).doc(currentUserID);

        // Get the Document refreence of current user ID.
        final DocumentReference<Map<String, dynamic>> otherUserDoc = _db.collection(usersCollection).doc(receiverID);

        // add new message collection inside the Users collections.
        // here we are storing chat collection inside the user collection and inside the ChatRoom Collection we are storing our message collection
        await userDoc.collection(chatRoomsCollection).doc(receiverID).collection(messagesCollection).add(newMessage.toMap());

        // add new message collection inside the OtherUser collections.
        // here we are storing chat collection inside the OtherUser collection and inside the ChatRoom Collection we are storing our message collection
        await otherUserDoc.collection(chatRoomsCollection).doc(currentUserID).collection(messagesCollection).add(newMessage.toMap());

        // Here we update the LastMessage.
        // await updateLastMessage(otherUserID: receiverID);

        // Here we add the send Message to UnSeenMessage List of Map to Other User Side because when user is not inside the chat room we will show those unseen message on HomePage with HighLited Text.
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

      // get the messages collection that is inside the chatRooms collection
      final CollectionReference messages = currentUserDoc.collection(chatRoomsCollection).doc(otherUserID).collection(messagesCollection);

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
    final DocumentReference<Map<String, dynamic>> currentUserDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

    // get the messages collection that is inside the chatRooms collection
    final CollectionReference messages = currentUserDoc.collection(chatRoomsCollection).doc(otherUserID).collection(messagesCollection);

    try {
      // Here we are the snapShot and with help of map() we retive that snapShot.
      return messages.orderBy("timestamp", descending: false).snapshots().map((snapshot) {
        // Here we retrive the documents from snapShot.
        return snapshot.docs.map((doc) {
          // Here we are converting each SnapShot document Map<String ,dynamic> and pass to the fromJson mehtod so we can convert it into NoteModel.
          return MessageModel.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();
      });
    } catch (error) {
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
      // Reference to the others user's document in the main collection
      final DocumentReference currentUserDoc = _db.collection(usersCollection).doc(_auth.currentUser!.uid);

      // get the messages collection that is inside the chatRooms collection
      final CollectionReference messages = currentUserDoc.collection(chatRoomsCollection).doc(otherUserID).collection(messagesCollection);

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
      final DocumentReference<Map<String, dynamic>> currentUserDoc = _db.collection(usersCollection).doc(userID);
      final DocumentReference<Map<String, dynamic>> otherUserDoc = _db.collection(usersCollection).doc(otherUserID);

      // Here we are fething current Users Collection "chatRooms" --> "messages" where sendId is current login user and "isSeen" == false.
      final Query<Map<String, dynamic>> currentUserMessagesRef = currentUserDoc.collection(chatRoomsCollection).doc(otherUserID).collection(messagesCollection).where('senderID', isEqualTo: _auth.currentUser!.uid).where('isSeen', isEqualTo: false).limit(50);

      // Here we are fething Other Side of Users Collection "chatRooms" --> "messages" where sendId is current login user and "isSeen" == false.
      final Query<Map<String, dynamic>> otherSideUserMessagesRef = otherUserDoc.collection(chatRoomsCollection).doc(otherUserID).collection(messagesCollection).where('senderID', isEqualTo: _auth.currentUser!.uid).where('isSeen', isEqualTo: false).limit(50);

      // here we are getting all the refernce of thoese document inside the messages collection thoese isSeen is false. (current user)
      final querySnapshotOfCurrentUser = await currentUserMessagesRef.get();

      // here we are getting all the refernce of thoese document inside the messages collection thoese isSeen is false. (other user)
      final querySnapshotOfOtherUser = await otherSideUserMessagesRef.get();

      // Create a batch instance so we can update the all the documents that contains isSeen is false.
      final WriteBatch batch = _db.batch();

      // here we loop through all the documents and update the isSeen to true.
      for (var doc in querySnapshotOfCurrentUser.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }

      // here we loop through all the documents and update the isSeen to true.
      for (var doc in querySnapshotOfOtherUser.docs) {
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
