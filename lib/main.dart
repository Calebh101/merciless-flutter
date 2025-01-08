import 'package:flutter/material.dart';
import 'package:localpkg/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merciless',
      theme: brandTheme(seedColor: Colors.red, backgroundColor: Colors.deepOrange, textColor: Colors.white),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Merciless Main Menu"),
      ),
      body: Text("Merciless"),
    );
  }
}
