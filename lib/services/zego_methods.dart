// Package imports:

import 'package:chat_application/widgets/custom_avatar.dart';
import 'package:colored_print/colored_print.dart';
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

    ColoredPrint.warning(userID);
    ColoredPrint.warning(name);

    /// 4/5. initialized ZegoUIKitPrebuiltCallInvitationService when account is logged in or re-logged in
    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: 160183049,
      appSign: "497baabd20893bd87376fc8263b93f8e05e9fe60012de0d391efe7b45a9e836d",
      userID: userID!,
      userName: name!,
      plugins: [ZegoUIKitSignalingPlugin()],
      requireConfig: (ZegoCallInvitationData data) {
        final config = (data.invitees.length > 1)
            ? ZegoCallInvitationType.videoCall == data.type
                ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
            : ZegoCallInvitationType.videoCall == data.type
                ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

        /// custom avatar
        config.avatarBuilder = customAvatarBuilder;

        /// support minimizing, show minimizing button
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
