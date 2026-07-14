import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// fasse_infraが発行したJWTの保存・有効性チェックを行う。
class JwtStore {
  JwtStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'fasse_jwt';

  final FlutterSecureStorage _storage;

  Future<void> save(String jwt) => _storage.write(key: _key, value: jwt);

  Future<String?> read() => _storage.read(key: _key);

  Future<void> clear() => _storage.delete(key: _key);

  /// 保存済みのJWTのうち、有効期限内（`exp`未経過）のものを返す。期限切れの場合は破棄してnullを返す。
  Future<String?> readValid() async {
    final jwt = await read();
    if (jwt == null) return null;
    if (isExpired(jwt)) {
      await clear();
      return null;
    }
    return jwt;
  }

  /// JWTのペイロード（`exp`）をデコードして有効期限切れかどうかを判定する。
  /// 署名検証はバックエンド側の責務であり、ここではクライアント側の再利用可否のみを判断する。
  static bool isExpired(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return true;
    try {
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
              as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! int) return true;
      return DateTime.now().millisecondsSinceEpoch >= exp * 1000;
    } catch (_) {
      return true;
    }
  }
}
