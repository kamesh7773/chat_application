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

  //! Step 1: Generate RSA Key Pair (public/private)
  AsymmetricKeyPair<PublicKey, PrivateKey> generateRSAKeyPair() {
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

    final keyGenerator = RSAKeyGenerator()..init(ParametersWithRandom(keyParams, secureRandom));

    return keyGenerator.generateKeyPair();
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

  //! Step 3: AES Encryption for Message
  final encrypter = Encrypter(AES(Key.fromSecureRandom(32), mode: AESMode.cbc));
  final iv = IV.fromSecureRandom(16); // AES IV (128-bit)

  String encryptMessage(String message) {
    final encrypted = encrypter.encrypt(message, iv: iv);
    return encrypted.base64;
  }

  //! Step 4: Encrypt AES Key and IV using RSA (for sending them securely)
  String rsaEncrypt(Uint8List data, RSAPublicKey publicKey) {
    final encryptor = Encrypter(RSA(publicKey: publicKey));
    final encryptedData = encryptor.encryptBytes(data);
    return encryptedData.base64;
  }
}
