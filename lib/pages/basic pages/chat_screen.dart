import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/providers/zego_avatar_provider.dart';
import 'package:chat_application/routes/rotues_names.dart';
import 'package:chat_application/widgets/send_call_button.dart';

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

  const ChatScreen({
    super.key,
    required this.userID,
    required this.name,
    required this.email,
    required this.imageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Declare a GlobalKey for the AnimatedList
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // TextEditingController declaration
  late TextEditingController _messageController;

  // StreamSubscription declaration (for listening the Sender message typing satues)
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> subscription;

  // variables decalaration
  final FirebaseFireStoreMethods firebaseFireStoreMethods = FirebaseFireStoreMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isTyping = false;
  Timer? _typingTimer;
  bool _isUserTyping = false;

  // Border Style
  final OutlineInputBorder borderStyle = OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.transparent),
    borderRadius: BorderRadius.circular(50),
  );

  // Method tha send the message.
  void sendMessage() async {
    await firebaseFireStoreMethods.sendMessage(reciverID: widget.userID, message: _messageController.text);

    // after sending the message we clear the controllar
    _messageController.clear();
  }

  @override
  void initState() {
    super.initState();

    context.read<ZegoAvatarProvider>().updateAvatarImageUrl(imageURL: widget.imageUrl);
    // ZegoMethods.onUserLogin();

    _messageController = TextEditingController();
    firebaseFireStoreMethods.isInsideChatRoom(status: true);

    // get the other side of user collection
    final otherSideofUser = _db.collection("users").doc(widget.userID).snapshots();

    // Method for listening sender user "isTyping" Status on Firestore (whenever it change to truethen we show the Typing Status in Chat Screen in the Bottom Part)
    subscription = otherSideofUser.listen(
      (snapshot) {
        if (mounted) {
          context.read<TypingStatusProvider>().changeStatus(status: snapshot.get("isTyping"));
          context.read<OnlineOfflineStatusProvider>().changeStatus(status: snapshot.get("isOnline"), lastSeen: snapshot.get("lastSeen"));
        }

        //! When Other side of user get inside the chat room then udpate all the unseen message to seen.
        firebaseFireStoreMethods.getAllUnseenMessagesAndUpdateToSeen(
          userID: _auth.currentUser!.uid,
          otherUserID: widget.userID,
          isOtherUserInsideChatRoom: snapshot.get("isInsideChatRoom"),
          isOnline: snapshot.get("isOnline"),
        );

        //! When other side of user get inside the chat room them we clear the Unseen Message List.
        if (snapshot.get("isInsideChatRoom")) {
          firebaseFireStoreMethods.deleteUnseenMessages(userID: widget.userID);
        }
      },
      onDone: () {
        throw "Sender Data fetched";
      },
      onError: (error) {
        throw error.toString();
      },
    );
  }

  // Method for updating isTyping Status.
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
                      //! Navigate User to Back Screen.
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
                            //! If User online then we show green dot.
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
                                // else we show SizedBox().
                                : const SizedBox(),
                          ],
                        );
                      }),
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
                          style: const TextStyle(
                            color: Color.fromARGB(255, 226, 221, 221),
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
                    // if data is loading...
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    }

                    // if snapshot has data.
                    if (snapshot.hasData) {
                      // convert the snapshot data into List<<MyMessageModel>
                      final List<MessageModel> data = snapshot.data as List<MessageModel>;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView.builder(
                              key: _listKey,
                              // set reverse to true so the listview start from the bottom so when user get into chat page so automatically
                              // get down to bottom (last message)
                              reverse: true,
                              padding: EdgeInsets.zero,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                // When reverse: true is used, Adjusts the data indexing to match the reversed scroll order, ensuring the most recent messages are displayed correctly.
                                final reverseIndex = data.length - 1 - index; // suppose data.length == 20 (20 - 1 = 19 - 0 = 19) as so and so..

                                // getting messages by Index.
                                final message = data[reverseIndex];

                                // is current user
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
                                      padding: EdgeInsets.only(left: 15.0, top: 16, bottom: 10),
                                      child: TypingIndicator(),
                                    )
                                  : const SizedBox();
                            },
                          ),
                        ],
                      );
                    }

                    // if snapshot has error.
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Something went wrong ⚠️"),
                      );
                    }

                    // else.
                    else {
                      return const Center(
                        child: Text("Else condition"),
                      );
                    }
                  },
                ),
              ),
            ),

            //! Textfeild section.
            Row(
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
                      filled: true,
                      fillColor: const Color.fromARGB(255, 225, 247, 237),
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
                const SizedBox(width: 10),
                StatefulBuilder(
                  builder: (context, mySetState) {
                    // Add a listener to the TextEditingController to track changes in the text field
                    _messageController.addListener(() {
                      // Use `mySetState` to rebuild the widget inside the `StatefulBuilder`
                      mySetState(() {});
                    });

                    // Check if the text is empty then we show SizedBox Widget.
                    if (_messageController.text.isEmpty) {
                      return const SizedBox(); // Hide the icon when text is empty
                    }
                    // else the text is not empty then we Send Text Icon Widget.
                    else {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
