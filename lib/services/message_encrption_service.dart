import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:pointycastle/export.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;

class MessageEncrptionService {
  // Creating an instance of FlutterSecureStorage to securely store keys
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  //! Method to generate an RSA key pair (public/private)
  Future<void> generateKeys() async {
    // Future to hold our KeyPair
    Future<crypto.AsymmetricKeyPair> futureKeyPair;
    // To store the KeyPair once we get data from our future
    crypto.AsymmetricKeyPair keyPair;

    // Helper class for RSA key operations
    var helper = RsaKeyHelper();

    // Function to generate RSA key pair
    Future<crypto.AsymmetricKeyPair<crypto.PublicKey, crypto.PrivateKey>> getKeyPair() {
      return helper.computeRSAKeyPair(helper.getSecureRandom());
    }

    // Generate the key pair
    futureKeyPair = getKeyPair();
    keyPair = await futureKeyPair;

    // Encode the RSA keys to PEM format
    final publicRSAKey = helper.encodePublicKeyToPemPKCS1(keyPair.publicKey as RSAPublicKey);
    final privateRSAKey = helper.encodePrivateKeyToPemPKCS1(keyPair.privateKey as RSAPrivateKey);

    // Generate AES key and IV for message encryption
    final aesKey = Key.fromSecureRandom(32); // 256-bit AES key
    final iv = IV.fromSecureRandom(16); // 128-bit AES IV

    // Writing the RSA public & private keys to Flutter Secure Storage
    await _storage.write(key: 'private_Key', value: privateRSAKey);
    await _storage.write(key: 'public_key', value: publicRSAKey);

    // Writing the AES key & IV to Flutter Secure Storage by encoding them into base64
    await _storage.write(key: 'AES_key', value: base64Encode(aesKey.bytes));
    await _storage.write(key: 'IV', value: base64Encode(iv.bytes));
  }

  //! Method to return the RSA keys (private and public), AES key & IV stored in Flutter Secure Storage
  Future<({String? rsaPublicKey, String? rsaPrivateKey, String? aesKey, String? iv})> returnKeys() async {
    // Reading RSA public and private keys from Flutter Secure Storage. If keys are already generated, we do not generate them again.
    final String? rsaPrivateKey = await _storage.read(key: 'private_Key');
    final String? rsaPublicKey = await _storage.read(key: 'public_key');

    // Reading AES key & IV from Flutter Secure Storage. If keys are already generated, we do not generate them again.
    final String? aesKey = await _storage.read(key: 'AES_key');
    final String? iv = await _storage.read(key: 'IV');

    // Return the keys and IV
    return (rsaPublicKey: rsaPublicKey, rsaPrivateKey: rsaPrivateKey, aesKey: aesKey, iv: iv);
  }

  //! Method to encrypt AES key and IV using the RSA public key of the recipient user (USER B)
  String rsaEncrypt({required Uint8List data, required RSAPublicKey publicKey}) {
    // Create an RSA encrypter with the recipient's public key
    final encryptor = Encrypter(RSA(publicKey: publicKey));
    // Encrypt the data and return it as a base64 string
    final encryptedData = encryptor.encryptBytes(data);
    return encryptedData.base64;
  }

  //! Encrypt a private key using a custom string (sub-property)
  Future encryptPrivateKey() async {
    // Reading the private key from Flutter Secure Storage
    const String privateKey = "hello";
    const String customString = "105155588538589755904";

    List<int> textBytes = privateKey.codeUnits;
    List<int> keyBytes = customString.codeUnits;
    List<int> result = [];

    for (int i = 0; i < textBytes.length; i++) {
      result.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    // wrting the encrypted private key to Flutter Secure Storage
    await _storage.write(key: 'encrypted_private_key', value: base64.encode(result));

  }

//! Decrypt the private key using the same custom string (sub-property)
  Future<void> decryptPrivateKey() async {
    // Reading the encrypted private key from Flutter Secure Storage
    final String? encryptedPrivateKey = await _storage.read(key: 'encrypted_private_key');
    const String customString = "105155588538589755904";

    List<int> textBytes = encryptedPrivateKey!.codeUnits;
    List<int> keyBytes = customString.codeUnits;
    List<int> result = [];

    for (int i = 0; i < textBytes.length; i++) {
      result.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

  }

  //! Method to decrypt AES key and IV using our own RSA private key
  Uint8List rsaDecrypt({required String data, required RSAPrivateKey privateKey}) {
    // Create an RSA decrypter with our private key
    final decryptor = Encrypter(RSA(privateKey: privateKey));
    // Decrypt the data and return it as a Uint8List
    final List<int> decryptedBytes = decryptor.decryptBytes(Encrypted.fromBase64(data));
    return Uint8List.fromList(decryptedBytes); // Convert List<int> to Uint8List
  }

  //! Method to encrypt the user message, write AES key, IV to Flutter Secure Storage, and return the AES key, IV & encrypted message
  Future<({String encryptedMessage, Key aesKey, IV iv})> encryptMessage({required String message}) async {
    try {
      // Reading AES key & IV from Flutter Secure Storage. If keys are already generated, we do not generate them again.
      final String? stringAESKey = await _storage.read(key: 'AES_key');
      final String? stringIV = await _storage.read(key: 'IV');

      // Converting AES key & IV from String data type to their original state because Flutter Secure Storage stores the data in the String data type.
      final Key aesKey = Key(base64Decode(stringAESKey!));
      final IV iv = IV(base64Decode(stringIV!));

      // Create an AES encrypter with the key and IV
      final encrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));

      // Encrypt the message
      final encryptedMsg = encrypter.encrypt(message, iv: iv);

      // Return the encrypted message, AES key, and IV
      return (encryptedMessage: encryptedMsg.base64, aesKey: aesKey, iv: iv);
    } catch (e) {
      throw e.toString();
    }
  }

