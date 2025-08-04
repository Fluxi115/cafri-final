import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  latlng.LatLng? _pickedLatLng;
  latlng.LatLng? _initialLatLng;
  String? _error;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          setState(() {
            _error = 'Permiso de ubicación denegado.';
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _initialLatLng = latlng.LatLng(position.latitude, position.longitude);
        _pickedLatLng = _initialLatLng;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo obtener la ubicación: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Selecciona ubicación'),
          backgroundColor: Colors.indigo,
        ),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_initialLatLng == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Selecciona ubicación'),
          backgroundColor: Colors.indigo,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return kIsWeb ? _buildWebMap(context) : _buildMobileMap(context);
  }

  Widget _buildWebMap(BuildContext context) {
    final mapController = MapController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona ubicación'),
        backgroundColor: Colors.indigo,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _initialLatLng!,
              initialZoom: 16,
              minZoom: 3,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all, // Permite arrastrar y hacer zoom
              ),
              onTap: (tapPosition, point) {
                setState(() {
                  _pickedLatLng = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              if (_pickedLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLatLng!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: const Text(
                'Seleccionar ubicación',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: _pickedLatLng == null
                  ? null
                  : () {
                      Navigator.pop(context, _pickedLatLng);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMap(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona ubicación'),
        backgroundColor: Colors.indigo,
      ),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(
              target: gmaps.LatLng(
                _initialLatLng!.latitude,
                _initialLatLng!.longitude,
              ),
              zoom: 16,
            ),
            onTap: (pos) {
              setState(() {
                _pickedLatLng = latlng.LatLng(pos.latitude, pos.longitude);
              });
            },
            markers: _pickedLatLng != null
                ? {
                    gmaps.Marker(
                      markerId: const gmaps.MarkerId('picked'),
                      position: gmaps.LatLng(
                        _pickedLatLng!.latitude,
                        _pickedLatLng!.longitude,
                      ),
                    ),
                  }
                : {},
          ),
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: const Text(
                'Seleccionar ubicación',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: _pickedLatLng == null
                  ? null
                  : () {
                      Navigator.pop(context, _pickedLatLng);
                    },
            ),
          ),
        ],
      ),
    );
  }
}
