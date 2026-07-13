import 'package:flutter/material.dart';

/// Home / MasterMaintenance 画面などで使う、縦に並べて配置する主要機能選択ボタン。
class PrimaryMenuButton extends StatelessWidget {
  const PrimaryMenuButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 18)),
        child: Text(label),
      ),
    );
  }
}