  //! Method to decrypt the message
  Future<String> mesageDecrypation({required String currentUserID, required String senderID, required String encryptedAESKey, required String encryptedIV, required String encryptedMessage}) async {
    // Reading the RSA private key from Flutter Secure Storage
    final pemPrivateKey = await _storage.read(key: 'private_Key');
    final currentUserAESKey = await _storage.read(key: 'AES_key');
    final currentUserIV = await _storage.read(key: 'IV');

    // Converting AES key & IV from String data type to their original state because Flutter Secure Storage stores the data in the String data type.
    final Key currentUserDecryptedAESKey = Key(base64Decode(currentUserAESKey!));
    final IV currentUserDecryptedIV = IV(base64Decode(currentUserIV!));

    // Convert the encrypted message String to an Encrypted object
    final Encrypted encryptedData = Encrypted.fromBase64(encryptedMessage);

    // If senderID of message model is current userID, then we do not need the private key because we can use the AES key and IV stored in
    // Flutter Secure Storage and just use the AES key and IV to decrypt our message.
    if (senderID == currentUserID) {
      final encrypterd = Encrypter(AES(currentUserDecryptedAESKey, mode: AESMode.cbc));
      final decryptedMsg = encrypterd.decrypt(encryptedData, iv: currentUserDecryptedIV);

      return decryptedMsg;
    }
    // Else if senderID is not equal to current userID, it means that the message is sent by User A to User B. Now User B uses their RSA private key to decrypt the
    // AES key and IV of User A that is encrypted by the User B public key. Now User B can decrypt the AES key and IV easily.
    else {
      // Parse the RSA private key from PEM format
      RsaKeyHelper helper = RsaKeyHelper();
      final privateKey = helper.parsePrivateKeyFromPem(pemPrivateKey);

      // Decrypt the AES key and IV using the recipient's private key
      final Uint8List decryptedAESKeyBytes = rsaDecrypt(data: encryptedAESKey, privateKey: privateKey);
      final Uint8List decryptedIVBytes = rsaDecrypt(data: encryptedIV, privateKey: privateKey);

      // Converting AES key & IV from String data type to their original state because Flutter Secure Storage stores the data in the String data type.
      final Key recipientUserDecryptedAESKey = Key(decryptedAESKeyBytes);
      final IV recipientUserDecryptedIV = IV(decryptedIVBytes);

      // Decrypt the message
      final encrypterd = Encrypter(AES(recipientUserDecryptedAESKey, mode: AESMode.cbc));
      final decryptedMsg = encrypterd.decrypt(encryptedData, iv: recipientUserDecryptedIV);

      return decryptedMsg;
    }
  }

  //! Method for understaning the encryption and decryption process
  Future<({String encryptedMessage, Key aesKey, IV iv})> encryptionDecryption({required String message, required String recipientPublicKey, required String recipientPrivateKey}) async {
    try {
      // Reading AES key & IV from Flutter Secure Storage. If keys are already generated, we do not generate them again.
      final String? stringAESKey = await _storage.read(key: 'AES_key');
      final String? stringIV = await _storage.read(key: 'IV');

      // Converting AES key & IV from String data type to their original state because Flutter Secure Storage stores the data in the String data type.
      final Key aesKey = Key(base64Decode(stringAESKey!));
      final IV iv = IV(base64Decode(stringIV!));

      // Create an AES encrypter with the key and IV
      final encrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));

      // Encrypt the message
      final encryptedMsg = encrypter.encrypt(message, iv: iv);

      // Converting PEM RSA private and public key to original state so they can be used for encryption
      RsaKeyHelper helper = RsaKeyHelper();
      final RSAPublicKey publicKey = helper.parsePublicKeyFromPem(recipientPublicKey);
      final RSAPrivateKey privateKey = helper.parsePrivateKeyFromPem(recipientPrivateKey);

      // Encrypt the AES key and IV with the recipient's public key
      final encryptedAESKey = rsaEncrypt(data: aesKey.bytes, publicKey: publicKey);
      final encryptedIV = rsaEncrypt(data: iv.bytes, publicKey: publicKey);

      //* ----------------- Decryption Part -----------------  */

      // Decrypt the AES key and IV using the recipient's private key
      final Uint8List decryptedAESKeyBytes = rsaDecrypt(data: encryptedAESKey, privateKey: privateKey);
      final Uint8List decryptedIVBytes = rsaDecrypt(data: encryptedIV, privateKey: privateKey);

      // Wrap the decrypted bytes into Key and IV objects
      final Key decryptedAESKey = Key(decryptedAESKeyBytes);
      final IV decryptedIV = IV(decryptedIVBytes);

      // Decrypt the message
      final encrypterd = Encrypter(AES(decryptedAESKey, mode: AESMode.cbc));
      final decryptedMsg = encrypterd.decrypt(encryptedMsg, iv: decryptedIV);

      // Print the decrypted message for debugging

      // Return the encrypted message, AES key, and IV
      return (encryptedMessage: encryptedMsg.base64, aesKey: aesKey, iv: iv);
    } catch (e) {
      throw e.toString();
    }
  }
}
