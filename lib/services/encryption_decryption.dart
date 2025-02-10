// ignore_for_file: unused_local_variable

import 'package:colored_print/colored_print.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';

class EncryptionDecryption {
  // Creating an instance of FlutterSecureStorage to securely store keys
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Method that retive the RSA Private Keyl, AES Key and IV from flutter secure storage and return it
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

  // Method that encrypt the RSA Private Key, AES Key and IV using the custom string
  Future<({String encryptedRSAPrivateKEY, String encryptedAESData, String encrptedIV})> encryptionWithCustomString({
    required String customString,
  }) async {
    // retriving the key's form returnKeys() method.
    final keys = await returnKeys();

    final pemRsaPrivateKey = keys.rsaPrivateKey;
    final pemAesKey = keys.aesKey;
    final pemIV = keys.iv;

    // Derive encryption key directly from the custom string
    final keyBytes = sha256.convert(utf8.encode(customString)).bytes;
    final key = Key(Uint8List.fromList(keyBytes));

    // Create an encrypter (No IV involved)
    final encrypter = Encrypter(AES(key, mode: AESMode.ecb));

    // Encrypt the private key, AES Key and IV
    final encryptedKey = encrypter.encrypt(pemRsaPrivateKey!);
    final encryptedAES = encrypter.encrypt(pemAesKey!);
    final encryptediv = encrypter.encrypt(pemIV!);

    final encryptedPrivateKey = encryptedKey.base64; // Return encrypted private key as a base64 string
    final encryptedAESKey = encryptedAES.base64; // Return encrypted AES key as a base64 string
    final encryptedIV = encryptediv.base64; // Return encrypted IV as a base64 string

    return (encryptedRSAPrivateKEY: encryptedPrivateKey, encryptedAESData: encryptedAESKey, encrptedIV: encryptedIV);
  }

  // Method that decrypt the the RSA Private Keyl, AES Key and IV using the custom string
  Future<({String decryptedRSAPrivateKey, String decryptedAESKEY, String decrypedIV})> decryptionWithCustomString({
    required String encryptedPrivateKey,
    required String encryptedAesKey,
    required String encryptediv,
    required String customString,
  }) async {
    // Derive decryption key directly from the custom string
    final keyBytes = sha256.convert(utf8.encode(customString)).bytes;
    final key = Key(Uint8List.fromList(keyBytes));

    // Create an encrypter (No IV involved)
    final encrypter = Encrypter(AES(key, mode: AESMode.ecb));

    // Decrypt the private key
    final encryptedKey = Encrypted.fromBase64(encryptedPrivateKey);
    final encryptedAESKey = Encrypted.fromBase64(encryptedAesKey);
    final encryptedIV = Encrypted.fromBase64(encryptediv);

    final decryptedPrivateKey = encrypter.decrypt(encryptedKey);
    final decryptedAES = encrypter.decrypt(encryptedAESKey);
    final decryptedIv = encrypter.decrypt(encryptedIV);

    return (decryptedRSAPrivateKey: decryptedPrivateKey, decryptedAESKEY: decryptedAES, decrypedIV: decryptedIv);
  }

  // Method that encrypt the message using AES Key and IV
  Future<Encrypted> encryptMessage({required String message, required String aESKey, required String iV}) async {
    try {
      // Converting AES key & IV from String data type to their original state.
      final Key aesKey = Key(base64Decode(aESKey));
      final IV iv = IV(base64Decode(iV));

      // Create an AES encrypter with the key and IV
      final encrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));

      // Encrypt the message
      final encryptedMsg = encrypter.encrypt(message, iv: iv);

