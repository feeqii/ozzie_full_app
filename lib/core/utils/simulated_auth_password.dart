import 'dart:convert';

import 'package:crypto/crypto.dart';

String buildSimulatedPassword(String email) {
  final normalized = email.trim().toLowerCase();
  final secret = const String.fromEnvironment('AUTH_PASSWORD_SECRET', defaultValue: 'dev-secret').trim();
  final seed = '$normalized::$secret';
  return sha256.convert(utf8.encode(seed)).toString();
}
