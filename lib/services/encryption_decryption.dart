import 'package:colored_print/colored_print.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
// Import necessary packages
import 'package:encrypt/encrypt.dart';
import 'dart:typed_data';

class EncryptionDecryption {
  void encryptandDecryptPrivateKey({required message, required String customString}) {
    //* -------------------Encrypt the private key ------------------- */

    // Derive encryption key directly from the custom string
    final keyBytes1 = sha256.convert(utf8.encode(customString)).bytes;
    final key1 = Key(Uint8List.fromList(keyBytes1));

    // Create an encrypter (No IV involved)
    final encrypter1 = Encrypter(AES(key1, mode: AESMode.ecb));

    // Encrypt the private key
    final encrypted = encrypter1.encrypt(message!);
    final encryptedPrivateKey = encrypted.base64; // Return encrypted private key as a base64 string

    ColoredPrint.warning(encryptedPrivateKey);

    //* --------------------- Decrypt the private key --------------------- */

    // Derive decryption key directly from the custom string
    final keyBytes2 = sha256.convert(utf8.encode(customString)).bytes;
    final key2 = Key(Uint8List.fromList(keyBytes2));

    // Create an encrypter (No IV involved)
    final encrypter2 = Encrypter(AES(key2, mode: AESMode.ecb));

    // Decrypt the private key
    final encrypted2 = Encrypted.fromBase64(encryptedPrivateKey);
    final decryptedPrivateKey = encrypter2.decrypt(encrypted2);

    ColoredPrint.warning(decryptedPrivateKey);
  }
}
