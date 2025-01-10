import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

Widget sendCallButton({
  required bool isVideoCall,
  required TextEditingController inviteeUsersIDTextCtrl,
  void Function(String code, String message, List<String>)? onCallFinished,
}) {
  return ValueListenableBuilder<TextEditingValue>(
    valueListenable: inviteeUsersIDTextCtrl,
    builder: (context, inviteeUserID, _) {
      return ZegoSendCallInvitationButton(
        isVideoCall: isVideoCall,
        invitees: [
          ZegoUIKitUser(
            id: 574036.toString(),
            name: "user heloo",
          )
        ],
        resourceID: 'zego_data',
        iconSize: const Size(40, 40),
        buttonSize: const Size(50, 50),
        onPressed: onCallFinished,
      );
    },
  );
}
