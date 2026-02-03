import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String buildSimulatedPassword(String email) {
  final normalized = email.trim().toLowerCase();
  final secret = dotenv.env['AUTH_PASSWORD_SECRET']?.trim();
  final seed = '$normalized::${secret?.isNotEmpty == true ? secret : 'dev-secret'}';
  return sha256.convert(utf8.encode(seed)).toString();
}
