import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:secure_pad/core/encryption_service.dart';

void main() {
  test('Encrypts and decrypts note correctly', () async {
    final key = SecretKey(List<int>.filled(32, 1));
    final service = EncryptionService(key);
    const plaintext = 'My secret note';
    final encrypted = await service.encrypt(plaintext);
    final decrypted = await service.decrypt(encrypted);
    expect(decrypted, plaintext);
  });
}
