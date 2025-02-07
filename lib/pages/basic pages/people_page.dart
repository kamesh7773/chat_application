import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../services/firebase_firestore_methods.dart';
import '../../routes/rotues_names.dart';
import 'package:flutter/material.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final FirebaseFireStoreMethods _firebaseFireStoreMethods = FirebaseFireStoreMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final String currentUsername;

  void fetchingcurrentUsername() async {
    final UserModel currentUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: _auth.currentUser!.uid);
    currentUsername = currentUser.name;
  }

  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final name = parts[0];
    final domain = parts[1];

    final maskedName = name[0] + '*' * (name.length - 2) + name[name.length - 1];

    return '$maskedName@$domain';
  }

  @override
  void initState() {
    super.initState();
    fetchingcurrentUsername();
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
            //! AppBar
            Container(
              width: double.infinity,
              color: const Color.fromARGB(255, 0, 191, 108),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "People",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          //! Navigate the user to the Search Page.
                          Navigator.of(context).pushNamed(
                            RoutesNames.searchPage,
                            arguments: "People",
                          );
                        },
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            //! User List
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _firebaseFireStoreMethods.fetchingUsers(),
                builder: (context, snapshot) {
                  // If the snapshot is still loading, show a CircularProgressIndicator.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // If the snapshot has an error, show an error message.
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(snapshot.error.toString()),
                    );
                  }

                  if (snapshot.hasData) {
                    // Convert the snapshot data into a List<UserModel>.
                    final List<UserModel> listOfUser = snapshot.data!;
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: listOfUser.length,
                      itemBuilder: (context, index) {
                        final user = listOfUser[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            onTap: () {
                              //! Navigate the user to the Chat Screen Page.
                              Navigator.of(context).pushNamed(
                                RoutesNames.chatScreenPage,
                                arguments: {
                                  "userID": user.userID,
                                  "name": user.name,
                                  "currentUsername": currentUsername,
                                  "email": user.email,
                                  "imageUrl": user.imageUrl,
                                  "isOnline": user.isOnline,
                                  "lastSeen": user.lastSeen,
                                  "rsaPublicKey": user.rsaPublicKey,
                                  "fcmToken": user.fcmToken,
                                },
                              );
                            },
                            leading: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: CachedNetworkImage(
                                    fit: BoxFit.fitHeight,
                                    width: 55,
                                    height: 55,
                                    imageUrl: user.imageUrl,
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  ),
                                ),
                                //! If the user is online, show a green dot.
                                user.isOnline
                                    ? Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 13,
                                          height: 13,
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(255, 0, 191, 108),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      )
                                    // Otherwise, show an empty SizedBox.
                                    : const SizedBox(),
                              ],
                            ),
                            title: Text(user.name),
                            subtitle: Text(
                              maskEmail(user.email),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 104, 101, 101) : const Color.fromARGB(255, 160, 153, 153),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Else condition
                  else {
                    return const Center(
                      child: Text("Else Condition"),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
