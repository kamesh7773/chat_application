import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/services/notification_service.dart';
import 'package:colored_print/colored_print.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/zego_avatar_provider.dart';
import '../../routes/rotues_names.dart';
import '../../widgets/send_call_button.dart';

import '../../models/message_model.dart';
import '../../providers/online_offline_status_provider.dart';
import '../../providers/typing_status_provider.dart';
import '../../services/firebase_firestore_methods.dart';
import '../../utils/date_time_calculator_for_users.dart';
import '../../widgets/chatbubble.dart';
import '../../widgets/typing_animation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String userID;
  final String name;
  final String email;
  final String imageUrl;
  final String rsaPublicKey;
  final String fcmToken;

  const ChatScreen({
    super.key,
    required this.userID,
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.rsaPublicKey,
    required this.fcmToken,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Declare a GlobalKey for the AnimatedList
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // TextEditingController declaration
  late TextEditingController _messageController;

  // StreamSubscription declaration (for listening to the sender's message typing status)
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> subscription;

  // Variable declarations
  final storage = const FlutterSecureStorage();
  final FirebaseFireStoreMethods firebaseFireStoreMethods = FirebaseFireStoreMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isTyping = false;
  Timer? _typingTimer;
  bool _isUserTyping = false;
  // ignore: prefer_typing_uninitialized_variables
  late var storedKey;
  // ignore: prefer_typing_uninitialized_variables
  late var storedIV;

  // Border style
  final OutlineInputBorder borderStyle = OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.transparent),
    borderRadius: BorderRadius.circular(50),
  );

  // Method to send the message.
  void sendMessage() async {
    await firebaseFireStoreMethods.sendMessage(receiverID: widget.userID, message: _messageController.text, recipientPublicKey: widget.rsaPublicKey);

    // sending the notification to the other user
    AwesomeNotificationsAPI.sendNotification(
      recipientToken: widget.fcmToken,
      title: widget.name,
      message: _messageController.text.trim(),
    );

    // After sending the message, clear the controller
    _messageController.clear();
  }

  @override
  void initState() {
    super.initState();

    context.read<ZegoAvatarProvider>().updateAvatarImageUrl(imageURL: widget.imageUrl);

    _messageController = TextEditingController();
    firebaseFireStoreMethods.isInsideChatRoom(status: true);

    // Get the other user's collection
    final otherSideofUser = _db.collection("users").doc(widget.userID).snapshots();

    // Method for listening to the sender's "isTyping" status on Firestore (whenever it changes to true, show the typing status in the chat screen at the bottom)
    subscription = otherSideofUser.listen(
      (snapshot) {
        if (mounted) {
          context.read<TypingStatusProvider>().changeStatus(status: snapshot.get("isTyping"));
          context.read<OnlineOfflineStatusProvider>().changeStatus(status: snapshot.get("isOnline"), lastSeen: snapshot.get("lastSeen"));
        }

        //! When the other user enters the chat room, update all unseen messages to seen.
        firebaseFireStoreMethods.getAllUnseenMessagesAndUpdateToSeen(
          userID: _auth.currentUser!.uid,
          otherUserID: widget.userID,
          isOtherUserInsideChatRoom: snapshot.get("isInsideChatRoom"),
          isOnline: snapshot.get("isOnline"),
        );

        //! When the other user enters the chat room, clear the unseen message list.
        if (snapshot.get("isInsideChatRoom")) {
          firebaseFireStoreMethods.deleteUnseenMessages(userID: widget.userID);
        }
      },
      onDone: () {
        throw "Sender data fetched";
      },
      onError: (error) {
        throw error.toString();
      },
    );
  }

  // Method for updating the isTyping status.
  void onTypingStarted() {
    _isUserTyping = true;

    firebaseFireStoreMethods.isUserTyping(userID: _auth.currentUser!.uid, isTyping: _isUserTyping);

    // Reset the timer every time the user types
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _isUserTyping = false;
      firebaseFireStoreMethods.isUserTyping(userID: _auth.currentUser!.uid, isTyping: _isUserTyping);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    subscription.cancel();
    _typingTimer?.cancel();
    firebaseFireStoreMethods.isInsideChatRoom(status: false);
    // ZegoMethods.onUserLogout();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RoutesNames.bottomNavigationBar,
            (Route<dynamic> route) => false,
          );
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            //! App Bar section.
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 10, left: 10, right: 10),
              color: const Color.fromARGB(255, 0, 191, 108),
              width: double.infinity,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      //! Navigate the user to the previous screen.
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        RoutesNames.bottomNavigationBar,
                        (Route<dynamic> route) => false,
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  ),
                  Selector<OnlineOfflineStatusProvider, bool>(
                    selector: (context, data) => data.isOnline,
                    builder: (context, value, child) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              width: 46,
                              height: 46,
                              imageUrl: widget.imageUrl,
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          ),
                          //! If the user is online, show a green dot.
                          value
                              ? Positioned(
                                  bottom: 2,
                                  right: 0.5,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 0, 191, 108),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                )
                              // Otherwise, show a SizedBox().
                              : const SizedBox(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Consumer<OnlineOfflineStatusProvider>(builder: (context, value, child) {
                        return Text(
                          DateTimeCalculatorForUsers.getLastActiveTime(isOnline: value.isOnline, lastSeen: value.userLastSeen.toDate()),
                          style: TextStyle(
                            color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 226, 221, 221) : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }),
                    ],
                  ),
                  const Spacer(flex: 1),
                  sendCallButton(
                    isVideoCall: false,
                    userId: widget.userID,
                    userName: widget.name,
                    imageUrl: widget.imageUrl,
                    icon: const Icon(
                      Icons.call,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  sendCallButton(
                    isVideoCall: true,
                    userId: widget.userID,
                    userName: widget.name,
                    imageUrl: widget.imageUrl,
                    icon: const Icon(
                      Icons.videocam_sharp,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            //! Chat section.
            Expanded(
              child: Center(
                child: StreamBuilder(
                  stream: firebaseFireStoreMethods.getMessages(otherUserID: widget.userID),
                  builder: (context, snapshot) {
                    // If data is loading...
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    }

                    // If snapshot has data.
                    if (snapshot.hasData) {
                      // Convert the snapshot data into a List<MessageModel>
                      final List<MessageModel> data = snapshot.data as List<MessageModel>;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView.builder(
                              key: _listKey,
                              // Set reverse to true so the ListView starts from the bottom, automatically scrolling to the last message when the user enters the chat page.
                              reverse: true,
                              padding: EdgeInsets.zero,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                // When reverse: true is used, adjust the data indexing to match the reversed scroll order, ensuring the most recent messages are displayed correctly.
                                final reverseIndex = data.length - 1 - index;

                                // Get messages by index.
                                final message = data[reverseIndex];

                                // Check if the current user is the sender.
                                var isCurrentUser = message.senderID == _auth.currentUser!.uid;

                                return Chatbubble(
                                  isCurrentUser: isCurrentUser,
                                  message: message.message,
                                  isMessageSeen: message.isSeen,
                                  timestamp: message.timestamp,
                                );
                              },
                            ),
                          ),
                          Selector<TypingStatusProvider, bool>(
                            selector: (context, status) => status.isTypingStatus,
                            builder: (context, specificValue, child) {
                              return specificValue
                                  ? const Padding(
                                      padding: EdgeInsets.only(left: 11.0, top: 2, bottom: 2),
                                      child: TypingIndicator(),
                                    )
                                  : const SizedBox();
                            },
                          ),
                        ],
                      );
                    }

                    // If the snapshot has an error.
                    if (snapshot.hasError) {
                      ColoredPrint.warning(snapshot.error);
                      return const Center(
                        child: Text("Something went wrong ⚠️"),
                      );
                    }

                    // Else condition.
                    else {
                      return const Center(
                        child: Text("Else condition"),
                      );
                    }
                  },
                ),
              ),
            ),

            //! Text field section.
            Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 10),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: InkWell(
                      onTap: () {},
                      child: const Icon(
                        Icons.mic,
                        color: Color.fromARGB(255, 0, 191, 108),
                        size: 28,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      onChanged: (value) {
                        onTypingStarted();
                      },
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type message",
                        prefix: const SizedBox(width: 10),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () {},
                              child: const Icon(
                                Icons.attach_file,
                                color: Color.fromARGB(255, 0, 191, 108),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () {},
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Color.fromARGB(255, 0, 191, 108),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                        ),
                        hintStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        enabledBorder: borderStyle,
                        focusedBorder: borderStyle,
                      ),
                    ),
                  ),
                  StatefulBuilder(
                    builder: (context, mySetState) {
                      // Add a listener to the TextEditingController to track changes in the text field
                      _messageController.addListener(() {
                        // Use `mySetState` to rebuild the widget inside the `StatefulBuilder`
                        mySetState(() {});
                      });

                      // Check if the text is empty, then show a SizedBox widget.
                      if (_messageController.text.isEmpty) {
                        return const SizedBox(); // Hide the icon when text is empty
                      }
                      // Else, if the text is not empty, show the Send Text Icon widget.
                      else {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: sendMessage,
                            child: const Icon(
                              Icons.send,
                              color: Color.fromARGB(255, 0, 191, 108),
                              size: 32,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
