import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CallWidget extends StatelessWidget {
  final bool isCurrentUser;
  final bool isVideoCall;
  final bool isIncoming;
  final Timestamp timestamp;

  const CallWidget({
    super.key,
    required this.isCurrentUser,
    required this.isVideoCall,
    required this.isIncoming,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: isCurrentUser ? const EdgeInsets.only(right: 2, top: 2, bottom: 4, left: 10) : const EdgeInsets.only(left: 10, top: 2, bottom: 4, right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isCurrentUser
                ? const Color.fromARGB(255, 0, 191, 108)
                : MediaQuery.of(context).platformBrightness == Brightness.light
                    ? const Color.fromARGB(255, 225, 247, 237)
                    : const Color.fromARGB(255, 45, 67, 83),
            border: Border.all(
              width: isCurrentUser ? 1 : 2,
              color: isCurrentUser ? Colors.white : const Color.fromARGB(255, 30, 44, 54),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isCurrentUser ? const Color.fromARGB(255, 0, 191, 108) : const Color.fromARGB(255, 64, 77, 87),
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                ),
                padding: const EdgeInsets.all(5),
                child: Icon(
                  color: isCurrentUser ? Colors.white : Colors.white,
                  isVideoCall ? Icons.videocam_outlined : Icons.phone_callback_outlined,
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isVideoCall ? const Text("Video Call") : const Text("Voice Call"),
                  Text(
                    DateFormat('hh:mm a').format(timestamp.toDate()),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
