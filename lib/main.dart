import 'services/notification_service.dart';

import 'providers/last_message_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/zego_avatar_provider.dart';
import 'services/zego_methods.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'providers/bottom_nav_image_provider.dart';
import 'providers/online_offline_status_provider.dart';
import 'providers/typing_status_provider.dart';
import 'services/firebase_auth_methods.dart';
import 'services/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'routes/rotues_names.dart';
import 'routes/routes.dart';
import 'package:flutter/material.dart';

/// 1/5: Define a navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Here we intilize the flutter Awesome Notifications.
  AwesomeNotificationsAPI().initlization();

  // Check if the user is already logged in.
  bool isUserAuthenticated = await FirebaseAuthMethods.isUserLogin();

  /// 2/5: Set the navigator key for ZegoUIKitPrebuiltCallInvitationService
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
        ChangeNotifierProvider(
          create: (context) => ThemeProvider("System"),
        ),
      ],
      child: Selector<ThemeProvider, ThemeData>(
        selector: (context, data) => data.themeData,
        builder: (context, value, child) {
          return MaterialApp(
            /// 3/5: Register the navigator key with MaterialApp
            navigatorKey: widget.navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Chat Application',
            theme: value,
            onGenerateRoute: Routes.generateRoute,
            initialRoute: widget.isUserAuthenticated ? RoutesNames.bottomNavigationBar : RoutesNames.signInPage,
          );
        },
      ),
    );
  }
}
