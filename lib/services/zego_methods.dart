// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/main.dart';
import 'package:chat_application/models/message_model.dart';
import 'package:chat_application/models/user_model.dart';
import 'package:chat_application/providers/zego_avatar_provider.dart';
import 'package:chat_application/services/firebase_firestore_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colored_print/colored_print.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegoMethods {
  /// Called when the user logs in
  static Future<void> onUserLogin() async {
    // Variables related to Firebase instances
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore db = FirebaseFirestore.instance;
    // Fetching current user details from Shared Preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Instance of FirestoreMethod class
    final FirebaseFireStoreMethods firebaseFireStoreMethods = FirebaseFireStoreMethods();

    final String? userID = prefs.getString('userID');
    final String? name = prefs.getString('name');

    /// Initialize ZegoUIKitPrebuiltCallInvitationService when the account is logged in or re-logged in
    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: 160183049,
      appSign: "497baabd20893bd87376fc8263b93f8e05e9fe60012de0d391efe7b45a9e836d",
      userID: userID!,
      userName: name!,
      plugins: [ZegoUIKitSignalingPlugin()],
      notificationConfig: ZegoCallInvitationNotificationConfig(
        androidNotificationConfig: ZegoCallAndroidNotificationConfig(
          callChannel: ZegoCallAndroidNotificationChannelConfig(
            channelID: "ZegoUIKit",
            channelName: "Call Notifications",
            sound: "call",
            icon: "call",
          ),
          missedCallChannel: ZegoCallAndroidNotificationChannelConfig(
            channelID: "MissedCall",
            channelName: "Missed Call",
            sound: "missed_call",
            icon: "missed_call",
            vibrate: false,
          ),
        ),
      ),
      config: ZegoCallInvitationConfig(
        endCallWhenInitiatorLeave: true,
        missedCall: ZegoCallInvitationMissedCallConfig(
          enabled: true,
        ),
      ),
      invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
        //! Triggered when the user receives any kind of call (audio/video)
        onIncomingCallReceived: (callID, caller, callType, callees, customData) async {
          // Retriving the UserID of person that we are calling to.
          final String receiverID = caller.id;

          try {
            // retiving the details of callerUser
            final UserModel otherUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: receiverID);

            // Update image using Provider method on Zego Method Avatar Image URL
            navigatorKey.currentContext!.read<ZegoAvatarProvider>().updateAvatarImageUrl(imageURL: otherUser.imageUrl);

            // Update call logs in the user's Firebase database
            firebaseFireStoreMethods.updateCallLogs(
              userName: caller.name,
              imageUrl: otherUser.imageUrl,
              isVideoCall: callType == ZegoCallInvitationType.videoCall ? true : false,
              isInComing: true,
            );
          } catch (error) {
            throw error.toString();
          }
        },
        //! Triggered when the user dials any kind of call to another user (audio/video)
        onOutgoingCallSent: (callID, caller, callType, callees, customData) async {
          // Retriving the UserID of person that we are calling to.
          final String receiverID = callees.first.id;

          try {
            // retiving the details of callerUser
            final UserModel otherUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: receiverID);

            // Update call logs in the user's Firebase database
            firebaseFireStoreMethods.updateCallLogs(
              userName: callees.first.name,
              imageUrl: otherUser.imageUrl,
              isVideoCall: callType == ZegoCallInvitationType.videoCall ? true : false,
              isInComing: false,
            );

            // Adding the new message on chatRoom collection about the call (Voice/Video Call)
            // Create a new message
            MessageModel newMessage = MessageModel(
              senderID: auth.currentUser!.uid,
              reciverID: receiverID,
              isVideoCall: callType == ZegoCallInvitationType.videoCall ? true : false,
              message: "null",
              encryptedAESKey: "null",
              encryptedIV: "null",
              isSeen: true,
              timestamp: Timestamp.now(),
            );

            // Construct chatRoom ID for two users (sorted to ensure uniqueness)
            List<String> ids = [auth.currentUser!.uid, receiverID];
            ids.sort();
            // Create the chatRoomID by combining currentUserID and receiverUserID. ("ZEL264FDSXEFD_KJLADSFJLSAJD")
            String chatRoomID = ids.join("_");

            // Add new message to the database.
            await db.collection("chatRooms").doc(chatRoomID).collection("messages").add(newMessage.toMap());
          } catch (error) {
            throw error.toString();
          }
        },
      ),
      requireConfig: (ZegoCallInvitationData data) {
        final config = (data.invitees.length > 1)
            ? ZegoCallInvitationType.videoCall == data.type
                ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
            : ZegoCallInvitationType.videoCall == data.type
                ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

        /// Custom avatar
        config.avatarBuilder = (context, size, user, extraInfo) {
          return Selector<ZegoAvatarProvider, String?>(
              selector: (context, data) => data.imageUrl,
              builder: (context, imageUrl, child) {
                return CachedNetworkImage(
                  imageUrl: imageUrl ?? data.customData,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              });
        };

        /// Support minimizing, show minimizing button
        config.bottomMenuBar.hideByClick = false;
        config.topMenuBar.isVisible = true;
        config.topMenuBar.buttons.insert(0, ZegoCallMenuBarButtonName.minimizingButton);
        config.topMenuBar.buttons.insert(1, ZegoCallMenuBarButtonName.soundEffectButton);

        return config;
      },
    );
  }

  /// Called when the user logs out
  static void onUserLogout() {
    /// De-initialize ZegoUIKitPrebuiltCallInvitationService when the account is logged out
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}
