// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/main.dart';
import 'package:chat_application/models/user_model.dart';
import 'package:chat_application/providers/zego_avatar_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegoMethods {
  /// on user login
  static void onUserLogin() async {
    // Fecting Current User Details from the Shared Preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userID = prefs.getString('userID');
    final String? name = prefs.getString('name');

    /// 4/5. initialized ZegoUIKitPrebuiltCallInvitationService when account is logged in or re-logged in
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
        onIncomingCallReceived: (callID, caller, callType, callees, customData) async {
          // get the current user ID
          final String currentUserID = caller.id;

          // get the user collection
          final CollectionReference users = FirebaseFirestore.instance.collection("users");

          try {
            // get the current user document
            final DocumentSnapshot userDocument = await users.doc(currentUserID).get();
            // convert the document data into UserModel
            final UserModel user = UserModel.fromJson(userDocument.data() as Map<String, dynamic>);

            navigatorKey.currentContext!.read<ZegoAvatarProvider>().updateAvatarImageUrl(imageURL: user.imageUrl);
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

        /// custom avatar
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

        /// support minimizing, show minimizing button
        config.bottomMenuBar.hideByClick = false;
        config.topMenuBar.isVisible = true;
        config.topMenuBar.buttons.insert(0, ZegoCallMenuBarButtonName.minimizingButton);
        config.topMenuBar.buttons.insert(1, ZegoCallMenuBarButtonName.soundEffectButton);

        return config;
      },
    );
  }

  /// on user logout
  static void onUserLogout() {
    /// 5/5. de-initialization ZegoUIKitPrebuiltCallInvitationService when account is logged out
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}
