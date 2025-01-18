import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MessageEncrptionService {
  static Future<({Key storedKey, IV storedIV})> genratingEncrption() async {
    // Generate a 256-bit AES key and a random IV
    final key = Key.fromSecureRandom(32); // 32 bytes = 256 bits
    final iv = IV.fromSecureRandom(16); // 16 bytes = 128 bits

    const storage = FlutterSecureStorage();

    // Save AES key and IV
    await storage.write(key: 'aesKey', value: key.base64);
    await storage.write(key: 'aesIV', value: iv.base64);

    // Retrieve AES key and IV
    final Key storedKey = Key.fromBase64(await storage.read(key: 'aesKey') ?? "");
    final IV storedIV = IV.fromBase64(await storage.read(key: 'aesIV') ?? "");

    return (storedIV: storedIV, storedKey: storedKey);
  }
}
