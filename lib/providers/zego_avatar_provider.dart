import 'package:flutter/foundation.dart';

class ZegoAvatarProvider extends ChangeNotifier {
  String? imageUrl;

  void updateAvatarImageUrl({required String imageURL}) {
    imageUrl = imageURL;
    notifyListeners();
  }
}
