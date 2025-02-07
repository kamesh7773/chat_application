import 'package:cached_network_image/cached_network_image.dart';
import '../../routes/rotues_names.dart';
import '../../widgets/send_call_button.dart';
import '../../models/user_model.dart';
import '../../services/firebase_firestore_methods.dart';
import '../../utils/date_time_calculator_for_unseenmsg.dart';
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
            //! Call Logs
            Expanded(
              child: StreamBuilder<UserModel>(
                stream: _firebaseFireStoreMethods.fetchingCurrentUserDetails(),
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
                    // Convert the snapshot data into a UserModel.
                    final UserModel currentUserData = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: currentUserData.callLogs!.length,
                      itemBuilder: (context, index) {
                        final user = currentUserData.callLogs![index];

                        if (currentUserData.callLogs == null) {
                          return const SizedBox();
                        } else {
                          return ListTile(
                            contentPadding: const EdgeInsets.only(top: 2, bottom: 10, left: 12, right: 10),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: CachedNetworkImage(
                                fit: BoxFit.fitHeight,
                                width: 55,
                                height: 55,
                                imageUrl: user.imageUrl,
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ),
                            title: Text(user.userName),
                            subtitle: Row(
                              children: [
                                user.isInComing
                                    ? const RotatedBox(
                                        quarterTurns: 50,
                                        child: Icon(
                                          Icons.arrow_outward_sharp,
                                          color: Colors.red,
                                          size: 22,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.arrow_outward_sharp,
                                        color: Color.fromARGB(255, 0, 191, 108),
                                        size: 22,
                                      ),
                                const SizedBox(width: 8),
                                Text(
                                  DateTimeCalculatorForUnseenmsg.getLastActiveTime(lastSeen: user.timeStamp.toDate()),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 104, 101, 101) : const Color.fromARGB(255, 160, 153, 153),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {},
                              icon: user.isVideoCall
                                  ? sendCallButton(
                                      isVideoCall: true,
                                      userId: user.userID,
                                      userName: user.userName,
                                      imageUrl: user.imageUrl,
                                      icon: const Icon(
                                        Icons.videocam_sharp,
                                        color: Color.fromARGB(255, 0, 191, 108),
                                        size: 28,
                                      ),
                                    )
                                  : sendCallButton(
                                      isVideoCall: false,
                                      userId: user.userID,
                                      userName: user.userName,
                                      imageUrl: user.imageUrl,
                                      icon: const Icon(
                                        Icons.call,
                                        color: Color.fromARGB(255, 0, 191, 108),
                                        size: 26,
                                      ),
                                    ),
                            ),
                          );
                        }
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
