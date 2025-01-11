import 'package:flutter/material.dart';

class AudioAndVideoPage extends StatefulWidget {
  final String callID;
  final String userName;
  const AudioAndVideoPage({
    super.key,
    required this.callID,
    required this.userName,
  });

  @override
  State<AudioAndVideoPage> createState() => _AudioAndVideoPageState();
}

class _AudioAndVideoPageState extends State<AudioAndVideoPage> {
  @override
  Widget build(BuildContext context) {
    return const Text("hdsfas");
  }
}
