import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Charger {
  final String id;
  final String name;
  final String freeformAddress;
  bool isFavorite;

  Charger({
    required this.id,
    required this.name,
    required this.freeformAddress,
    this.isFavorite = false,
  });

  factory Charger.fromJson(Map<String, dynamic> json) {
    return Charger(
      id: json['id'].toString(),
      name: json['name'],
      freeformAddress: json['freeform_address'],
      isFavorite: false,
    );
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}

class ChargerListView extends StatefulWidget {
  const ChargerListView({super.key});

  @override
  State<ChargerListView> createState() => _ChargerListViewState();
}

class _ChargerListViewState extends State<ChargerListView> {
  late Future<List<Charger>> _chargers;
  double? userLatitude;
  double? userLongitude;

  double? minPower;
  double? maxPower;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        userLatitude = position.latitude;
        userLongitude = position.longitude;
        _chargers = fetchChargers(userLatitude, userLongitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<List<Charger>> fetchChargers(
      double? userLatitude, double? userLongitude) async {
    if (userLatitude == null || userLongitude == null) {
      throw Exception('User location is not available');
    }

    final response = await http.get(Uri.parse(
        '${dotenv.env['API_URL']}/api/closest-chargers?user_latitude=$userLatitude&user_longitude=$userLongitude'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      List<Charger> chargers =
          data.map((charger) => Charger.fromJson(charger)).toList();

      final favorites = await _getFavorites();
      for (var charger in chargers) {
        if (favorites.contains(charger.id)) {
          charger.isFavorite = true;
        }
      }

      return chargers;
    } else {
      throw Exception('Failed to load chargers');
    }
  }

  Future<List<String>> _getFavorites() async {
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
      final List<dynamic> favorites = json.decode(response.body);
      return favorites
          .map((favorite) => favorite['charger_id'].toString())
          .toList();
    } else {
      return [];
    }
  }

  Future<void> _addToFavorites(String chargerId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in first')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL']}/api/favorites/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'charger_id': chargerId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Charger added to favorites')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to favorites')),
      );
    }
  }

  Future<void> _removeFromFavorites(String chargerId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in first')),
      );
      return;
    }

    final response = await http.delete(
      Uri.parse('${dotenv.env['API_URL']}/api/favorites/$chargerId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Charger removed from favorites')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove from favorites')),
      );
    }
  }

  Future<void> _toggleFavorite(String chargerId, bool isFavorite) async {
    if (!isFavorite) {
      await _removeFromFavorites(chargerId);
    } else {
      await _addToFavorites(chargerId);
    }
  }

  void _showFilterDialog() async {
    double? tempMinPower = minPower;
    double? tempMaxPower = maxPower;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Chargers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min Power (kW)'),
                onChanged: (value) {
                  tempMinPower = double.tryParse(value);
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Power (kW)'),
                onChanged: (value) {
                  tempMaxPower = double.tryParse(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  minPower = tempMinPower;
                  maxPower = tempMaxPower;
                  _chargers = fetchChargers(userLatitude, userLongitude);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userLatitude == null || userLongitude == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Charger>>(
              future: _chargers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No chargers available'));
                } else {
                  final chargers = snapshot.data!;
                  return ListView.separated(
                    itemCount: chargers.length,
                    itemBuilder: (context, index) {
                      final charger = chargers[index];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        leading: Icon(
                          Icons.ev_station,
                          color: Colors.green,
                        ),
                        title: Text(
                          charger.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          charger.freeformAddress,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        tileColor: Colors.grey[100],
                        trailing: IconButton(
                          icon: Icon(
                            charger.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: charger.isFavorite ? Colors.red : null,
                          ),
                          onPressed: () async {
                            setState(() {
                              charger.toggleFavorite();
                            });

                            await _toggleFavorite(
                                charger.id, charger.isFavorite);
                          },
                        ),
                        onTap: () {
                          //TODO Navigate to charger details
                        },
                      );
                    },
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Divider(
                        color: Colors.grey[300],
                        height: 1,
                      ),
                    ),
                  );
                }
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        tooltip: 'Filter Chargers',
        child: const Icon(Icons.filter_list),
      ),
    );
  }
}
