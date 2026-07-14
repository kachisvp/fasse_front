import 'package:flutter/material.dart';

import '../../shared/widgets/primary_menu_button.dart';
import 'auth_session.dart';

/// AccessKeyが未設定、またはAccessKeyでのJWT取得に失敗した場合に表示するログイン画面。
/// docs/spec/purchase-sales-frontend/design.md「認証」参照。
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              const Text(
                'ログインが必要です',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (authSession.errorMessage != null) ...[
                Text(
                  authSession.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              PrimaryMenuButton(
                label: 'Cognitoでログイン',
                onPressed: () => authSession.loginWithCognito(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
