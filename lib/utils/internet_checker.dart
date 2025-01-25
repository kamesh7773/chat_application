import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class InternetChecker {
  static late List<ConnectivityResult> connectivityResult;

  // Future method to check internet connectivity
  static Future<bool> checkInternet() async {
    connectivityResult = await (Connectivity().checkConnectivity());
    // Return "true" if there is no internet connection
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return true;
      // Return "false" if an internet connection is present
    } else {
      return false;
    }
  }
}
