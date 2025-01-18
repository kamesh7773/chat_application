// import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MessageEncrptionService {
  // Generate a 256-bit AES key and a random IV
  final key = Key.fromSecureRandom(32); // 32 bytes = 256 bits
  final iv = IV.fromSecureRandom(16); // 16 bytes = 128 bits

  final storage = const FlutterSecureStorage();

  Future<({Key storedKey, IV storedIV})> retrivingEncryptedKeys() async {
    // Retrieve AES key and IV
    final Key storedKey = Key.fromBase64(await storage.read(key: 'aesKey') ?? "");
    final IV storedIV = IV.fromBase64(await storage.read(key: 'aesIV') ?? "");

    return (storedKey: storedKey, storedIV: storedIV);
  }

  // This Method return the Encrypter Key and IV.
  Future<String> encryptingMessage({required message}) async {
    // Save AES key and IV
    await storage.write(key: 'aesKey', value: key.base64);
    await storage.write(key: 'aesIV', value: iv.base64);

    final encryptedData = await retrivingEncryptedKeys();

    final encrypter = Encrypter(AES(encryptedData.storedKey, mode: AESMode.cbc));

    final encryptedMessage = encrypter.encrypt(message, iv: encryptedData.storedIV).base64;

    return encryptedMessage;
  }

  // This Method Decrypt the Message.
  String decryptingMessage({required String encryptedMessage, required Key key, required IV iv}) {
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    // Decrypt the message
    final decryptedMessage = encrypter.decrypt64(encryptedMessage, iv: iv);
    return decryptedMessage;
  }
}
