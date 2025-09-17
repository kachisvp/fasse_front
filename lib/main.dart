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
  List<Map<String, dynamic>> _userList = [];

  // [m_user]からデータを取得
  Future<String> _getUsers() async {
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
      return "";
    } finally {
      client.close();
    }
  }

  // 画面を再描画
  void _reload() async {
    try {
      // 初期化
      _message = "";
      _userList = [];

      String result = await _getUsers();
      _userList = List<Map<String, dynamic>>.from(json.decode(result));
    } catch (e) {
      _message = e.toString();
    }
    // 画面を再描画
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Fasse"),
      ),
      body: Column(
        children: [
          SelectableText(_message),
          SizedBox(
            width: 768,
            height: 432,
            child: (_userList.isEmpty)
                ? const Text("")
                : ListView.builder(
                    itemCount: _userList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Text(_userList[index]["foodNm"]);
                    },
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
