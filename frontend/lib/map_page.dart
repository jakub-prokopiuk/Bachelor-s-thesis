import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'list_view.dart';
import 'filter_view.dart';
import 'favorites_view.dart';
import 'charger_details_view.dart';

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
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  late FocusNode _searchFocusNode;

  double? minPower;
  double? maxPower;
  String? connectorType;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _getCurrentLocation();
    _mapController = MapController();
    _loadChargers();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
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
          'id': charger['id'],
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

  Future<void> _searchAddress(String query) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search')
        .replace(queryParameters: {
      'q': query,
      'format': 'json',
      'addressdetails': '1',
      'limit': '3',
      'countrycodes': 'pl',
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        _searchResults = data.map((result) {
          return {
            'display_name': result['display_name'],
            'latitude': double.parse(result['lat']),
            'longitude': double.parse(result['lon']),
          };
        }).toList();
      });
    }
  }

  void _centerMapOnSearchResult(LatLng location) {
    _mapController.move(location, 17.0);
    setState(() {
      _searchResults.clear();
      _searchController.clear();
    });
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
    ).whenComplete(() {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
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
                  ? const Center(
                      child: CircularProgressIndicator(
                      color: Colors.green,
                    ))
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation!,
                        initialZoom: 17.0,
                        onTap: (_, __) {
                          setState(() {
                            _searchResults.clear();
                            _searchController.clear();
                          });
                          FocusScope.of(context).unfocus();
                        },
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
                                charger['latitude'],
                                charger['longitude'],
                              ),
                              width: 30.0,
                              height: 30.0,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChargerDetailsView(
                                        chargerId: charger['id'].toString(),
                                      ),
                                    ),
                                  );
                                },
                                child: SvgPicture.asset(
                                  'assets/icons/pin.svg',
                                  width: 40.0,
                                  height: 40.0,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: 0.6,
                        child: TextField(
                          focusNode: _searchFocusNode,
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for an address',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults.clear();
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _searchAddress(value);
                            } else {
                              setState(() {
                                _searchResults.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
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
                    SizedBox(width: 8),
                    Container(
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
                        icon: const Icon(Icons.favorite_border_outlined),
                        onPressed: _goToFavoritesPage,
                      ),
                    ),
                  ],
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(
                            result['display_name'],
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            _centerMapOnSearchResult(LatLng(
                              result['latitude'],
                              result['longitude'],
                            ));
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                Container(
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
                    icon: const Icon(Icons.list),
                    onPressed: _goToListPage,
                  ),
                ),
                SizedBox(height: 16),
                Container(
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
                    icon: const Icon(Icons.my_location),
                    onPressed: _centerMapOnLocation,
                  ),
                ),
                SizedBox(height: 16),
                Container(
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
                    icon: const Icon(Icons.rotate_right),
                    onPressed: _resetMapOrientation,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
