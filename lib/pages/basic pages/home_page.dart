import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/providers/last_message_provider.dart';
import 'package:chat_application/utils/date_time_calculator_for_users.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firebase_firestore_methods.dart';
import '../../utils/date_time_calculator_for_unseenmsg.dart';
import '../../routes/rotues_names.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFireStoreMethods _firebaseFireStoreMethods = FirebaseFireStoreMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //! AppBar
          Container(
            width: double.infinity,
            color: Color.fromARGB(255, 0, 191, 108),
            child: Column(
              children: [
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Chats",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        //! Navigate user to Search Page
                        Navigator.of(context).pushNamed(
                          RoutesNames.searchPage,
                          arguments: "Chats",
                        );
                      },
                      icon: Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      ActionChip(
                        onPressed: () {},
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        shadowColor: Colors.black,
                        elevation: 3,
                        label: Text(
                          "Recent message",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(
                            color: Colors.white,
                            width: 0.7,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: ActionChip(
                          onPressed: () {
                            //! Navigate user to Active Users Page.
                            Navigator.of(context).pushNamed(RoutesNames.activeUserPage);
                          },
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          label: Text(
                            "Active",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Color.fromARGB(255, 0, 191, 108),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(
                              color: Colors.white,
                              width: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
              ],
            ),
          ),
          //! User Chat List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firebaseFireStoreMethods.fetchingUsers(),
              builder: (context, snapshot) {
                // If snapshot is still loading then show CircularProgressIndicator.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // If snapshot has error then show error message.
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }

                // If snapshot has data then show ListView.builder.
                if (snapshot.hasData) {
                  // Here we are converting the snapshot data into List<UserModel>.
                  final List<UserModel> listofUser = snapshot.data!;

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: listofUser.length,
                    itemBuilder: (context, index) {
                      // retiving each user data from UserModal.
                      final user = listofUser[index];

                      // This method get called for every other User and we pass with his userID.
                      context.read<LastMessageProvider>().fetchLastMsg(otherUserID: user.userID);

                      return ListTile(
                        onTap: () {
                          //! Navigate user to Chat Screen Page.
                          Navigator.of(context).pushNamed(
                            RoutesNames.chatScreenPage,
                            arguments: {
                              "userID": user.userID,
                              "name": user.name,
                              "email": user.email,
                              "imageUrl": user.imageUrl,
                              "isOnline": user.isOnline,
                              "lastSeen": user.lastSeen,
                            },
                          );
                        },
                        leading: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: CachedNetworkImage(
                                fit: BoxFit.fitHeight,
                                width: 50,
                                height: 50,
                                imageUrl: user.imageUrl,
                                errorWidget: (context, url, error) {
                                  return const Icon(Icons.error);
                                },
                              ),
                            ),
                            //! If User online then we show green dot.
                            user.isOnline
                                ? Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: Color.fromARGB(255, 0, 191, 108),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  )
                                // else we show SizedBox().
                                : SizedBox(),
                          ],
                        ),
                        title: Text(
                          user.name,
                          maxLines: 1,
                        ),
                        //! if UnseenMessage List is Empty then we show the last Msg in subtitle as normal text other wise we show lastMsg in BOLD Text.
                        subtitle: user.unSeenMessages!.isEmpty
                            ? Selector<LastMessageProvider, String>(
                                // Here we fetch the Last Message of other User ID from Map that we create and we store the lastMsg with the key name of his User ID so it will very easy to retive
                                // because we can fetch easly with provided UserID from map.
                                selector: (context, provider) => provider.getLastMsg(user.userID),
                                builder: (context, value, child) {
                                  return Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  );
                                },
                              )
                            : Selector<LastMessageProvider, String>(
                                // Here we fetch the Last Message of other User ID from Map that we create and we store the lastMsg with the key name of his User ID so it will very easy to retive
                                // because we can fetch easly with provided UserID from map.
                                selector: (context, provider) => provider.getLastMsg(user.userID),
                                builder: (context, value, child) {
                                  return Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  );
                                },
                              ),
                        //! if UnseenMessage List is Empty then...
                        trailing: user.unSeenMessages!.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  DateTimeCalculatorForUsers.getLastActiveTime(lastSeen: user.lastSeen.toDate(), isOnline: user.isOnline),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              )
                            //! If UnserSeenMessage Contains the Message then...
                            : user.unSeenMessages!.last.reciverId == _auth.currentUser!.uid
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 80),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          DateTimeCalculatorForUnseenmsg.getLastActiveTime(lastSeen: user.unSeenMessages!.last.timeStamp.toDate()),
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color.fromARGB(255, 0, 191, 108),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 0),
                                            child: Text(
                                              user.unSeenMessages!.length.toString(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      DateTimeCalculatorForUsers.getLastActiveTime(lastSeen: user.lastSeen.toDate(), isOnline: user.isOnline),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color.fromARGB(255, 116, 114, 114),
                                      ),
                                    ),
                                  ),
                      );
                    },
                  );
                }

                // else condiation
                else {
                  return Center(
                    child: Text("Else Condition"),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 0, 191, 108),
        onPressed: () {},
        child: Icon(
          Icons.person_add_alt_1,
          color: Colors.white,
        ),
      ),
    );
  }
}
