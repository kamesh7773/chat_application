import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pointycastle/asymmetric/api.dart';

class MessageModel {
  final String senderID;
  final String reciverID;
  final String message;
  final String encryptedAESKey;
  final String encryptedIV;
  final RSAPublicKey myPublicKey;
  final bool isSeen;
  final Timestamp timestamp;

  MessageModel({
    required this.senderID,
    required this.reciverID,
    required this.message,
    required this.encryptedAESKey,
    required this.encryptedIV,
    required this.myPublicKey,
    required this.isSeen,
    required this.timestamp,
  });

  // Convert to a Map
  Map<String, dynamic> toMap() {
    return {
      "senderID": senderID,
      "reciverID": reciverID,
      "message": message,
      "encryptedAESKey": encryptedAESKey,
      "encryptedIV": encryptedIV,
      "isSeen": isSeen,
      "timestamp": timestamp,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        senderID: json["senderID"],
        reciverID: json["reciverID"],
        message: json["message"],
        encryptedAESKey: json["encryptedAESKey"],
        encryptedIV: json["encryptedIV"],
        myPublicKey: json["myPublicKey"],
        isSeen: json["isSeen"],
        timestamp: json["timestamp"],
      );

  Map<String, dynamic> toJson() => {
        "senderID": senderID,
        "reciverID": reciverID,
        "message": message,
        "encryptedAESKey": encryptedAESKey,
        "encryptedIV": encryptedIV,
        "myPublicKey": myPublicKey,
        "isSeen": isSeen,
        "timestamp": timestamp,
      };
}
