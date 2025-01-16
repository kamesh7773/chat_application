import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Chatbubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final bool isMessageSeen;
  final Timestamp timestamp;

  const Chatbubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.timestamp,
    required this.isMessageSeen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                margin: isCurrentUser ? const EdgeInsets.only(right: 2, top: 2, bottom: 4, left: 100) : const EdgeInsets.only(left: 10, top: 2, bottom: 4, right: 100),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? const Color.fromARGB(255, 0, 191, 108)
                      : MediaQuery.of(context).platformBrightness == Brightness.light
                          ? const Color.fromARGB(255, 225, 247, 237)
                          : const Color.fromARGB(255, 45, 67, 83),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isCurrentUser
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end, // Align text and time
                        mainAxisSize: MainAxisSize.min, // Shrink-wrap the content
                        children: [
                          Flexible(
                            child: SelectableText(
                              message,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(width: 4), // Spacing between message and timestamp
                          Text(
                            DateFormat('hh:mm a').format(timestamp.toDate()),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end, // Align text and time
                        mainAxisSize: MainAxisSize.min, // Shrink-wrap the content
                        children: [
                          Flexible(
                            child: SelectableText(
                              message,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),

                          const SizedBox(width: 4), // Spacing between message and timestamp
                          Text(
                            DateFormat('hh:mm a').format(timestamp.toDate()),
                            style: TextStyle(
                              fontSize: 9,
                              color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 87, 87, 87) : const Color.fromARGB(255, 228, 219, 219),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            isCurrentUser
                ? Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Icon(
                          Icons.check_circle,
                          color: isMessageSeen ? const Color.fromARGB(255, 0, 191, 108) : const Color.fromARGB(255, 123, 122, 122),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                : const SizedBox(),
          ],
        ),
      ],
    );
  }
}
