// import 'package:encrypt/encrypt.dart';

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
  void generateRSAKeyPairAndEncode() async {
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

    var public = helper.encodePublicKeyToPemPKCS1(keyPair.publicKey as RSAPublicKey);

    ColoredPrint.warning(public);
  }

  //! Step 2: Method That return the RSA Key's (Private and Public)
  Future<({String? rsaPublicKey, String? rsaPrivateKey})> returnRSAKeys() async {
    // First we read the Key from flutter secure storage if key are already genrated then we do not genrate them again
    final String? rsaPrivateKey = await _storage.read(key: 'private_key');
    final String? rsaPublicKey = await _storage.read(key: 'public_key');

    return (rsaPublicKey: rsaPublicKey, rsaPrivateKey: rsaPrivateKey);
  }

  // Method that encryped the user message and write AES Key, IV to flutter secure storage and also return the AES Key, IV & Encrypted Message.
  Future<({String encryptedMessage, Key aesKey, IV iv, RSAPublicKey publicKey})> encryptMessage({required String message}) async {
    //! Step 3: AES Key & IV for Message Encryption
    final aesKey = Key.fromSecureRandom(32);
    final iv = IV.fromSecureRandom(16); // AES IV (128-bit)

    final encrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));

    // writing the AES key & IV for Message encryption to firebase secure storage.
    await _storage.write(key: 'AES_key', value: aesKey.toString());
    await _storage.write(key: 'IV', value: iv.toString());

    // reading the AES key & IV form firebase secure storage.
    final Key readedAesKey = await _storage.read(key: 'AES_key') as Key;
    final IV readedIV = await _storage.read(key: 'IV') as IV;
    final RSAPublicKey readedpublicKey = await _storage.read(key: 'public_key') as RSAPublicKey;

    // encrypting the user message
    final encryptedMsg = encrypter.encrypt(message, iv: iv);

    return (encryptedMessage: encryptedMsg.base64, aesKey: readedAesKey, iv: readedIV, publicKey: readedpublicKey);
  }

  //! Step 4: Encrypt AES Key and IV using RSA (for sending them securely)
  String rsaEncrypt(Uint8List data, RSAPublicKey publicKey) {
    final encryptor = Encrypter(RSA(publicKey: publicKey));
    final encryptedData = encryptor.encryptBytes(data);
    return encryptedData.base64;
  }
}
