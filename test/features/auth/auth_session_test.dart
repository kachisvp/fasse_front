import 'package:flutter_test/flutter_test.dart';

import 'package:fasse_front/features/auth/auth_repository.dart';
import 'package:fasse_front/features/auth/auth_session.dart';
import 'package:fasse_front/features/auth/jwt_store.dart';

/// 呼び出し回数と戻り値を制御できる[JwtStore]のテスト用実装。
class FakeJwtStore extends Fake implements JwtStore {
  FakeJwtStore({this.validJwt});

  String? validJwt;
  int readValidCount = 0;
  int clearCount = 0;
  final List<String> saved = [];

  @override
  Future<String?> readValid() async {
    readValidCount++;
    return validJwt;
  }

  @override
  Future<void> save(String jwt) async => saved.add(jwt);

  @override
  Future<void> clear() async {
    clearCount++;
    validJwt = null;
  }
}

/// AccessKeyでのJWT取得結果を制御できる[AuthRepository]のテスト用実装。
class FakeAuthRepository extends Fake implements AuthRepository {
  FakeAuthRepository({this.accessKeyJwt});

  String? accessKeyJwt;
  int issueCount = 0;

  @override
  Future<String?> issueTokenByAccessKey() async {
    issueCount++;
    return accessKeyJwt;
  }
}

void main() {
  group('認証無効モード', () {
    test('bootstrapでJWTを取得せずに即authenticatedとなる', () async {
      final store = FakeJwtStore();
      final repository = FakeAuthRepository(accessKeyJwt: 'jwt');
      final session = AuthSession(repository: repository, jwtStore: store, authDisabled: true);

      await session.bootstrap();

      expect(session.status, AuthStatus.authenticated);
      expect(store.readValidCount, 0);
      expect(repository.issueCount, 0);
    });

    test('handleUnauthorizedはfalseを返し、ログイン画面へ遷移させない', () async {
      final store = FakeJwtStore();
      final repository = FakeAuthRepository(accessKeyJwt: 'jwt');
      final session = AuthSession(repository: repository, jwtStore: store, authDisabled: true);
      await session.bootstrap();

      final recovered = await session.handleUnauthorized();

      expect(recovered, isFalse);
      expect(session.status, AuthStatus.authenticated);
      expect(repository.issueCount, 0);
      expect(store.clearCount, 0);
    });
  });

  group('認証有効モード', () {
    test('保存済みの有効なJWTがあれば再利用する', () async {
      final store = FakeJwtStore(validJwt: 'stored');
      final repository = FakeAuthRepository();
      final session = AuthSession(repository: repository, jwtStore: store, authDisabled: false);

      await session.bootstrap();

      expect(session.status, AuthStatus.authenticated);
      expect(repository.issueCount, 0);
    });

    test('保存済みJWTが無くAccessKeyで取得できれば保存してauthenticatedとなる', () async {
      final store = FakeJwtStore();
      final repository = FakeAuthRepository(accessKeyJwt: 'issued');
      final session = AuthSession(repository: repository, jwtStore: store, authDisabled: false);

      await session.bootstrap();

      expect(session.status, AuthStatus.authenticated);
      expect(store.saved, ['issued']);
    });

    test('保存済みJWTもAccessKeyも無ければneedsLoginとなる', () async {
      final session = AuthSession(
        repository: FakeAuthRepository(),
        jwtStore: FakeJwtStore(),
        authDisabled: false,
      );

      await session.bootstrap();

      expect(session.status, AuthStatus.needsLogin);
    });

    test('handleUnauthorizedでAccessKeyが無ければJWTを破棄してneedsLoginとなる', () async {
      final store = FakeJwtStore(validJwt: 'stored');
      final session = AuthSession(
        repository: FakeAuthRepository(),
        jwtStore: store,
        authDisabled: false,
      );
      await session.bootstrap();

      final recovered = await session.handleUnauthorized();

      expect(recovered, isFalse);
      expect(store.clearCount, 1);
      expect(session.status, AuthStatus.needsLogin);
    });
  });
}
