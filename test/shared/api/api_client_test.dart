import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fasse_front/features/auth/auth_session.dart';
import 'package:fasse_front/shared/api/api_client.dart';
import 'package:fasse_front/shared/api/api_exception.dart';

/// JWTと401時の再取得結果を制御できる[AuthSession]のテスト用実装。
class FakeAuthSession extends Fake implements AuthSession {
  FakeAuthSession({this.jwt, this.recover = false});

  final String? jwt;
  final bool recover;
  int handleUnauthorizedCount = 0;

  @override
  Future<String?> currentJwt() async => jwt;

  @override
  Future<bool> handleUnauthorized() async {
    handleUnauthorizedCount++;
    return recover;
  }
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8080');
  });

  group('認証無効モード', () {
    test('Authorizationヘッダーを付与しない', () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('[]', 200);
        }),
        authDisabled: true,
        session: FakeAuthSession(jwt: 'jwt'),
      );

      await client.get('/items');

      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('401は再取得を行わずApiExceptionとして送出する', () async {
      final session = FakeAuthSession(jwt: 'jwt', recover: true);
      var requestCount = 0;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          requestCount++;
          return http.Response('{"message":"Unauthorized"}', 401);
        }),
        authDisabled: true,
        session: session,
      );

      await expectLater(
        client.get('/items'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
      expect(session.handleUnauthorizedCount, 0);
      expect(requestCount, 1);
    });
  });

  group('認証有効モード', () {
    test('AuthorizationヘッダーにJWTを付与する', () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('[]', 200);
        }),
        authDisabled: false,
        session: FakeAuthSession(jwt: 'jwt'),
      );

      await client.get('/items');

      expect(requests.single.headers['Authorization'], 'Bearer jwt');
    });

    test('401時は再取得に成功すれば1回だけリトライする', () async {
      final session = FakeAuthSession(jwt: 'jwt', recover: true);
      var requestCount = 0;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          requestCount++;
          return requestCount == 1 ? http.Response('', 401) : http.Response('[]', 200);
        }),
        authDisabled: false,
        session: session,
      );

      await client.get('/items');

      expect(session.handleUnauthorizedCount, 1);
      expect(requestCount, 2);
    });
  });
}
