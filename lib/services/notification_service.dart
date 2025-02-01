import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:colored_print/colored_print.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//! This is the method that is called when a notification is received while the app is in the background.
//! It is used to initialize the app and show the notification.
//! This method i working for showing custum notification when app is in background please don't remove it.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this line
  await Firebase.initializeApp();
  await AwesomeNotificationsAPI().instantNotification(message);
}

class AwesomeNotificationsAPI {
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) => instantNotification(message));

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
    ColoredPrint.warning(receivedAction.buttonKeyPressed);

    
    // Check if the action is a reply
    if (receivedAction.buttonKeyPressed == 'reply') {
      final String replyText = receivedAction.buttonKeyInput; // Get the reply text
      final String senderId = receivedAction.payload?['senderId'] ?? ''; // Get sender ID from payload

      if (replyText.isNotEmpty) {
        // Send the reply to your backend or handle it as needed
        ColoredPrint.success('Reply: $replyText to Sender: $senderId');

        // Example: Send reply to backend
        // await sendReplyToBackend(senderId, replyText);

        // Dismiss the notification after reply
        AwesomeNotifications().dismissAllNotifications();
      } else {
        ColoredPrint.error('Reply text or sender ID is empty');
      }
    } else if (receivedAction.buttonKeyPressed == 'Mark_as_read') {
      // Handle mark as read action
      ColoredPrint.success('Mark as read pressed');
    } else if (receivedAction.buttonKeyPressed == 'close') {
      // Handle close action
      ColoredPrint.success('Close pressed');
    }

    //! Navigate the user to specific  the Chat Screen Page.

    //  MyApp.navigatorKey.currentState?.push(
    //    MaterialPageRoute(
    //      builder: (context) => NotificationPage(receivedAction: receivedAction),
    //    ),
    //  );
  }

  //! ------------------------------------
  //! Method for Notification for Chat App
  //! ------------------------------------
  Future<void> instantNotification(RemoteMessage remoteMessage) async {
    try {
      _notifications.createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: remoteMessage.data['channelKey'],
          title: remoteMessage.data['title'],
          body: remoteMessage.data['body'],
          color: const Color.fromARGB(255, 0, 191, 108),
          //! Here we also set the layout Notification for Chat App.
          notificationLayout: NotificationLayout.Inbox,
          category: NotificationCategory.Message,
        ),
        //! Here is the action button that we show in notification so user can reply message or perfrom some action.
        actionButtons: [
          NotificationActionButton(key: "1", label: "reply", requireInputText: true),
          NotificationActionButton(key: "2", label: "Mark as read"),
          NotificationActionButton(key: "3", label: "close"),
        ],
      );
    } catch (e) {
      throw Exception(e);
    }
  }

  //! Method for sending notification to sepcific user by the FCM Token.
  static Future<void> sendNotification({required String recipientToken, required String title, required String message}) async {
    const String backendUrl = 'https://mature-sissy-montu-113ea327.koyeb.app/send-notification'; // backend URL

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
