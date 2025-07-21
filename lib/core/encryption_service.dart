import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class EncryptedPayload {
  final String ciphertext;
  final String nonce;
  EncryptedPayload({required this.ciphertext, required this.nonce});
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
    );
  }

  Future<String> decrypt(EncryptedPayload payload) async {
    final secretBox = SecretBox(
      base64Decode(payload.ciphertext),
      nonce: base64Decode(payload.nonce),
      mac: Mac.empty,
    );
    final cleartext = await cipher.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return utf8.decode(cleartext);
  }
}