      // Return the encrypted message, AES key, and IV
      return encryptedMsg;
    } catch (e) {
      throw e.toString();
    }
  }

  // Method for encrypting the AES Key and IV
  String rsaEncrypt({required Uint8List data, required RSAPublicKey publicKey}) {
    // Create an RSA encrypter with the recipient's public key
    final encryptor = Encrypter(RSA(publicKey: publicKey));
    // Encrypt the data and return it as a base64 string
    final encryptedData = encryptor.encryptBytes(data);
    return encryptedData.base64;
  }

  // Method for decrypting the AES Key and IV
  Uint8List rsaDecrypt({required String data, required RSAPrivateKey privateKey}) {
    // Create an RSA decrypter with our private key
    final decryptor = Encrypter(RSA(privateKey: privateKey));
    // Decrypt the data and return it as a Uint8List
    final List<int> decryptedBytes = decryptor.decryptBytes(Encrypted.fromBase64(data));
    return Uint8List.fromList(decryptedBytes); // Convert List<int> to Uint8List
  }

  // Method for decrypint the message with AES Key and IV
  Future<String> decryptMessage({required Encrypted encryptedMessage, required Uint8List decrtedAESKey, required Uint8List decrtediV}) async {
    try {
      // Converting AES key & IV from String data type to their original state.
      final Key recipientUserDecryptedAESKey = Key(decrtedAESKey);
      final IV recipientUserDecryptedIV = IV(decrtediV);

      final encrypterd = Encrypter(AES(recipientUserDecryptedAESKey, mode: AESMode.cbc));
      final decryptedMsg = encrypterd.decrypt(encryptedMessage, iv: recipientUserDecryptedIV);

      // Return the encrypted message, AES key, and IV
      return decryptedMsg;
    } catch (e) {
      throw e.toString();
    }
  }

  void messageEncryptionandDecryption({required message, required String customString}) async {
    //! 1st step we need to retive the RSA Private Key, AES Key and IV from the flutter secure storage.
    final keys = await returnKeys();
    final pemRsaPrivateKey = keys.rsaPrivateKey;
    final pemRsaPublicKey = keys.rsaPublicKey;
    final pemAesKey = keys.aesKey;
    final pemIv = keys.iv;

    //! 2nd step we need to encrypt RSA Private Key, AES Key and IV and store it at firebase database
    final encryptedData = await encryptionWithCustomString(customString: customString);

    final encryptedprivateKey = encryptedData.encryptedRSAPrivateKEY;
    final encryptedAES = encryptedData.encryptedAESData;
    final encryptedIV = encryptedData.encrptedIV;

    //! 3rd step we need to decrypt RSA Private Key, AES Key and IV
    final decryptedData = await decryptionWithCustomString(
      encryptedPrivateKey: encryptedprivateKey,
      encryptedAesKey: encryptedAES,
      encryptediv: encryptedIV,
      customString: customString,
    );

    final decryptedprivateKey = decryptedData.decryptedRSAPrivateKey;
    final decryptedAES = decryptedData.decryptedAESKEY;
    final decryptedIV = decryptedData.decrypedIV;

    //! 4th step we will encryt any kind of message using the AES Key and IV
    final Encrypted encryptMsg = await encryptMessage(message: message, aESKey: decryptedAES, iV: decryptedIV);

    //! 5th step we encrypt the AES and IV using the User B RSA Public Key
    // converting AES Key and IV to its orignal State.
    final Key aesKey = Key(base64Decode(decryptedAES));
    final IV iv = IV(base64Decode(decryptedIV));

    // Parse the recipient's RSA public key from PEM format.
    RsaKeyHelper helper = RsaKeyHelper();
    final RSAPublicKey publicKey = helper.parsePublicKeyFromPem(pemRsaPublicKey);

    // encrypting the AES Key and IV
    final encrtedAESKey = rsaEncrypt(data: aesKey.bytes, publicKey: publicKey);
    final encrtediV = rsaEncrypt(data: iv.bytes, publicKey: publicKey);

    //! 6th step we decrypt the AES and IV using the User B RSA Private Key
    final RSAPrivateKey privateKey = helper.parsePrivateKeyFromPem(pemRsaPrivateKey);

    // decrypting the AES Key and IV
    final Uint8List decrtedAESKey = rsaDecrypt(data: encrtedAESKey, privateKey: privateKey);
    final Uint8List decrtediV = rsaDecrypt(data: encrtediV, privateKey: privateKey);

    //! 7th decrpting the Messaage here
    final String decryptedMsg = await decryptMessage(encryptedMessage: encryptMsg, decrtedAESKey: decrtedAESKey, decrtediV: decrtediV);
    ColoredPrint.warning(encryptMsg);
    ColoredPrint.warning(decryptedMsg);
  }
}
