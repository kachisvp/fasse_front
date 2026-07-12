import 'package:flutter/material.dart';

class MasterMaintenancePage extends StatelessWidget {
  const MasterMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マスタメンテナンス'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 16),
              _buildSubButton(context, label: '品目', routeName: '/items'),
              const SizedBox(height: 16),
              _buildSubButton(context, label: '仕入先', routeName: '/suppliers'),
              const SizedBox(height: 16),
              _buildSubButton(context, label: 'メニュー', routeName: '/menus'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubButton(BuildContext context,
      {required String label, required String routeName}) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pushNamed(routeName);
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
