import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:watt_way/cool_snackbar.dart';
import 'filter_view.dart';
import 'charger_details_view.dart';
import 'favorite_button.dart';

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
      id: json['id'].toString(),
      name: json['name'],
      freeformAddress: json['freeform_address'],
    );
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
      CoolSnackbar.show(context,
          message: 'Error: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error);
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
      return data.map((charger) => Charger.fromJson(charger)).toList();
    } else {
      throw Exception('Failed to load chargers');
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
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.green,
            ))
          : FutureBuilder<List<Charger>>(
              future: _chargers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: Colors.green,
                  ));
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
                        trailing: FavoriteButton(
                          chargerId: charger.id,
                          initialFavorite: false,
                          iconSize: 24,
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
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(),
                      );
                    },
                  );
                }
              },
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
      ),
    );
  }
}
