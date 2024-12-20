import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChargerDetailsView extends StatefulWidget {
  final String chargerId;

  const ChargerDetailsView({super.key, required this.chargerId});

  @override
  State<ChargerDetailsView> createState() => _ChargerDetailsViewState();
}

class _ChargerDetailsViewState extends State<ChargerDetailsView> {
  final List<Map<String, dynamic>> connectorTypes = [
    {
      'type': 'Type 2',
      'icon': Icons.car_rental,
      'dbValue': 'IEC62196Type2CableAttached',
    },
    {
      'type': 'Type 3',
      'icon': Icons.electric_bolt,
      'dbValue': 'IEC62196Type3',
    },
    {
      'type': 'Type 2 Outlet',
      'icon': Icons.power,
      'dbValue': 'IEC62196Type2Outlet',
    },
    {
      'type': 'Tesla',
      'icon': Icons.car_repair,
      'dbValue': 'Tesla',
    },
    {
      'type': 'Chademo',
      'icon': Icons.car_crash,
      'dbValue': 'Chademo',
    },
    {
      'type': 'CCS',
      'icon': Icons.energy_savings_leaf,
      'dbValue': 'IEC62196Type2CCS',
    },
  ];

  bool isFavorite = false;

  Future<Map<String, dynamic>> fetchChargerDetails(String chargerId) async {
    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/api/chargers/$chargerId'),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load charger details');
    }
  }

  Future<Map<String, dynamic>?> fetchChargingStatus(String chargerId) async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/charging-status/$chargerId'),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  String getConnectorType(String dbValue) {
    final connector = connectorTypes.firstWhere(
      (type) => type['dbValue'] == dbValue,
      orElse: () => {'type': 'Unknown'},
    );
    return connector['type'];
  }

  IconData getConnectorIcon(String dbValue) {
    final connector = connectorTypes.firstWhere(
      (type) => type['dbValue'] == dbValue,
      orElse: () => {'icon': Icons.help},
    );
    return connector['icon'];
  }

  Future<void> openLocation(BuildContext context, String name, double latitude,
      double longitude) async {
    try {
      if (Platform.isAndroid) {
        final url =
            Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($name)');
        await launchUrl(url);
      } else if (Platform.isIOS) {
        final url =
            Uri.parse('maps:$latitude,$longitude?q=$latitude,$longitude');
        await launchUrl(url);
      }
    } catch (error) {
      throw Exception('Could not launch maps');
    }
  }

  Widget buildConnectorList(
    List<dynamic> connectors,
    Map<String, dynamic> chargingStatus,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: connectors.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final connector = connectors[index];
        final dbValue = connector['connector_type'];
        final type = getConnectorType(dbValue);
        final icon = getConnectorIcon(dbValue);

        final connectorTypeStatus = chargingStatus[dbValue] ?? {};
        final availability = connectorTypeStatus['available'] != null
            ? (connectorTypeStatus['available'] == 1
                ? 'Available'
                : 'Not Available')
            : 'Status Unknown';

        final availabilityColor = availability == 'Available'
            ? Colors.green
            : availability == 'Not Available'
                ? Colors.red
                : Colors.grey;

        return ListTile(
          leading: Icon(icon, color: Colors.blue),
          title: Text(type),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Power: ${connector['rated_power_kw']?.toStringAsFixed(1) ?? 'N/A'} kW',
              ),
              Text(
                availability,
                style: TextStyle(color: availabilityColor),
              ),
            ],
          ),
        );
      },
    );
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
      setState(() {
        isFavorite = true;
      });
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
      setState(() {
        isFavorite = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove from favorites')),
      );
    }
  }

  Future<void> _toggleFavorite(String chargerId, bool isFavorite) async {
    if (isFavorite) {
      await _removeFromFavorites(chargerId);
    } else {
      await _addToFavorites(chargerId);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchChargerDetails(widget.chargerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No details available'));
          } else {
            final data = snapshot.data!;
            final connectors = data['connectors'] as List<dynamic>;

            return FutureBuilder<Map<String, dynamic>?>(
              future: fetchChargingStatus(widget.chargerId),
              builder: (context, chargingStatusSnapshot) {
                if (chargingStatusSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (chargingStatusSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${chargingStatusSnapshot.error}'));
                } else {
                  final chargingStatus =
                      chargingStatusSnapshot.data ?? <String, dynamic>{};
                  final showNotificationIcon = chargingStatus.isNotEmpty;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            data['name'] ?? 'Unknown',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            data['freeform_address'] ?? 'Address not available',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _toggleFavorite(widget.chargerId, isFavorite),
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                              color: Colors.red,
                              iconSize: 30,
                            ),
                            IconButton(
                              onPressed: () => openLocation(
                                context,
                                data['name'],
                                data['latitude'],
                                data['longitude'],
                              ),
                              icon: const Icon(Icons.location_on_outlined),
                              color: Colors.green,
                              iconSize: 30,
                            ),
                            if (showNotificationIcon)
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.notifications_outlined),
                                color: Colors.blue,
                                iconSize: 30,
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Connectors:',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        buildConnectorList(connectors, chargingStatus),
                      ],
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
