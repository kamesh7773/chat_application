import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CallWidget extends StatelessWidget {
  final bool isCurrentUser;
  final bool isVideoCall;
  final Timestamp timestamp;
  final String callerId;
  final String recipientId;
  final String currentUserId;

  const CallWidget({
    super.key,
    required this.isCurrentUser,
    required this.isVideoCall,
    required this.timestamp,
    required this.callerId,
    required this.recipientId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the current user is the caller or the recipient
    final isCaller = currentUserId == callerId;

    // Text to display based on the user's role (caller or recipient)
    final callTypeText = isCaller ? (isVideoCall ? "Video Call" : "Voice Call") : (isVideoCall ? "Incoming Video Call" : "Incoming Voice Call");

    // Format the timestamp
    final callTime = DateFormat('hh:mm a').format(timestamp.toDate());

    // Colors and alignment based on the user's role
    const iconColor = Colors.white;
    final iconBackgroundColor = isCaller ? const Color.fromARGB(255, 0, 191, 108) : const Color.fromARGB(255, 64, 77, 87);

    final containerColor = isCaller
        ? const Color.fromARGB(255, 0, 191, 108)
        : MediaQuery.of(context).platformBrightness == Brightness.light
            ? const Color.fromARGB(255, 225, 247, 237)
            : const Color.fromARGB(255, 45, 67, 83);

    final borderColor = isCaller ? const Color.fromARGB(255, 0, 191, 108) : const Color.fromARGB(255, 30, 44, 54);

    return Column(
      crossAxisAlignment: isCaller ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: isCaller ? const EdgeInsets.only(right: 10, top: 2, bottom: 4, left: 10) : const EdgeInsets.only(left: 10, top: 2, bottom: 4, right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: containerColor,
            border: Border.all(
              width: isCaller ? 1 : 2,
              color: borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                ),
                padding: const EdgeInsets.all(5),
                child: Icon(
                  isVideoCall ? Icons.videocam_outlined : Icons.phone,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: isCaller ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    callTypeText,
                    style: const TextStyle(fontSize: 15),
                  ),
                  Text(
                    callTime,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
