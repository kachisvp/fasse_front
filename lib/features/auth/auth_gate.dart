import 'package:flutter/material.dart';

import 'auth_session.dart';
import 'login_screen.dart';

/// アプリ起動時のJWT取得判定を行い、状態に応じて[child]・[LoginScreen]・ローディング表示を切り替える。
/// docs/spec/purchase-sales-frontend/design.md「認証」の起動時フロー参照。
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    authSession.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authSession,
      builder: (context, _) {
        switch (authSession.status) {
          case AuthStatus.loading:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case AuthStatus.needsLogin:
            return const LoginScreen();
          case AuthStatus.authenticated:
            return widget.child;
        }
      },
    );
  }
}
