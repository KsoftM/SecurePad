import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';

class CloudKeyService {
  final FirebaseFirestore firestore;
  CloudKeyService(this.firestore);

  // Derive a key from passphrase using PBKDF2
  Future<List<int>> deriveKey(String passphrase, String salt,
      {int iterations = 100000, int length = 32}) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: length * 8,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: utf8.encode(salt),
    );
    return await secretKey.extractBytes();
  }

  // Encrypt the user's encryption key with the derived key
  Future<String> encryptKey(List<int> key, List<int> derivedKey) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(derivedKey);
    final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    final encrypted = await algorithm.encrypt(
      key,
      secretKey: secretKey,
      nonce: nonce,
    );
    return base64Encode(nonce + encrypted.cipherText + encrypted.mac.bytes);
  }

  // Decrypt the user's encryption key with the derived key
  Future<List<int>> decryptKey(String encrypted, List<int> derivedKey) async {
    final data = base64Decode(encrypted);
    final nonce = data.sublist(0, 12);
    final cipherText = data.sublist(12, data.length - 16);
    final mac = Mac(data.sublist(data.length - 16));
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(derivedKey);
    final secret = await algorithm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: secretKey,
    );
    return secret;
  }

  // Store encrypted key in Firestore
  Future<void> storeEncryptedKey(
      String userId, String encryptedKey, String salt) async {
    await firestore.collection('users').doc(userId).set({
      'encryptedKey': encryptedKey,
      'salt': salt,
    }, SetOptions(merge: true));
  }

  // Retrieve encrypted key and salt from Firestore
  Future<Map<String, String>?> getEncryptedKey(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!.containsKey('encryptedKey')) {
      return {
        'encryptedKey': doc['encryptedKey'],
        'salt': doc['salt'],
      };
    }
    return null;
  }
}
