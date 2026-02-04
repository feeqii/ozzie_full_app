import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PinHash {
  const PinHash._();

  static String generateSalt([int length = 16]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt$pin');
    final digest = sha256.convert(bytes);
    return '$salt\$${digest.toString()}';
  }

  static bool verifyPin(String pin, String storedHash) {
    final parts = storedHash.split(r'$');
    if (parts.length != 2) {
      return false;
    }
    final salt = parts[0];
    final digest = parts[1];
    final recomputed = sha256.convert(utf8.encode('$salt$pin')).toString();
    return digest == recomputed;
  }
}
