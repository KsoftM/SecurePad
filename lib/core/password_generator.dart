import 'dart:math';

class PasswordGenerator {
  static String generate(
      {int length = 16,
      bool numbers = true,
      bool uppercase = true,
      bool lowercase = true,
      bool symbols = true}) {
    const String numChars = '0123456789';
    const String upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowerChars = 'abcdefghijklmnopqrstuvwxyz';
    const String symbolChars = '!@#\$%^&*()-_=+[]{}|;:,.<>?';
    String chars = '';
    if (numbers) chars += numChars;
    if (uppercase) chars += upperChars;
    if (lowercase) chars += lowerChars;
    if (symbols) chars += symbolChars;
    if (chars.isEmpty) chars = numChars + upperChars + lowerChars + symbolChars;
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
