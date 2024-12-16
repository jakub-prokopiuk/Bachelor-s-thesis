import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'list_view.dart';
import 'filter_view.dart';
import 'favorites_view.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _currentLocation;
  bool _locationError = false;
  late MapController _mapController;
  List<Map<String, dynamic>> _chargers = [];

  double? minPower;
  double? maxPower;
  String? connectorType;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _mapController = MapController();
    _loadChargers();
  }

  Future<void> _loadChargers() async {
    try {
      List<Map<String, dynamic>> chargers = await fetchChargers();
      setState(() {
        _chargers = chargers;
      });
    } catch (e) {
      setState(() {
        _locationError = true;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchChargers() async {
    final queryParams = <String, String>{};

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
      List<dynamic> data = json.decode(response.body);
      return data.map((charger) {
        return {
          'latitude': charger['latitude'],
          'longitude': charger['longitude'],
          'name': charger['name'],
        };
      }).toList();
    } else {
      throw Exception('Failed to load chargers');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = true;
        });
        return;
      }

      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = true;
        });
      }
    }
  }

  void _centerMapOnLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 17.0);
    }
  }

  void _resetMapOrientation() {
    _mapController.rotate(0.0);
  }

  void _goToListPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChargerListView()),
    );
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
              _loadChargers();
            });
          },
        );
      },
    );
  }

  void _goToFavoritesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoriteChargersView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _locationError
              ? const Center(child: Text('Error fetching location'))
              : _currentLocation == null
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation!,
                        initialZoom: 17.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: _chargers.map((charger) {
                            return Marker(
                              point: LatLng(
                                  charger['latitude'], charger['longitude']),
                              width: 40.0,
                              height: 40.0,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                    onPressed: _goToListPage, child: const Icon(Icons.list)),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _centerMapOnLocation,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _resetMapOrientation,
                  child: const Icon(Icons.rotate_left),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _showFilterDialog,
                  child: const Icon(Icons.filter_list),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _goToFavoritesPage,
                  child: const Icon(Icons.favorite),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
