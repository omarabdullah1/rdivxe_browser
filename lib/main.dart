import 'package:flutter/material.dart';

import 'browser_home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Rdivxe Browser',
      home: BrowserHome(),
    );
  }
}
