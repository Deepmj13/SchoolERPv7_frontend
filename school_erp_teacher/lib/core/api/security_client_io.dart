import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client? createSecureClient() {
  final pin = String.fromEnvironment('CERT_PIN');
  if (pin.isEmpty) return null;

  final inner = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      final digest = sha256.convert(cert.der);
      final computedPin = base64.encode(digest.bytes);
      return computedPin == pin;
    };

  return IOClient(inner);
}
