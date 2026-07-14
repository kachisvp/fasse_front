import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Cognito Hosted UI（Authorization Code Grant）向けのPKCEペア。
/// docs/spec/purchase-sales-frontend/design.md「PKCE」参照。
class PkcePair {
  PkcePair({required this.codeVerifier, required this.codeChallenge});

  final String codeVerifier;
  final String codeChallenge;

  /// `code_verifier`: 暗号学的乱数から生成する43〜128文字のランダム文字列。
  /// `code_challenge`: `code_verifier`をSHA-256でハッシュ化しBase64URLエンコードした値（S256）。
  factory PkcePair.generate() {
    final codeVerifier = _randomUrlSafeString(32);
    final digest = sha256.convert(ascii.encode(codeVerifier));
    final codeChallenge = base64UrlEncode(digest.bytes).replaceAll('=', '');
    return PkcePair(codeVerifier: codeVerifier, codeChallenge: codeChallenge);
  }
}

/// CSRF対策の`state`パラメータ用ランダム文字列を生成する。
String generateOAuthState() => _randomUrlSafeString(16);

String _randomUrlSafeString(int byteLength) {
  final random = Random.secure();
  final bytes = Uint8List.fromList(List.generate(byteLength, (_) => random.nextInt(256)));
  return base64UrlEncode(bytes).replaceAll('=', '');
}
