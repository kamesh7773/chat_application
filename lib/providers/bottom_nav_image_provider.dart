import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BottomNavImageProvider extends ChangeNotifier {
  // for initial imageUrl we are providing some dummy image URL for removing the CachedNetworkImage package error.
  String imageUrl = "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_640.png";

  Future<void> fetchProfileImage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    imageUrl = prefs.getString('imageUrl') ?? "false";
    notifyListeners();
  }
}
