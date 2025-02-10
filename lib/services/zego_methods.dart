// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/main.dart';
import 'package:chat_application/models/message_model.dart';
import 'package:chat_application/models/user_model.dart';
import 'package:chat_application/providers/zego_avatar_provider.dart';
import 'package:chat_application/services/firebase_firestore_methods.dart';
import 'package:chat_application/services/message_encrption_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:provider/provider.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegoMethods {
  /// Called when the user logs in
  static Future<void> onUserLogin() async {
    // Initialize Firebase instances
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore db = FirebaseFirestore.instance;

    // Fetch current user details from Shared Preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Instance of FirestoreMethod class
    final FirebaseFireStoreMethods firebaseFireStoreMethods = FirebaseFireStoreMethods();

    // Retrieve user ID and name from Shared Preferences
    final String? userID = prefs.getString('userID');
    final String? name = prefs.getString('name');

    /// Initialize ZegoUIKitPrebuiltCallInvitationService when the account is logged in or re-logged in
    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: 239722986,
      appSign: "c326e362536ff903846997e72f8aa030adc8454ea580bbb1c6a3890eefc9aa08",
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
          // Retrieve the UserID of the caller
          final String receiverID = caller.id;

          try {
            // Retrieve the details of the caller
            final UserModel otherUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: receiverID);

            // Update avatar image URL using Provider method
            navigatorKey.currentContext!.read<ZegoAvatarProvider>().updateAvatarImageUrl(imageURL: otherUser.imageUrl);

            // Update call logs in the user's Firebase database
            firebaseFireStoreMethods.updateCallLogs(
              userID: otherUser.userID,
              userName: caller.name,
              imageUrl: otherUser.imageUrl,
              isVideoCall: callType == ZegoCallInvitationType.videoCall,
              isInComing: true,
            );
          } catch (error) {
            throw error.toString();
          }
        },
        //! Triggered when the user initiates any kind of call to another user (audio/video)
        onOutgoingCallSent: (callID, caller, callType, callees, customData) async {
          // Retrieve the UserID of the callee
          final String receiverID = callees.first.id;

          try {
            // Retrieve the details of the callee
            final UserModel otherUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: receiverID);

            // Update call logs in the user's Firebase database
            firebaseFireStoreMethods.updateCallLogs(
              userID: otherUser.userID,
              userName: callees.first.name,
              imageUrl: otherUser.imageUrl,
              isVideoCall: callType == ZegoCallInvitationType.videoCall,
              isInComing: false,
            );

            // Parse the RSA public key of the recipient from PEM format
            RsaKeyHelper helper = RsaKeyHelper();
            final RSAPublicKey publicKey = helper.parsePublicKeyFromPem(otherUser.rsaPublicKey);

            // Encrypt the message using AES
            final result = await MessageEncrptionService().messageEncryption(message: "message");

            // Encrypt AES Key & IV using the recipient's public RSA key
            String encryptedAESKey = MessageEncrptionService().rsaEncrypt(data: result.aesKey.bytes, publicKey: publicKey);
            String encryptedIV = MessageEncrptionService().rsaEncrypt(data: result.iv.bytes, publicKey: publicKey);

            // Create a new message for the call (Voice/Video Call)
            MessageModel newMessage = MessageModel(
              senderID: auth.currentUser!.uid,
              reciverID: receiverID,
              isVideoCall: callType == ZegoCallInvitationType.videoCall,
              callerID: auth.currentUser!.uid,
              message: result.encryptedMessage,
              encryptedAESKey: encryptedAESKey,
              encryptedIV: encryptedIV,
              isSeen: true,
              timestamp: Timestamp.now(),
            );

            // Construct chatRoom ID for two users (sorted to ensure uniqueness)
            List<String> ids = [auth.currentUser!.uid, receiverID];
            ids.sort();
            String chatRoomID = ids.join("_");

            // Add new message to the database
            await db.collection("chatRooms").doc(chatRoomID).collection("messages").add(newMessage.toMap());
          } catch (error) {
            throw error.toString();
          }
        },
      ),
      requireConfig: (ZegoCallInvitationData data) {
        // Determine the call configuration based on the number of invitees and call type
        final config = (data.invitees.length > 1)
            ? ZegoCallInvitationType.videoCall == data.type
                ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
            : ZegoCallInvitationType.videoCall == data.type
                ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

        /// Custom avatar builder
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
            },
          );
        };

        /// Support minimizing, show minimizing button
        config.bottomMenuBar.hideByClick = true;
        config.topMenuBar.isVisible = true;
        config.topMenuBar.buttons.insert(0, ZegoCallMenuBarButtonName.chatButton);
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
