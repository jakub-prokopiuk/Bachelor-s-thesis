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
        inputDecorationTheme: InputDecorationTheme(
          focusColor: Colors.green,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
            borderRadius: BorderRadius.circular(10),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.orange,
          selectionColor: Colors.green.withOpacity(0.4),
          selectionHandleColor: Colors.orange.withOpacity(0.8),
        ),
      ),
      themeMode: ThemeMode.system,
      home: accessToken == null ? const WelcomePage() : const MapPage(),
    );
  }
}
