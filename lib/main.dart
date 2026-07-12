import 'package:flutter/material.dart';

import 'features/home/home_page.dart';
import 'features/master/master_page.dart';
import 'features/items/items_page.dart';
import 'features/suppliers/suppliers_page.dart';
import 'features/menus/menus_page.dart';
import 'features/purchases/purchases_page.dart';
import 'features/sales/sales_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fasse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/master': (context) => const MasterMaintenancePage(),
        '/items': (context) => const ItemsPage(),
        '/suppliers': (context) => const SuppliersPage(),
        '/menus': (context) => const MenusPage(),
        '/purchases': (context) => const PurchasesPage(),
        '/sales': (context) => const SalesPage(),
      },
    );
  }
}
