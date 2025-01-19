import 'package:flutter/material.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/functions.dart';
import 'package:localpkg/online.dart';
import 'package:localpkg/theme.dart';
import 'package:localpkg/logger.dart';
import 'package:localpkg/widgets.dart';
import 'package:merciless/game.dart';
import 'package:merciless/var.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Merciless',
      theme: brandTheme(seedColor: Colors.red),
      darkTheme: brandTheme(seedColor: Colors.red, darkMode: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String code = '';

  @override
  void initState() {
    super.initState();
    print("beta,debug: $beta,$debug");
    print("fetch info: ${getFetchInfo(debug: debug)}");
    showFirstTimeDialogue(context, "Welcome to Merciless!", "$description\n\n$instructions", false);
    serverlaunch(context: context, service: "Merciless");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Select a Mode"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BlockButton(text: "Join Public Room", size: 200, action: () async {}),
              BlockButton(text: "Create Private Room", size: 200, action: () async {}),
              BlockButton(text: "Join Private Room", size: 200, action: () async {}),
              BlockButton(text: "Singleplayer", size: 200, action: () async {
                navigate(context: context, page: Game(mode: 1, goal: 13));
              }),
            ],
          ),
        ),
      )
    );
  }

  bool isValid(String input) {
    return input.length == 9 && RegExp(r'^[0-9]+$').hasMatch(input);
  }
}