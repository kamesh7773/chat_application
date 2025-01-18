import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/bottom_nav_image_provider.dart';
import '../../services/firebase_firestore_methods.dart';
import 'package:provider/provider.dart';

import 'calls_page.dart';
import 'home_page.dart';
import 'people_page.dart';
import 'profile_page.dart';
import 'package:flutter/material.dart';

class BottomNavigationBarPage extends StatefulWidget {
  const BottomNavigationBarPage({super.key});

  @override
  State<BottomNavigationBarPage> createState() => _BottomNavigationBarPageState();
}

class _BottomNavigationBarPageState extends State<BottomNavigationBarPage> with WidgetsBindingObserver {
  // Variable declarations
  int _page = 0;
  String imageURL = "";
  FirebaseFireStoreMethods firebaseFireStoreMethods = FirebaseFireStoreMethods();

  // List of pages for the bottom navigation bar
  List<Widget> pages = [
    const HomePage(),
    const PeoplePage(),
    const CallsPage(),
    const ProfilePage(),
  ];

  // Method for changing the screen when the user taps on a bottom navigation icon
  void onPagedChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  //! Here we update the user's "isOnline" status when user get out or close the application.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Set user to online when app is in foreground
      firebaseFireStoreMethods.isOnlineStatus(
        isOnline: true,
        datetime: DateTime.now(),
      );
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.detached) {
      // Set user to offline for all background states
      firebaseFireStoreMethods.isOnlineStatus(
        isOnline: false,
        datetime: DateTime.now(),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<BottomNavImageProvider>().fetchProfileImage();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_page],
      bottomNavigationBar: Theme(
        data: ThemeData(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          applyElevationOverlayColor: true,
        ),
        child: BottomNavigationBar(
          backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.white : const Color.fromARGB(255, 29, 29, 53),
          selectedItemColor: const Color.fromARGB(255, 0, 191, 108),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          unselectedFontSize: 14.0,
          selectedFontSize: 14.0,
          type: BottomNavigationBarType.fixed,
          onTap: onPagedChanged,
          currentIndex: _page,
          items: [
            // Chats
            const BottomNavigationBarItem(
              icon: Icon(
                Icons.chat_bubble,
                size: 21,
              ),
              label: "Chats",
            ),
            // People
            const BottomNavigationBarItem(
              icon: Icon(
                Icons.people,
                size: 24,
              ),
              label: "People",
            ),
            // Calls
            const BottomNavigationBarItem(
              icon: Icon(
                Icons.call,
                size: 24,
              ),
              label: "Calls",
            ),
            // Profile
            BottomNavigationBarItem(
              icon: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Selector<BottomNavImageProvider, String>(
                    selector: (context, data) => data.imageUrl,
                    builder: (context, value, child) {
                      return CachedNetworkImage(
                        fit: BoxFit.fitHeight,
                        width: 28,
                        height: 28,
                        imageUrl: value,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      );
                    }),
              ),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
