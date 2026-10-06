import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';
import '../../shared/api/api_exception.dart';
import '../../shared/logging/app_logger.dart';
import 'auth_repository.dart';
import 'jwt_store.dart';

enum AuthStatus { loading, authenticated, needsLogin }

/// アプリ全体の認証状態を管理する。
/// 起動時のJWT取得判定・401時の再取得/ログイン誘導を`ApiClient`と`AuthGate`から共有するため、
/// `appLogger`と同様にトップレベルの単一インスタンス（[authSession]）として扱う。
/// フロー詳細は docs/spec/purchase-sales-frontend/design.md「認証」参照。
class AuthSession extends ChangeNotifier {
  AuthSession({AuthRepository? repository, JwtStore? jwtStore, bool? authDisabled})
    : _repository = repository ?? AuthRepository(),
      _jwtStore = jwtStore ?? JwtStore(),
      authDisabled = authDisabled ?? AppConfig.authDisabled;

  final AuthRepository _repository;
  final JwtStore _jwtStore;

  /// 認証無効モード（ローカルAPIサーバー接続用）かどうか。
  final bool authDisabled;

  AuthStatus status = AuthStatus.loading;
  String? errorMessage;

  /// アプリ起動時のJWT取得フロー。
  /// 0. 認証無効モードであれば、JWTを取得せずにアプリ本体を表示する
  /// 1. SecureStorageに有効なJWTがあれば再利用
  /// 2. `.env`のAccessKeyがあればルートAへ自動送信
  /// 3. いずれも無い/失敗した場合はログイン画面（Cognito誘導）を表示する
  Future<void> bootstrap() async {
    if (authDisabled) {
      appLogger.w('認証無効モード（DISABLE_AUTH）で起動しました。APIリクエストに認証情報を付与しません');
      status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }

    status = AuthStatus.loading;
    notifyListeners();

    final storedJwt = await _jwtStore.readValid();
    if (storedJwt != null) {
      status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }

    try {
      final jwt = await _repository.issueTokenByAccessKey();
      if (jwt != null) {
        await _jwtStore.save(jwt);
        status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
    } catch (e) {
      appLogger.i('AccessKeyでのJWT取得に失敗したため、Cognitoログインへフォールバックします: $e');
    }

    status = AuthStatus.needsLogin;
    notifyListeners();
  }

  /// ログイン画面の「Cognitoでログイン」ボタンから呼び出す。
  Future<void> loginWithCognito() async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final jwt = await _repository.loginWithCognito();
      await _jwtStore.save(jwt);
      status = AuthStatus.authenticated;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : 'ログインに失敗しました';
      status = AuthStatus.needsLogin;
    }
    notifyListeners();
  }

  /// `ApiClient`が401を受信した際に呼び出す。
  /// AccessKeyが利用可能であれば自動的に再取得し、リクエストのリトライを許可する。
  /// 失敗する場合、またはAccessKeyが無い場合はJWTを破棄し、ログイン画面へ遷移させる。
  /// 認証無効モードでは状態を変更せず`false`を返す（ログイン画面へ遷移させない）。
  Future<bool> handleUnauthorized() async {
    if (authDisabled) return false;
    try {
      final jwt = await _repository.issueTokenByAccessKey();
      if (jwt != null) {
        await _jwtStore.save(jwt);
        return true;
      }
    } catch (e) {
      appLogger.w('AccessKeyでの再取得に失敗しました: $e');
    }

    await _jwtStore.clear();
    status = AuthStatus.needsLogin;
    notifyListeners();
    return false;
  }

  /// `ApiClient`がAuthorizationヘッダーへ付与するJWTを取得する。
  Future<String?> currentJwt() => _jwtStore.readValid();
}

final AuthSession authSession = AuthSession();
