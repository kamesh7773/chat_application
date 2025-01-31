import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:colored_print/colored_print.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    ColoredPrint.warning(receivedAction.buttonKeyInput);
    ColoredPrint.warning(receivedAction.buttonKeyPressed);
    // Your code goes here

    // MyApp.navigatorKey.currentState?.push(
    //   MaterialPageRoute(
    //     builder: (context) => NotificationPage(receivedAction: receivedAction),
    //   ),
    // );
  }

  //! ------------------------------------
  //! Method for Notification for Chat App
  //! ------------------------------------
  Future<void> instantNotification(RemoteMessage remoteMessage) async {
    ColoredPrint.warning(remoteMessage.data);
    _notifications.createNotification(
      content: NotificationContent(
        id: UniqueKey().hashCode,
        channelKey: "basic_channel",
        title: remoteMessage.data['title'],
        body: remoteMessage.data['body'],
        color: const Color.fromARGB(255, 0, 191, 108),
        //! Here we also set the layout Notification for Chat App.
        notificationLayout: NotificationLayout.Inbox,
      ),
      //! Here is the action button that we show in notification so user can reply message or perfrom some action.
      actionButtons: [
        NotificationActionButton(key: "1", label: "reply", requireInputText: true),
        NotificationActionButton(key: "2", label: "Mark as read"),
        NotificationActionButton(key: "3", label: "close"),
      ],
    );
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
