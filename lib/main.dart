import 'package:chat_application/providers/last_message_provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'providers/bottom_nav_image_provider.dart';
import 'providers/online_offline_status_provider.dart';
import 'providers/typing_status_provider.dart';
import 'services/firebase_auth_methods.dart';
import 'services/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:provider/provider.dart';

import 'routes/rotues_names.dart';
import 'routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// 1.1.2: set navigator key to ZegoUIKitPrebuiltCallInvitationService
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  // Initialize Facebook sign-in/sign-up for Flutter web apps only.
  if (kIsWeb) {
    await FacebookAuth.i.webAndDesktopInitialize(
      appId: "1518795865449666",
      cookie: true,
      xfbml: true,
      version: "v13.0",
    );
  }

  // Check if the user is already logged in.
  bool isUserAuthenticated = await FirebaseAuthMethods.isUserLogin();

  // call the useSystemCallingUI
  ZegoUIKit().initLog().then((value) {
    ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
      [ZegoUIKitSignalingPlugin()],
    );

    runApp(
      MyApp(
        navigatorKey: navigatorKey,
        isUserAuthenticated: isUserAuthenticated,
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  final GlobalKey navigatorKey;
  final bool isUserAuthenticated;
  const MyApp({
    super.key,
    required this.isUserAuthenticated,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => TypingStatusProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => OnlineOfflineStatusProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => BottomNavImageProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => LastMessageProvider(),
        ),
      ],
      child: MaterialApp(
        key: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Chat Application',
        theme: ThemeData(
          //! defining Lato fonts Globally.
          textTheme: GoogleFonts.latoTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 0, 191, 108),
          ),
          useMaterial3: true,
        ),
        onGenerateRoute: Routes.generateRoute,
        initialRoute: isUserAuthenticated ? RoutesNames.bottomNavigationBar : RoutesNames.signInPage,
      ),
    );
  }
}
