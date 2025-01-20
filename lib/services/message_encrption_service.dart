// import 'package:encrypt/encrypt.dart';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';

import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';

class MessageEncrptionService {
  // creating the instance of FlutterSecureStorage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  //! Method that Generates RSA Key Pair (public/private)
  Future generateRSAKeyPair() async {
    // First we read the Key from flutter secure storage if key are already genrated then we do not genrate them again
    final String? rsaPrivateKey = await _storage.read(key: 'private_key');
    final String? rsaPublicKey = await _storage.read(key: 'public_key');

    if (rsaPrivateKey == null && rsaPublicKey == null) {
      final secureRandom = FortunaRandom();
      final random = Random.secure();
      final seeds = Uint8List(32);
      for (int i = 0; i < seeds.length; i++) {
        seeds[i] = random.nextInt(256);
      }
      secureRandom.seed(KeyParameter(seeds));

      final keyParams = RSAKeyGeneratorParameters(
        BigInt.from(65537), // Public exponent
        2048, // Key size (2048 bits)
        12, // Certainty
      );

      RSAKeyGenerator().init(ParametersWithRandom(keyParams, secureRandom));

      // Store RSA Key pair Securely (Private and Public) to flutter secure storage.
      String privateKeyString = privateKey.toString();
      String publicKeyString = publicKey.toString();
    }
  }

  //! Step 2: Store RSA Keys Securely (Private and Public)
  Future<void> storeKeys(RSAPrivateKey privateKey, RSAPublicKey publicKey) async {
    // Convert keys to PEM or Base64 string for storage
    String privateKeyString = privateKey.toString();
    String publicKeyString = publicKey.toString();

    // Store the private key securely on the device
    await _storage.write(key: 'private_key', value: privateKeyString);
    // Store the public key (can be shared securely)
    await _storage.write(key: 'public_key', value: publicKeyString);
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
