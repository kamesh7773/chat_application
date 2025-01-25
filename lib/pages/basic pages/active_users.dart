import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/firebase_firestore_methods.dart';
import 'package:flutter/material.dart';

class ActiveUsers extends StatefulWidget {
  const ActiveUsers({super.key});

  @override
  State<ActiveUsers> createState() => _ActiveUsersState();
}

class _ActiveUsersState extends State<ActiveUsers> {
  final FirebaseFireStoreMethods _firebaseFireStoreMethods = FirebaseFireStoreMethods();

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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: IconButton(
                        onPressed: () {
                          //! Navigate the user to the previous screen.
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0),
                      child: Text(
                        "Active users",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          //! User Chat List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firebaseFireStoreMethods.fetchingOnlineUsers(),
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

                if (snapshot.hasData) {
                  // Convert the snapshot data into a List<UserModel>.
                  final List<UserModel> listofUser = snapshot.data!;

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: listofUser.length,
                    itemBuilder: (context, index) {
                      // Retrieve each user's data from UserModel.
                      final user = listofUser[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
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
                              //! If the user is online, display the indicator
                              Positioned(
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
                              ),
                            ],
                          ),
                          title: const Text("Kamesh Singh"),
                          subtitle: const Text(
                            "(239) 555-0108",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
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
                    child: Text("No active users available."),
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
