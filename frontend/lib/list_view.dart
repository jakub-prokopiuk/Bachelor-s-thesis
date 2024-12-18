import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'filter_view.dart';
import 'charger_details_view.dart';

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
  String? connectorType;

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

    final queryParams = <String, String>{};

    queryParams['user_latitude'] = userLatitude.toString();
    queryParams['user_longitude'] = userLongitude.toString();

    if (minPower != null) {
      queryParams['min_power'] = minPower.toString();
    }
    if (maxPower != null) {
      queryParams['max_power'] = maxPower.toString();
    }
    if (connectorType != null && connectorType!.isNotEmpty) {
      queryParams['connector_types'] = connectorType!;
    }

    final uri = Uri.parse('${dotenv.env['API_URL']}/api/chargers').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri);

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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FilterWidget(
          minPower: minPower ?? 0.0,
          maxPower: maxPower,
          selectedConnectorTypes: connectorType?.split(',') ?? [],
          onApply: (double minPower, double? maxPower,
              List<String>? connectorTypes) {
            setState(() {
              this.minPower = minPower;
              this.maxPower = maxPower;
              if (connectorTypes != null && connectorTypes.isNotEmpty) {
                connectorType = connectorTypes.join(',');
              } else {
                connectorType = null;
              }
              _chargers = fetchChargers(userLatitude, userLongitude);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
                        title: Text(charger.name),
                        subtitle: Text(charger.freeformAddress),
                        trailing: IconButton(
                          icon: Icon(
                            charger.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              charger.toggleFavorite();
                            });
                            _toggleFavorite(charger.id, charger.isFavorite);
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChargerDetailsView(chargerId: charger.id),
                            ),
                          );
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const Divider();
                    },
                  );
                }
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        child: const Icon(Icons.filter_list),
      ),
    );
  }
}
