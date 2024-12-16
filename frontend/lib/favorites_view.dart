import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _chargers = fetchFavoriteChargers();
  }

  Future<List<Charger>> fetchFavoriteChargers() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      return [];
    }

    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/api/favorites'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = json.decode(responseBody);
      List<Charger> chargers =
          data.map((charger) => Charger.fromJson(charger)).toList();
      return chargers;
    } else {
      throw Exception('Failed to load favorite chargers');
    }
  }

  Future<void> removeFromFavorites(Charger charger) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      return;
    }

    final response = await http.delete(
      Uri.parse('${dotenv.env['API_URL']}/api/favorites/${charger.id}'),
      headers: {
        'Authorization': 'Bearer $accessToken',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Chargers')),
      body: FutureBuilder<List<Charger>>(
        future: _chargers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorite chargers'));
          } else {
            final chargers = snapshot.data!;
            return ListView.separated(
              itemCount: chargers.length,
              itemBuilder: (context, index) {
                final charger = chargers[index];
                return ListTile(
                  title: Text(charger.name),
                  subtitle: Text(charger.freeformAddress),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      removeFromFavorites(charger);
                    },
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return const Divider();
              },
            );
          }
        },
      ),
    );
  }
}
