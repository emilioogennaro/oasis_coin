import 'dart:convert';
import 'package:crypto/crypto.dart';

String sha512(String data) {
  return sha256.convert(utf8.encode(data)).toString();
}
