import 'package:flutter/material.dart';

import '../items/items_list_screen.dart';
import '../menus/menus_list_screen.dart';
import '../suppliers/suppliers_list_screen.dart';
import '../tax_rates/tax_rates_list_screen.dart';
import '../../shared/widgets/primary_menu_button.dart';

class MasterMaintenanceScreen extends StatelessWidget {
  const MasterMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('マスタメンテナンス')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              PrimaryMenuButton(
                label: '品目',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ItemsListScreen()),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryMenuButton(
                label: '仕入先',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SuppliersListScreen()),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryMenuButton(
                label: 'メニュー',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MenusListScreen()),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryMenuButton(
                label: '消費税率',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TaxRatesListScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
