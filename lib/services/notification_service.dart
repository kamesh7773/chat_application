import 'package:awesome_notifications/awesome_notifications.dart';
import '../main.dart';
import '../models/user_model.dart';
import '../routes/rotues_names.dart';
import 'firebase_firestore_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// This method is called when a notification is received while the app is in the background.
// It initializes the app and displays the notification.
// This method is crucial for showing custom notifications when the app is in the background. Do not remove it.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure the Flutter framework is initialized
  await Firebase.initializeApp(); // Initialize Firebase
  await AwesomeNotificationsAPI().instantNotification(remoteMessage: message); // Show the notification
}

class AwesomeNotificationsAPI {
  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Instance of AwesomeNotifications
  static final AwesomeNotifications _notifications = AwesomeNotifications();

  // Initialize AwesomeNotifications
  void initlization() async {
    await _notifications.initialize(
      // Set the notification icon to default by using null
      'resource://drawable/logo',
      // Define Notification Channels
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
      // Define Notification Channel Groups
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: "basic_channel_group",
          channelGroupName: "Basic Group",
        )
      ],
      // Enable debug mode to show notification activities like creation, display, tap, and dismissal
      // debug: true,
    );

    // Request notification permission from the device
    bool isAllowedToSendNotification = await _notifications.isNotificationAllowed();

    if (!isAllowedToSendNotification) {
      _notifications.requestPermissionToSendNotifications();
    }

    // Set listeners for notification events
    _notifications.setListeners(
      onActionReceivedMethod: AwesomeNotificationsAPI.onActionReceivedMethod,
      onNotificationCreatedMethod: AwesomeNotificationsAPI.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: AwesomeNotificationsAPI.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: AwesomeNotificationsAPI.onDismissActionReceivedMethod,
    );

    // Listen for when a user taps on a notification and the app is opened
    FirebaseMessaging.onMessage.listen((RemoteMessage message) => instantNotification(remoteMessage: message));

    // Listen for notifications received while the app is in the background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Called when a new notification or schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  // Called every time a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  // Called if the user dismisses a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

  // Called when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Fetch current user details and other user details
    final UserModel otherUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: receivedAction.payload!["senderID"]!);
    final UserModel currentUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: _auth.currentUser!.uid);

    // Check if the action is a reply
    if (receivedAction.buttonKeyPressed == 'reply') {
      final String replyText = receivedAction.buttonKeyInput; // Get the reply text
      final String senderId = receivedAction.payload?['senderID'] ?? ''; // Get sender ID from payload
      final String rsaPublicKey = receivedAction.payload?['rsaPublicKey'] ?? ''; // Get RSA public key from payload

      if (replyText.isNotEmpty) {
        // Send the reply to the Node.js FCM backend
        await FirebaseFireStoreMethods().sendMessage(
          message: replyText,
          receiverID: senderId,
          recipientPublicKey: rsaPublicKey,
        );

        // Send a notification to the other user if replying directly from the notification
        if (!otherUser.isInsideChatRoom) {
          await sendNotification(
            recipientToken: otherUser.fcmToken,
            title: currentUser.name,
            message: replyText,
          );
        }

        // Dismiss the notification after replying
        AwesomeNotifications().dismiss(receivedAction.id!);
      } else {
        return;
      }
    } else if (receivedAction.buttonKeyPressed == 'Mark_as_read') {
      // Mark messages as seen when the user clicks the "Mark as read" button on the notification
      FirebaseFireStoreMethods().getAllUnseenMessagesAndUpdateToSeen(
        userID: _auth.currentUser!.uid,
        otherUserID: receivedAction.payload!["senderID"]!,
        isOnline: true,
        isOtherUserInsideChatRoom: true,
      );

      // Remove the message from unseen messages
      FirebaseFireStoreMethods().deleteUnseenMessages(
        userID: receivedAction.payload!["senderID"]!,
      );

      // Dismiss the notification
      AwesomeNotifications().dismiss(receivedAction.id!);
    } else if (receivedAction.buttonKeyPressed == 'close') {
      // Dismiss the notification
      AwesomeNotifications().dismiss(receivedAction.id!);
    }

    // Navigate the user to the specific Chat Screen Page
    if (receivedAction.buttonKeyPressed == "") {
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
  }

  // Method for displaying an instant notification
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
          // Set the layout for the notification
          notificationLayout: NotificationLayout.Default,
          payload: {
            "senderID": remoteMessage.data["senderID"],
            "name": remoteMessage.data["name"],
            "email": remoteMessage.data["email"],
            "imageUrl": remoteMessage.data["imageUrl"],
            "rsaPublicKey": remoteMessage.data["recipientPublicKey"],
            "fcmToken": remoteMessage.data["fcmToken"],
          },
        ),
        // Action buttons for the notification
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

  // Method for sending a notification to a specific user using their FCM Token
  static Future<void> sendNotification({required String recipientToken, required String title, required String message}) async {
    // Node.js backend API URL
    const String backendUrl = 'https://mature-sissy-montu-113ea327.koyeb.app/send-notification';

    // Fetch current user details
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
