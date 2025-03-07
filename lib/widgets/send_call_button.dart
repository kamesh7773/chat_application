import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

Widget sendCallButton({
  required bool isVideoCall,
  required userId,
  required userName,
  required String imageUrl,
  required Icon icon,
}) {
  return ZegoSendCallInvitationButton(
    isVideoCall: isVideoCall,
    invitees: [
      ZegoUIKitUser(
        id: userId,
        name: userName,
      ),
    ],
    customData: imageUrl,
    resourceID: 'zego_call',
    icon: ButtonIcon(icon: icon),
    iconSize: const Size(40, 40),
    buttonSize: const Size(50, 50),
  );
}
