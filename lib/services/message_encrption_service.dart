import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;

class MessageEncrptionService {
  // creating the instance of FlutterSecureStorage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  //! Method that Generates RSA Key Pair (public/private)
  Future<void> generateRSAKeyPairAndEncode() async {
    //Future to hold our KeyPair
    Future<crypto.AsymmetricKeyPair> futureKeyPair;
    //to store the KeyPair once we get data from our future
    crypto.AsymmetricKeyPair keyPair;

    var helper = RsaKeyHelper();

    Future<crypto.AsymmetricKeyPair<crypto.PublicKey, crypto.PrivateKey>> getKeyPair() {
      return helper.computeRSAKeyPair(helper.getSecureRandom());
    }

    futureKeyPair = getKeyPair();
    keyPair = await futureKeyPair;

    final publicRSAKey = helper.encodePublicKeyToPemPKCS1(keyPair.publicKey as RSAPublicKey);
    final privateRSAKey = helper.encodePrivateKeyToPemPKCS1(keyPair.privateKey as RSAPrivateKey);

    // writing the RSA Public & Private key's to firebase secure storage.
    await _storage.write(key: 'private_Key', value: privateRSAKey);
    await _storage.write(key: 'public_key', value: publicRSAKey);
  }

  //! Method That return the RSA Key's (Private and Public) that is stored in flutter secure storage.
  Future<({String? rsaPublicKey, String? rsaPrivateKey})> returnRSAKeys() async {
    // First we read the Key from flutter secure storage if key are already genrated then we do not genrate them again
    final String? rsaPrivateKey = await _storage.read(key: 'private_Key');
    final String? rsaPublicKey = await _storage.read(key: 'public_key');

    return (rsaPublicKey: rsaPublicKey, rsaPrivateKey: rsaPrivateKey);
  }

  //! Method that encryped the user message and write AES Key, IV to flutter secure storage and also return the AES Key, IV & Encrypted Message.
  Future<({String encryptedMessage, Key aesKey, IV iv})> encryptMessage({required String message}) async {
    //! Step 3: AES Key & IV for Message Encryption
    final aesKey = Key.fromSecureRandom(32);
    final iv = IV.fromSecureRandom(16); // AES IV (128-bit)

    final encrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));

    // encrypting the user message
    final encryptedMsg = encrypter.encrypt(message, iv: iv);

    return (encryptedMessage: encryptedMsg.base64, aesKey: aesKey, iv: iv);
  }

  //! Method Encrypt AES Key and IV using RSA Public key of the recipient user (USER B)
  String rsaEncrypt(Uint8List data, RSAPublicKey publicKey) {
    final encryptor = Encrypter(RSA(publicKey: publicKey));
    final encryptedData = encryptor.encryptBytes(data);
    return encryptedData.base64;
  }

  //! Method that decrypted the
  Future<({Uint8List decryptedKey, Uint8List decryptedIV})> decryptAESKey(String encryptedAESKey, String encryptedIV) async {
    final privateKey = await _storage.read(key: 'private_Key');

    final decryptor = Encrypter(RSA(privateKey: privateKey as RSAPrivateKey));
    final decryptedKeyBytes = decryptor.decryptBytes(Encrypted.fromBase64(encryptedAESKey));
    final decryptedIVBytes = decryptor.decryptBytes(Encrypted.fromBase64(encryptedIV));
    return (decryptedKey: decryptedKeyBytes as Uint8List, decryptedIV: decryptedIVBytes as Uint8List);
  }

// Step 7: Decrypt the Message using AES (Receiver Side)
  String decryptMessage(String encryptedMessage, Key decryptedAESKey, IV decryptedIV) {
    final encrypter = Encrypter(AES(decryptedAESKey, mode: AESMode.cbc));
    final decrypted = encrypter.decrypt(Encrypted.fromBase64(encryptedMessage), iv: decryptedIV);
    return decrypted;
  }
}
