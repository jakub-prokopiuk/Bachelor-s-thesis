import 'package:flutter/material.dart';
import 'welcome_page.dart';

void main() {
  runApp(const WattWay());
}

class WattWay extends StatelessWidget {
  const WattWay({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WattWay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const WelcomePage(),
    );
  }
}
