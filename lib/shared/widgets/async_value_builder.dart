import 'package:flutter/material.dart';

import 'error_view.dart';

/// [Future] の読み込み中・エラー・成功状態をまとめて表示する共通ビルダー。
class AsyncValueBuilder<T> extends StatelessWidget {
  const AsyncValueBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.onRetry,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorView(message: snapshot.error.toString(), onRetry: onRetry);
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}
