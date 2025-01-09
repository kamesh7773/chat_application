import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class InternetChecker {
  static late List<ConnectivityResult> connectivityResult;

  // Future method for checking internet connectivity
  static Future<bool> checkInternet() async {
    connectivityResult = await (Connectivity().checkConnectivity());
    // If there is no internet, return "true"
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return true;
    // If an internet connection is present, return "false"
    } else {
      return false;
    }
  }
}
