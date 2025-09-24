import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Fasse",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _message = "";
  List<Map<String, dynamic>> _dataList = [];
  List<DataColumn> _labels = [];
  List<DataRow> _values = [];

  // [m_food_composition]からデータを取得
  Future<String> _getFoodcompositions() async {
    var client = http.Client();

    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/foodcompositions"),
        headers: <String, String>{
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 4));

      // [HTTP Status 200]でなければエラーとする
      if (response.statusCode != 200) {
        throw Exception(response.statusCode.toString());
      }

      return response.body;
    } catch (e) {
      _message = e.toString();

      // WebAPIで取得できない場合、DummyDataを返す
      return _getDummyData();
    } finally {
      client.close();
    }
  }

  Future<String> _getDummyData() async {
    // FIXME "assets/foodcompositions.zip"を解凍してDummyDataを返す
    return '[{"foodNm": "こめ"}]';
  }

  // 画面を再描画
  void _reload() async {
    try {
      // 初期化
      _message = "";
      _labels = [];
      _values = [];

      String result = await _getFoodcompositions();
      _dataList = List<Map<String, dynamic>>.from(json.decode(result));

      _labels = List<DataColumn>.generate(
          7, (int index) => DataColumn(label: Text("$index")),
          growable: false);

      _values = List<DataRow>.generate(_dataList.length, (int index) {
        return DataRow(cells: [
          DataCell(Text(_dataList[index]["foodNm"])),
          DataCell(Text(_dataList[index]["enercKcal"].toString())),
          DataCell(Text(_dataList[index]["prot"].toString())),
          DataCell(Text(_dataList[index]["chole"].toString())),
          DataCell(Text(_dataList[index]["fat"].toString())),
          DataCell(Text(_dataList[index]["chocdf"].toString())),
          DataCell(Text(_dataList[index]["vitc"].toString())),
        ]);
      }, growable: false);
    } catch (e) {
      _message = e.toString();
    }
    // 画面を再描画
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Fasse"),
      ),
      body: Column(
        children: [
          SelectableText(_message),
          SizedBox(
            width: size.width,
            height: size.height - 80,
            child: (_dataList.isEmpty)
                ? const Text("")
                : ListView(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(columns: _labels, rows: _values),
                      )
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _reload,
        tooltip: "reload",
        child: const Icon(Icons.add),
      ),
    );
  }
}
