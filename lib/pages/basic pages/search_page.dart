import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/models/user_model.dart';
import 'package:chat_application/routes/rotues_names.dart';
import 'package:chat_application/services/firebase_firestore_methods.dart';
import 'package:colored_print/colored_print.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final String heading;
  const SearchPage({super.key, required this.heading});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // varible declartion
  String searchName = "";
  final FirebaseFireStoreMethods _firebaseFireStoreMethods = FirebaseFireStoreMethods();

  // Border Style
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
                          //! Navigate user to Home Page.
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
              stream: _firebaseFireStoreMethods.serachingUserBasedOnName(keyword: searchName),
              builder: (context, snapshot) {
                // If snapshot is still loading then show CircularProgressIndicator.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // If snapshot has error then show error message.
                if (snapshot.hasError) {
                  ColoredPrint.warning(snapshot.error.toString());
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

                // else condiation
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
