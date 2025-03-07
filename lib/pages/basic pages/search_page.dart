import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../routes/rotues_names.dart';
import '../../services/firebase_firestore_methods.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SearchPage extends StatefulWidget {
  final String heading;
  const SearchPage({super.key, required this.heading});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Variable declaration
  String searchName = "";
  final FirebaseFireStoreMethods _firebaseFireStoreMethods = FirebaseFireStoreMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final String currentUsername;

  void fetchingcurrentUsername() async {
    final UserModel currentUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: _auth.currentUser!.uid);
    currentUsername = currentUser.name;
  }

  @override
  void initState() {
    super.initState();
    fetchingcurrentUsername();
  }

  // Border style
  final OutlineInputBorder borderStyle = OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.transparent),
    borderRadius: BorderRadius.circular(50),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //! AppBar
          Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 0, 191, 108),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          //! Navigate the user to the Home Page.
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        widget.heading,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        searchName = value;
                      });
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      hintText: "Search",
                      prefixIcon: const Icon(Icons.search),
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 114, 111, 111),
                        fontWeight: FontWeight.bold,
                      ),
                      enabledBorder: borderStyle,
                      focusedBorder: borderStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          //! User Chat List
          const Padding(
            padding: EdgeInsets.only(left: 18, top: 20, bottom: 10),
            child: Text(
              "Suggested",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 145, 141, 141),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firebaseFireStoreMethods.searchingUserBasedOnName(keyword: searchName),
              builder: (context, snapshot) {
                // If the snapshot is still loading, show a CircularProgressIndicator.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.progressiveDots(
                      color: const Color.fromARGB(255, 0, 191, 108),
                      size: 50,
                    ),
                  );
                }

                // If the snapshot has an error, show an error message.
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }

                // If the snapshot has data, show a ListView.builder.
                if (snapshot.hasData) {
                  // Convert the snapshot data into a List<UserModel>.
                  final List<UserModel> listOfUser = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: listOfUser.length,
                    itemBuilder: (context, index) {
                      // Retrieve each user's data from UserModel.
                      final user = listOfUser[index];
                      return ListTile(
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
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: CachedNetworkImage(
                            fit: BoxFit.fitHeight,
                            width: 46,
                            height: 46,
                            imageUrl: user.imageUrl,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        title: Text(user.name),
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
    );
  }
}
