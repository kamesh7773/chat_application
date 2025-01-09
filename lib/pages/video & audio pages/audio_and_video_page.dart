import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class AudioAndVideoPage extends StatefulWidget {
  final String callID;
  final String userName;
  const AudioAndVideoPage({super.key, required this.callID, required this.userName,});

  @override
  State<AudioAndVideoPage> createState() => _AudioAndVideoPageState();
}

class _AudioAndVideoPageState extends State<AudioAndVideoPage> {
  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: 160183049,
      appSign: "497baabd20893bd87376fc8263b93f8e05e9fe60012de0d391efe7b45a9e836d",
      callID: widget.callID,
      userID: "asdjfljsdlfjsdkljf",
      userName: widget.userName,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
    );
  }
}
