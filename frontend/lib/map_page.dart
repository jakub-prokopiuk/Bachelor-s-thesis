import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'list_view.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _currentLocation;
  bool _locationError = false;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _mapController = MapController();
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

  void _getVisibleBounds() {
    LatLngBounds bounds = _mapController.camera.visibleBounds;

    LatLng northWest = bounds.northWest;
    LatLng southEast = bounds.southEast;

    debugPrint("Visible bounds:");
    debugPrint("Nortwest: (${northWest.latitude}, ${northWest.longitude})");
    debugPrint("Southeast: (${southEast.latitude}, ${southEast.longitude})");
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
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture) {
                            _getVisibleBounds();
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
