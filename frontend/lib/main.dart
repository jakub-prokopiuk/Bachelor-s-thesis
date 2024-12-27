import 'package:flutter/material.dart';
import 'welcome_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_page.dart';

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');

  runApp(WattWay(accessToken: accessToken));
}

class WattWay extends StatelessWidget {
  final String? accessToken;

  const WattWay({super.key, this.accessToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WattWay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: accessToken == null ? const WelcomePage() : const MapPage(),
    );
  }
}
