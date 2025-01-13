import 'package:chat_application/providers/last_message_provider.dart';
import 'package:chat_application/providers/zego_avatar_provider.dart';
import 'package:chat_application/services/zego_methods.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  /// 1/5: define a navigator key
  final navigatorKey = GlobalKey<NavigatorState>();

  /// 2/5: set navigator key to ZegoUIKitPrebuiltCallInvitationService
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  ZegoUIKit().initLog().then((value) {
    ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
      [ZegoUIKitSignalingPlugin()],
    );

    runApp(MyApp(
      navigatorKey: navigatorKey,
      isUserAuthenticated: isUserAuthenticated,
    ));
  });
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final bool isUserAuthenticated;
  const MyApp({
    super.key,
    required this.isUserAuthenticated,
    required this.navigatorKey,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (widget.isUserAuthenticated) {
      ZegoMethods.onUserLogin();
    }
  }

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
        ChangeNotifierProvider(
          create: (context) => ZegoAvatarProvider(),
        ),
      ],
      child: MaterialApp(
        /// 3/5: register the navigator key to MaterialApp
        navigatorKey: widget.navigatorKey,

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
        initialRoute: widget.isUserAuthenticated ? RoutesNames.bottomNavigationBar : RoutesNames.signInPage,
      ),
    );
  }
}
