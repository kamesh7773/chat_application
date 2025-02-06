import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chat_application/main.dart';
import 'package:chat_application/models/user_model.dart';
import 'package:chat_application/routes/rotues_names.dart';
import 'package:chat_application/services/firebase_firestore_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//! This is the method that is called when a notification is received while the app is in the background.
//! It is used to initialize the app and show the notification.
//! This method i working for showing custum notification when app is in background don't remove it.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this line
  await Firebase.initializeApp();
  await AwesomeNotificationsAPI().instantNotification(remoteMessage: message);
}

class AwesomeNotificationsAPI {
  // Variables related to Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // creating instance of AwesomeNotifications
  static final AwesomeNotifications _notifications = AwesomeNotifications();

  //* This Method initialized the AwesomeNotifications.
  void initlization() async {
    await _notifications.initialize(
      // This used for notification icon we set it to null so it will show default notification icon.
      'resource://drawable/logo',
      // Here we define our Notification Channel's
      [
        NotificationChannel(
          channelGroupKey: "basic_channel_group",
          channelKey: "basic_channel",
          channelName: "Basic Notifications",
          channelDescription: "Basic Notification Channel",
          playSound: true,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
        )
      ],
      // Here we define our Notification channel group.
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: "basic_channel_group",
          channelGroupName: "Basic Group",
        )
      ],
      // When set the debug propertie to true then it show every activity of notification like when it created , shows on devices status bar
      // when it taped by user and when it's dismissed by user.
      // debug: true,
    );

    //* Here we ask Notification Permisson from device.
    bool isAllowedToSentNotification = await _notifications.isNotificationAllowed();

    if (!isAllowedToSentNotification) {
      _notifications.requestPermissionToSendNotifications();
    }

    //* Here we are firing the function that we have defined below in this class and these methods run
    //* when any notification get scheduled, displayed, when user dismissed notification, when user taps on a notification etc.
    _notifications.setListeners(
      onActionReceivedMethod: AwesomeNotificationsAPI.onActionReceivedMethod,
      onNotificationCreatedMethod: AwesomeNotificationsAPI.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: AwesomeNotificationsAPI.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: AwesomeNotificationsAPI.onDismissActionReceivedMethod,
    );

    //! Listen for when a user taps on a notification and the app is opened as a result.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) => instantNotification(remoteMessage: message));

    //! Listen for when a notification is received while the app is in the background.
    //! When notification is received from firebase then this method get called and it fires the
    //! method that is responsible for showing awesome notification.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  //? Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  //? Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  //? Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

  //? Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Fetching current User Details of currentUser and OtherUser.
    final UserModel otherUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: receivedAction.payload!["senderID"]!);
    final UserModel currentUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: _auth.currentUser!.uid);

    // Check if the action is a reply
    if (receivedAction.buttonKeyPressed == 'reply') {
      final String replyText = receivedAction.buttonKeyInput; // Get the reply text
      final String senderId = receivedAction.payload?['senderID'] ?? ''; // Get sender ID from payload
      final String rsaPublicKey = receivedAction.payload?['rsaPublicKey'] ?? ''; // Get sender ID from payload

      if (replyText.isNotEmpty) {
        // Sending the reply to node.js FCM backend.
        await FirebaseFireStoreMethods().sendMessage(
          message: replyText,
          receiverID: senderId,
          recipientPublicKey: rsaPublicKey,
        );

        // sending the notification to other user if we directly reply form the notification.
        if (!otherUser.isInsideChatRoom) {
          await sendNotification(
            recipientToken: otherUser.fcmToken,
            title: currentUser.name,
            message: replyText,
          );
        }

        // Dismiss the notification after reply
        AwesomeNotifications().dismiss(receivedAction.id!);
      } else {
        return;
      }
    } else if (receivedAction.buttonKeyPressed == 'Mark_as_read') {
      // Mark as Seen Message when user click on the mark as read button on notification.
      FirebaseFireStoreMethods().getAllUnseenMessagesAndUpdateToSeen(
        userID: _auth.currentUser!.uid,
        otherUserID: receivedAction.payload!["senderID"]!,
        isOnline: true,
        isOtherUserInsideChatRoom: true,
      );

      // remove the message form unse. messages.
      FirebaseFireStoreMethods().deleteUnseenMessages(
        userID: receivedAction.payload!["senderID"]!,
      );

      // Dismiss the notification after reply
      AwesomeNotifications().dismiss(receivedAction.id!);
    } else if (receivedAction.buttonKeyPressed == 'close') {
      // Dismiss the notification after reply
      AwesomeNotifications().dismiss(receivedAction.id!);
    }

    //! Navigate the user to specific  the Chat Screen Page.
    navigatorKey.currentState?.pushNamed(
      RoutesNames.chatScreenPage,
      arguments: {
        "userID": receivedAction.payload!["senderID"],
        "name": receivedAction.payload!["name"],
        "currentUsername": currentUser.name,
        "email": receivedAction.payload!["email"],
        "imageUrl": receivedAction.payload!["imageUrl"],
        "isOnline": otherUser.isOnline,
        "lastSeen": otherUser.lastSeen,
        "rsaPublicKey": receivedAction.payload!["rsaPublicKey"],
        "fcmToken": otherUser.fcmToken,
      },
    );
  }

  //! ------------------------------------
  //! Method for Notification for Chat App
  //! ------------------------------------
  Future<void> instantNotification({
    required RemoteMessage remoteMessage,
  }) async {
    try {
      _notifications.createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: remoteMessage.data['channelKey'],
          title: remoteMessage.data['title'],
          body: remoteMessage.data['body'],
          color: const Color.fromARGB(255, 0, 191, 108),
          largeIcon: remoteMessage.data['imageUrl'],
          //! Here we also set the layout Notification for Chat App.
          notificationLayout: NotificationLayout.Inbox,
          category: NotificationCategory.Message,
          payload: {
            "senderID": remoteMessage.data["senderID"],
            "name": remoteMessage.data["name"],
            "email": remoteMessage.data["email"],
            "imageUrl": remoteMessage.data["imageUrl"],
            "rsaPublicKey": remoteMessage.data["recipientPublicKey"],
            "fcmToken": remoteMessage.data["fcmToken"],
          },
        ),

        //! Here is the action button that we show in notification so user can reply message or perfrom some action.
        actionButtons: [
          NotificationActionButton(key: "reply", label: "reply", requireInputText: true),
          NotificationActionButton(key: "Mark_as_read", label: "Mark as read"),
          NotificationActionButton(key: "close", label: "close"),
        ],
      );
    } catch (e) {
      throw Exception(e);
    }
  }

  //! Method for sending notification to sepcific user by the FCM Token.
  static Future<void> sendNotification({required String recipientToken, required String title, required String message}) async {
    // Node JS backend API URL
    const String backendUrl = 'https://mature-sissy-montu-113ea327.koyeb.app/send-notification';

    // Fetching current User Details.
    final DocumentReference currentUserDoc = _db.collection("users").doc(_auth.currentUser!.uid);
    final DocumentSnapshot docSnapshot = await currentUserDoc.get();
    final UserModel user = UserModel.fromJson(docSnapshot.data() as Map<String, dynamic>);

    final response = await http.post(
      Uri.parse(backendUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        <String, dynamic>{
          'token': recipientToken,
          'title': title,
          'body': message,
          'senderID': user.userID,
          'name': user.name,
          'email': user.email,
          'imageUrl': user.imageUrl,
          'recipientPublicKey': user.rsaPublicKey,
        },
      ),
    );

    if (response.statusCode == 200) {
      debugPrint('Notification sent successfully ✅');
    } else {
      throw 'Failed to send notification: ${response.body}';
    }
  }
}
