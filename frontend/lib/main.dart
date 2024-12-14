import 'package:flutter/material.dart';
import 'welcome_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
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
