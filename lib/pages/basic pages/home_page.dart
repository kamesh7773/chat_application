import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/services/encryption_decryption.dart';
import 'package:chat_application/services/message_encrption_service.dart';
import 'package:colored_print/colored_print.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import '../../providers/last_message_provider.dart';
import '../../utils/date_time_calculator_for_users.dart';
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
  late final String currentUsername;

  void fetchingcurrentUsername() async {
    final UserModel currentUser = await FirebaseFireStoreMethods().fetchingCurrentUserDetail(userID: _auth.currentUser!.uid);
    currentUsername = currentUser.name;
  }

  @override
  void initState() {
    super.initState();
    fetchingcurrentUsername();
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
                        "Chats",
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        //! Navigate the user to the Search Page
                        Navigator.of(context).pushNamed(
                          RoutesNames.searchPage,
                          arguments: "Search",
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      ActionChip(
                        onPressed: () {
                          // MessageEncrptionService().encryptionDecryption(
                          //   message: "Hello 😎",
                          //   recipientPublicKey: "-----BEGIN RSA PUBLIC KEY-----MIIBCgKCAQEApngHVpwEeN5/m8fBK4VLz//u2Z/meZP4cYK6aZE58TvKRw4t7yrVpkTLYZbdKjIPPPDzkjVIniqiTv5iJXyPYgTLvIPiRMVwzJOwzquXZ95mBpQ6mETbW5mzrQ7GQ7eTenT90p+MTaKgQjTA/nM2aI7Q+051tZ2xWTQ+IW5L09dUtFE1Huda5qlRbPsPkGP8FxH/it84176m7rBu/U/Pe6PdSpRDzUAYvHJt1IyL5ebksiralz7j5MgXHnuNSBUUFZTUAZg8KzbuK6uKepvwTnQWr/gwn4Ul8w5eU8Iugecqf/ITq6ygbCKUK2xWsq6AHgt7GwVyjNoZmxY71bcvewIDAQAB-----END RSA PUBLIC KEY-----",
                          //   recipientPrivateKey:
                          //       "-----BEGIN RSA PRIVATE KEY-----MIIFogIBAAKCAQEApngHVpwEeN5/m8fBK4VLz//u2Z/meZP4cYK6aZE58TvKRw4t7yrVpkTLYZbdKjIPPPDzkjVIniqiTv5iJXyPYgTLvIPiRMVwzJOwzquXZ95mBpQ6mETbW5mzrQ7GQ7eTenT90p+MTaKgQjTA/nM2aI7Q+051tZ2xWTQ+IW5L09dUtFE1Huda5qlRbPsPkGP8FxH/it84176m7rBu/U/Pe6PdSpRDzUAYvHJt1IyL5ebksiralz7j5MgXHnuNSBUUFZTUAZg8KzbuK6uKepvwTnQWr/gwn4Ul8w5eU8Iugecqf/ITq6ygbCKUK2xWsq6AHgt7GwVyjNoZmxY71bcvewKCAQBNx5U+LWWVh/g9tCaYjA5xIBbcje6k7bNObhNlUdqt0Q7hBkoGDpCGwGv6q/+oQH2ILtjPfp/wbuEpYYhAFaP022LKMSDemxXqMDOTTO9QM8Sd3FJIZRvM/9LI0Ddo2nRI6jLSX4OxnoOci4OFIBXS4q/YS7+J3SVJFbTV7+/0CUw2rIcv+3tZUTWgukYO1iEdR+IT2fzbcn+QrjdKC28bgXracs8+jlph7uHveG2qoR+me1SIk7hZjW/DAL9QCyxOezz9lFBueDoB+nRB51gjp1b656lypBo32SXWrFon8L6gW4NYWmRETV0v6ARfQYgoOMu0W0OyCPPQbMAfRNEhAoIBAE3HlT4tZZWH+D20JpiMDnEgFtyN7qTts05uE2VR2q3RDuEGSgYOkIbAa/qr/6hAfYgu2M9+n/Bu4SlhiEAVo/TbYsoxIN6bFeowM5NM71AzxJ3cUkhlG8z/0sjQN2jadEjqMtJfg7Geg5yLg4UgFdLir9hLv4ndJUkVtNXv7/QJTDashy/7e1lRNaC6Rg7WIR1H4hPZ/Ntyf5CuN0oLbxuBetpyzz6OWmHu4e94baqhH6Z7VIiTuFmNb8MAv1ALLE57PP2UUG54OgH6dEHnWCOnVvrnqXKkGjfZJdasWifwvqBbg1haZERNXS/oBF9BiCg4y7RbQ7II89BswB9E0SECgYEA8KVvtOYn0NdBvl3ZaxDHnlrqE9dkhZ9v2XpyB3dgSyeOgU8TTbjlMosxbwjJLuej+JC5+VV9m0ZqMpxIKh9z2wu9uEKtHyV7jIjLuCAYIcuAdxin5rrgSRBG425xX4K9x6o8fWcimzJCHJpw8iagWnkIYKPubF9bwd7H/PN6PksCgYEAsRcGo2wqqkQAtcekvemtEgVZpQaJwEIi8+sP1F0KGe+jX094BLCyEoIA6jXCkWDSjLFp1QKECXIzgwHkLfBekl7xfU2owf05W7+2oO7YoTLoB+AGo9jgYX0U7ql4oUfBOH05Fpc5dscku6RNB016uhMxTYluwaViAK1HCvmBVZECgYAk68z6vUEomo4crft4oMdvtVUqnCZxFegsPswV9yvP/A6yKja0+wQ3QAHinj93sdSHg3T1Gze9Rg1vHGk6BT9aQS/ngFtdZvvQsQBIjKwHK1jXbPH9xXg53YRyynQcikuhwa2sM9GsbAaWqt9fV6vMlbtCUIR5HhxO32Zhmd2MhwKBgBsq0yPjBjCUuh8o/4b7AEgRdg0xEZTjEIWm/AiyNUiBUOjgQiNGECtysj07/htbZTGcTgYVmrfwQyLH+X9qrrd5xUZZ0ZfhBxmiMZxCyA0CyEHdBmfAb7vE+p8adJ0ZavUFkOp8TJ6CMopuzDpgkoFVTGz+tnUSsBQ2gP2YBVVhAoGBAIX6hrHrPgeadLr1GMb/wgZvY7IbnloUC+tukA/cLjCO5S1mZyQ2fxVa2S2kvrrO+xPgBUzvBXQKP5gPqRrWbwhMAHCB7+NyBm10fujmXuSBZLIGzfaFzYzyLBVZxSrDF1g19WMavH6NnD6NUXa9tCXsmG+64N0Wg5O/b/HYwdJM-----END RSA PRIVATE KEY-----",
                          // );

                          EncryptionDecryption().encryptandDecryptPrivateKey(customString: "customString", message: "hello");
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        shadowColor: Colors.black,
                        elevation: 3,
                        label: const Text(
                          "Recent message",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: ActionChip(
                          onPressed: () {
                            //! Navigate the user to the Active Users Page.
                            Navigator.of(context).pushNamed(RoutesNames.activeUserPage);
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          label: const Text(
                            "Active",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: const Color.fromARGB(255, 0, 191, 108),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          //! User Chat List
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

                // If the snapshot has an error, display the error message.
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }

                // If the snapshot has data, display the ListView.builder.
                if (snapshot.hasData) {
                  // Convert the snapshot data into a List<UserModel>.
                  final List<UserModel> listofUser = snapshot.data!;

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: listofUser.length,
                    itemBuilder: (context, index) {
                      // Retrieve each user's data from UserModel.
                      final user = listofUser[index];

                      // This method is called for every user, passing their userID.
                      context.read<LastMessageProvider>().fetchLastMsg(otherUserID: user.userID);

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
                        leading: Stack(
                          children: [
                            user.provider == "Email & Password"
                                ? CircleAvatar(
                                    backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 0, 191, 108) : const Color.fromARGB(255, 45, 67, 83),
                                    radius: 25,
                                    child: Text(
                                      user.name.substring(0, 1),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : ClipRRect(
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
                            //! If the user is online, display a green dot.
                            user.isOnline
                                ? Positioned(
                                    bottom: 1.5,
                                    right: 1.5,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 0, 191, 108),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  )
                                // Otherwise, display a SizedBox().
                                : const SizedBox(),
                          ],
                        ),
                        title: Text(
                          user.name,
                          maxLines: 1,
                        ),
                        //! If the UnseenMessage List is empty, show the last message in the subtitle as normal text; otherwise, show it in bold text.
                        subtitle: user.unSeenMessages!.isEmpty
                            ? Selector<LastMessageProvider, String>(
                                // Fetch the last message of the other user ID from the map we created, storing the last message with the key name of their User ID for easy retrieval.
                                selector: (context, provider) => provider.getLastMsg(user.userID),
                                builder: (context, value, child) {
                                  return Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                  );
                                },
                              )
                            : Selector<LastMessageProvider, String>(
                                // Fetch the last message of the other user ID from the map we created, storing the last message with the key name of their User ID for easy retrieval.
                                selector: (context, provider) => provider.getLastMsg(user.userID),
                                builder: (context, value, child) {
                                  return Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  );
                                },
                              ),
                        //! If the UnseenMessage List is empty, then...
                        trailing: user.unSeenMessages!.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  DateTimeCalculatorForUsers.getLastActiveTime(lastSeen: user.lastSeen.toDate(), isOnline: user.isOnline),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 216, 204, 204),
                                  ),
                                ),
                              )
                            //! If UnseenMessage contains messages, then...
                            : user.unSeenMessages!.last.reciverId == _auth.currentUser!.uid
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 80),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          DateTimeCalculatorForUnseenmsg.getLastActiveTime(lastSeen: user.unSeenMessages!.last.timeStamp.toDate()),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color.fromARGB(255, 0, 191, 108),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 0),
                                            child: Text(
                                              user.unSeenMessages!.length.toString(),
                                              style: const TextStyle(
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
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color.fromARGB(255, 116, 114, 114),
                                      ),
                                    ),
                                  ),
                      );
                    },
                  );
                }

                // Default case if no data is available
                else {
                  return const Center(
                    child: Text("No data available."),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 0, 191, 108),
        onPressed: () {},
        child: const Icon(
          Icons.person_add_alt_1,
          color: Colors.white,
        ),
      ),
    );
  }
}
