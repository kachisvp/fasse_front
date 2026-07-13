import 'package:flutter/material.dart';

import '../master_maintenance/master_maintenance_screen.dart';
import '../purchases/purchases_list_screen.dart';
import '../sales/sales_list_screen.dart';
import '../../shared/widgets/primary_menu_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fasse 仕入・売上管理')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              PrimaryMenuButton(
                label: '仕入伝票',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PurchasesListScreen()),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryMenuButton(
                label: '売上伝票',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SalesListScreen()),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryMenuButton(
                label: 'マスタメンテナンス',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MasterMaintenanceScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
