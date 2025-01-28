import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:colored_print/colored_print.dart';
import 'package:flutter/material.dart';

class AwesomeNotificationsAPI {
  // creating instance of AwesomeNotifications
  static final AwesomeNotifications _notifications = AwesomeNotifications();

  //* This Method initialized the AwesomeNotifications.
  static void initlization() async {
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
  static Future<void> instantNotification({
    required int id,
    required String currentUserID,
    required String senderID,
    required String title,
    required String body,
    Map<String, String?>? payload,
  }) async {
    // if UserId is equal to SenderID then it's means that new message is sended by the current user so we don't gonna show the notification.
    if (senderID == currentUserID) {
      return;
    }
    // else we show the notification.
    else {
      _notifications.createNotification(
        content: NotificationContent(
          id: id,
          channelKey: "basic_channel",
          title: title,
          body: body,
          payload: payload,
          color: Colors.green,
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
  }

  //! Method for canceling all the Awesome Notification.
  static void cancelAllNotifications() {
    _notifications.cancelAll();
    ColoredPrint.warning("All Notification got cancel");
  }
}
