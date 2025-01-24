import 'dart:convert';
import 'dart:typed_data';

import 'package:colored_print/colored_print.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;

class MessageEncrptionService {
  // creating the instance of FlutterSecureStorage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  //! Method that Generates RSA Key Pair (public/private)
  Future<void> generateKeys() async {
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

    // Stroing RSA Public and Private key's to varibles
    final publicRSAKey = helper.encodePublicKeyToPemPKCS1(keyPair.publicKey as RSAPublicKey);
    final privateRSAKey = helper.encodePrivateKeyToPemPKCS1(keyPair.privateKey as RSAPrivateKey);

    // creating AES Key and IV for message encryption
    final aesKey = Key.fromSecureRandom(32);
    final iv = IV.fromSecureRandom(16); // AES IV (128-bit)

    // writing the RSA Public & Private key's to firebase secure storage.
    await _storage.write(key: 'private_Key', value: privateRSAKey);
    await _storage.write(key: 'public_key', value: publicRSAKey);

    // writing the AES Key & IV to firebase secure storage by encoding them into base64Encode.
    await _storage.write(key: 'AES_key', value: base64Encode(aesKey.bytes));
    await _storage.write(key: 'IV', value: base64Encode(iv.bytes));
  }

  //! Method That return the RSA Key's (Private and Public), AES Key & IV  that is stored in flutter secure storage.
  Future<({String? rsaPublicKey, String? rsaPrivateKey, String? aesKey, String? iv})> returnKeys() async {
    // Reading RSA Public and Private Key's from flutter secure storage if key are already genrated then we do not genrate them again
    final String? rsaPrivateKey = await _storage.read(key: 'private_Key');
    final String? rsaPublicKey = await _storage.read(key: 'public_key');

    // Reading AES Key & IV from flutter secure storage if key are already genrated then we do not genrate them again
    final String? aesKey = await _storage.read(key: 'AES_key');
    final String? iv = await _storage.read(key: 'IV');

    return (rsaPublicKey: rsaPublicKey, rsaPrivateKey: rsaPrivateKey, aesKey: aesKey, iv: iv);
  }

  //! Method Encrypt AES Key and IV using RSA Public key of the recipient user (USER B)
  String rsaEncrypt({required Uint8List data, required RSAPublicKey publicKey}) {
    final encryptor = Encrypter(RSA(publicKey: publicKey));
    final encryptedData = encryptor.encryptBytes(data);
    return encryptedData.base64;
  }

  //! Method that encryped the user message and write AES Key, IV to flutter secure storage and also return the AES Key, IV & Encrypted Message.
  Future<({String encryptedMessage, Key aesKey, IV iv})> encryptMessage({required String message}) async {
    try {
      // Reading AES Key & IV from flutter secure storage if key are already genrated then we do not genrate them again
      final String? stringAESKey = await _storage.read(key: 'AES_key');
      final String? stringIV = await _storage.read(key: 'IV');

      // Converting AES Key & IV from String dataType to their orignal State because flutter secure storage store the data in the String data type.
      final Key aesKey = Key(base64Decode(stringAESKey!));
      final IV iv = IV(base64Decode(stringIV!));

      // crating Encrypter instance for encrption.
      final encrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));

      // encrypting the message.
      final encryptedMsg = encrypter.encrypt(message, iv: iv);

      // returning the encrypted Message and AES Key and IV that is used for Encrpting the meseage.
      return (encryptedMessage: encryptedMsg.base64, aesKey: aesKey, iv: iv);
    } catch (e) {
      throw e.toString();
    }
  }

  //! Method that Decrypt AES Key and IV using RSA Private key of Our Own key.
  dynamic decryptAESKey({required String data, required RSAPrivateKey privateKey}) {
    try {
      final decryptor = Encrypter(RSA(privateKey: privateKey));
      final decryptedKeyBytes = decryptor.decryptBytes(Encrypted.fromBase64(data));
      return decryptedKeyBytes;
    } catch (e) {
      ColoredPrint.warning(e);
      throw e.toString();
    }
  }

  //! Method that decrypted the
  Future<void> mesageDecrypation({required String senderID, required String encryptedAESKey, required String encryptedIV, required String message}) async {
    // reading the RSA Private Key from flutter secure storage.
    final pemPrivateKey = await _storage.read(key: 'private_Key');

    // Parse the RSA private key directly from PEM format
    RsaKeyHelper helper = RsaKeyHelper();
    final privateKey = helper.parsePrivateKeyFromPem(pemPrivateKey);

    // Decrypt the AES key
    final Key aesKey = decryptAESKey(data: encryptedAESKey, privateKey: privateKey);

    // Decrypt the IV
    final iv = decryptAESKey(data: encryptedIV, privateKey: privateKey);

    ColoredPrint.warning(aesKey.runtimeType);
    ColoredPrint.warning(iv.runtimeType);
  }
}
