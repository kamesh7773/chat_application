import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

List<UserModel> userModelFromJson(String str) => List<UserModel>.from(json.decode(str).map((x) => UserModel.fromJson(x)));

String userModelToJson(List<UserModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class UserModel {
  String name;
  String email;
  String imageUrl;
  bool isOnline;
  Timestamp lastSeen;
  bool isTyping;
  bool isInsideChatRoom;
  List<UnSeenMessage>? unSeenMessages;
  String provider;
  String userID;

  UserModel({
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.isOnline,
    required this.lastSeen,
    required this.isTyping,
    required this.isInsideChatRoom,
    this.unSeenMessages,
    required this.provider,
    required this.userID,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        name: json["name"] ?? '',
        email: json["email"] ?? '',
        imageUrl: json["imageUrl"] ?? '',
        isOnline: json["isOnline"] ?? false,
        lastSeen: json["lastSeen"] ?? Timestamp.now(),
        isTyping: json["isTyping"] ?? false,
        isInsideChatRoom: json["isInsideChatRoom"] ?? false,
        unSeenMessages: json["unSeenMessages"] == null ? null : List<UnSeenMessage>.from(json["unSeenMessages"].map((x) => UnSeenMessage.fromJson(x))),
        provider: json["provider"] ?? '',
        userID: json["userID"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "email": email,
        "imageUrl": imageUrl,
        "isOnline": isOnline,
        "lastSeen": lastSeen,
        "isTyping": isTyping,
        "isInsideChatRoom": isInsideChatRoom,
        "unSeenMessages": unSeenMessages == null ? null : List<dynamic>.from(unSeenMessages!.map((x) => x.toJson())),
        "provider": provider,
        "userID": userID,
      };
}

class UnSeenMessage {
  String msg;
  Timestamp timeStamp;
  String senderId;
  String reciverId;

  UnSeenMessage({
    required this.msg,
    required this.timeStamp,
    required this.senderId,
    required this.reciverId,
  });

  factory UnSeenMessage.fromJson(Map<String, dynamic> json) => UnSeenMessage(
        msg: json["msg"] ?? '',
        timeStamp: json["timeStamp"] ?? Timestamp.now(),
        senderId: json["senderID"] ?? '',
        reciverId: json["reciverId"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "msg": msg,
        "timeStamp": timeStamp,
        "senderID": senderId,
        "reciverId": reciverId,
      };
}
