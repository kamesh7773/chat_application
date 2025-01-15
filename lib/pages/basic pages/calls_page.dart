import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_application/models/user_model.dart';
import 'package:chat_application/services/firebase_firestore_methods.dart';
import 'package:colored_print/colored_print.dart';
import 'package:flutter/material.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
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
            child: const Column(
              children: [
                SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Calls",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
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
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // If snapshot has error then show error message.
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }

                if (snapshot.hasData) {
                  // Here we are converting the snapshot data into List<UserModel>.
                  final List<UserModel> listofUser = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: listofUser.length,
                    itemBuilder: (context, index) {
                      final user = listofUser[index];

                      if (user.callLogs == null) {
                        ColoredPrint.warning("true");
                        return const SizedBox();
                      } else {
                        return ListTile(
                          contentPadding: const EdgeInsets.only(top: 2, bottom: 10, left: 12, right: 10),
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
                              //! If User online then
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
                          subtitle: const Row(
                            children: [
                              Icon(
                                Icons.arrow_outward_sharp,
                                color: Color.fromARGB(255, 0, 191, 108),
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "3m ago",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 116, 114, 114),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.videocam_sharp,
                              color: Color.fromARGB(255, 0, 191, 108),
                              size: 26,
                            ),
                          ),
                        );
                      }
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
