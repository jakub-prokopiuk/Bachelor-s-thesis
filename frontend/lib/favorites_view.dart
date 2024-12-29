import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watt_way/favorite_button.dart';

import 'charger_details_view.dart';
import 'login_page.dart';

class Charger {
  final String id;
  final String name;
  final String freeformAddress;

  Charger({
    required this.id,
    required this.name,
    required this.freeformAddress,
  });

  factory Charger.fromJson(Map<String, dynamic> json) {
    return Charger(
      id: json['charger_id'].toString(),
      name: json['name'],
      freeformAddress: json['freeform_address'],
    );
  }
}

class FavoriteChargersView extends StatefulWidget {
  const FavoriteChargersView({super.key});

  @override
  State<FavoriteChargersView> createState() => _FavoriteChargersViewState();
}

class _FavoriteChargersViewState extends State<FavoriteChargersView> {
  late Future<List<Charger>> _chargers;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
  }

  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _accessToken = prefs.getString('access_token');
    });

    if (_accessToken != null) {
      _chargers = fetchFavoriteChargers();
    }
  }

  Future<List<Charger>> fetchFavoriteChargers() async {
    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/api/favorites/'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = json.decode(responseBody);
      return data.map((charger) => Charger.fromJson(charger)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load favorite chargers');
    }
  }

  Future<void> removeFromFavorites(Charger charger) async {
    final response = await http.delete(
      Uri.parse('${dotenv.env['API_URL']}/api/favorites/${charger.id}'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _chargers = fetchFavoriteChargers();
      });
    } else {
      throw Exception('Failed to remove charger from favorites');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_accessToken == null) {
      return Scaffold(
        body: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange,
                Colors.green,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'You should log in first to add chargers to favorites',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Log In',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<Charger>>(
        future: _chargers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                  'Failed to load favorite chargers. Please try again later.'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You have no favorite chargers yet.'),
            );
          } else {
            final chargers = snapshot.data!;
            return ListView.separated(
              itemCount: chargers.length,
              itemBuilder: (context, index) {
                final charger = chargers[index];
                return ListTile(
                  title: Text(charger.name),
                  subtitle: Text(charger.freeformAddress),
                  trailing: FavoriteButton(
                    chargerId: charger.id,
                    initialFavorite: true,
                    iconSize: 24.0,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChargerDetailsView(
                          chargerId: charger.id,
                        ),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(),
                );
              },
            );
          }
        },
      ),
    );
  }
}
