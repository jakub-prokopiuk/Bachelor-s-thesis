import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'favorite_button.dart';

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
      'icon': 'assets/icons/Type2.svg',
      'dbValue': 'IEC62196Type2CableAttached',
    },
    {
      'type': 'Type 2 Outlet',
      'icon': 'assets/icons/Type2.svg',
      'dbValue': 'IEC62196Type2Outlet',
    },
    {
      'type': 'Type 3',
      'icon': 'assets/icons/Type3.svg',
      'dbValue': 'IEC62196Type3',
    },
    {
      'type': 'Tesla',
      'icon': 'assets/icons/Tesla.svg',
      'dbValue': 'Tesla',
    },
    {
      'type': 'Chademo',
      'icon': 'assets/icons/Chademo.svg',
      'dbValue': 'Chademo',
    },
    {
      'type': 'CCS',
      'icon': 'assets/icons/CCS2.svg',
      'dbValue': 'IEC62196Type2CCS',
    },
  ];

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

  String getConnectorIcon(String dbValue) {
    final connector = connectorTypes.firstWhere(
      (type) => type['dbValue'] == dbValue,
      orElse: () => {'icon': 'assets/icons/default.svg'},
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
        final iconPath = getConnectorIcon(dbValue);

        final connectorTypeStatus = chargingStatus[dbValue] ?? {};
        final availability = connectorTypeStatus['available'] != null
            ? (connectorTypeStatus['available'] >= 1
                ? 'Available'
                : 'Not Available')
            : 'Status Unknown';
        final availabilityColor = availability == 'Available'
            ? Colors.green
            : availability == 'Not Available'
                ? Colors.red
                : Colors.grey;

        return ListTile(
          leading: SvgPicture.asset(
            iconPath,
            colorFilter: ColorFilter.mode(Colors.orange, BlendMode.srcIn),
            width: 30,
            height: 30,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchChargerDetails(widget.chargerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.green,
            ));
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
                  return const Center(
                      child: CircularProgressIndicator(
                    color: Colors.green,
                  ));
                } else if (chargingStatusSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${chargingStatusSnapshot.error}'));
                } else {
                  final chargingStatus =
                      chargingStatusSnapshot.data ?? <String, dynamic>{};

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
                            FutureBuilder<List<String>>(
                              future: _getFavorites(),
                              builder: (context, favoritesSnapshot) {
                                final isFavorite = favoritesSnapshot.data
                                        ?.contains(widget.chargerId) ??
                                    false;

                                return FavoriteButton(
                                  chargerId: widget.chargerId,
                                  initialFavorite: isFavorite,
                                );
                              },
                            ),
                            IconButton(
                              onPressed: () => openLocation(
                                context,
                                data['name'],
                                data['latitude'],
                                data['longitude'],
                              ),
                              icon: Icon(Icons.location_on_outlined),
                              color: Colors.green,
                              iconSize: 30,
                            ),
                          ],
                        ),
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
