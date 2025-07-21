import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class EncryptedPayload {
  final String ciphertext;
  final String nonce;
  final String mac;
  EncryptedPayload(
      {required this.ciphertext, required this.nonce, required this.mac});
}

class EncryptionService {
  final SecretKey secretKey;
  final Cipher cipher = AesGcm.with256bits();

  EncryptionService(this.secretKey);

  Future<EncryptedPayload> encrypt(String plaintext) async {
    final nonce = cipher.newNonce();
    final secretBox = await cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    return EncryptedPayload(
      ciphertext: base64Encode(secretBox.cipherText),
      nonce: base64Encode(secretBox.nonce),
      mac: base64Encode(secretBox.mac.bytes),
    );
  }

  Future<String> decrypt(EncryptedPayload payload) async {
    try {
      final macBytes = base64Decode(payload.mac);
      if (macBytes.isEmpty || macBytes.length != 16) {
        throw Exception(
            'Invalid MAC: expected 16 bytes, got \\${macBytes.length}');
      }
      final secretBox = SecretBox(
        base64Decode(payload.ciphertext),
        nonce: base64Decode(payload.nonce),
        mac: Mac(macBytes),
      );
      final cleartext = await cipher.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return utf8.decode(cleartext);
    } catch (e) {
      print(e);
      throw Exception('Decryption failed: $e');
    }
  }
}
