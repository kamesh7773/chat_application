import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/firebase_auth_methods.dart';
import '../../services/firebase_firestore_methods.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFireStoreMethods _firebaseFireStoreMethods = FirebaseFireStoreMethods();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
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
                          "Profile",
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
            StreamBuilder<List<UserModel>>(
              stream: _firebaseFireStoreMethods.fetchingCurrentUserDetails(),
              builder: (context, snapshot) {
                // If snapshot is still loading then show CircularProgressIndicator.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }

                // If snapshot has error then show error message.
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }

                if (snapshot.hasData) {
                  // Here we are converting the snapshot data into List<UserModel>.
                  final List<UserModel> user = snapshot.data!;
                  return Column(
                    children: [
                      const SizedBox(height: 40),
                      //! Profile Image
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color.fromARGB(255, 0, 191, 108),
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: CachedNetworkImage(
                                  fit: BoxFit.fitHeight,
                                  width: 100,
                                  height: 100,
                                  imageUrl: user.first.imageUrl,
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 3,
                            right: 1,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.green, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.green,
                                size: 21,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      //! Name Widget
                      Text(
                        user.first.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 12),
                      //! Edit Profile Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color.fromARGB(255, 0, 191, 108),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(135, 36),
                        ),
                        onPressed: () {},
                        child: const Text(
                          "Edit Profile",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Divider(
                          thickness: 0.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      //! User ID Line
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "User ID",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              user.first.userID.substring(0, 8),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      //! E-mail ID Line
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "E-mail ID",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              user.first.email,
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      //! Location Line
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Location",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "India,Rajasthan",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      //! Provider Line
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Provider",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              user.first.provider,
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Divider(
                          thickness: 0.5,
                        ),
                      ),
                      const SizedBox(height: 90),
                      //! Logout Button.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            const Text(
                              "Joined",
                              style: TextStyle(
                                color: Color.fromARGB(255, 107, 105, 105),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "04 March 2024",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(flex: 1),
                            ElevatedButton(
                              onPressed: () {
                                FirebaseAuthMethods.singOut(context: context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: const Color.fromARGB(255, 0, 191, 108),
                                backgroundColor: const Color.fromARGB(255, 225, 247, 237),
                                minimumSize: const Size(80, 36),
                              ),
                              child: const Text(
                                "Logout",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  );
                }
                // else condiation
                else {
                  return const Center(
                    child: Text("Else Condition"),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
