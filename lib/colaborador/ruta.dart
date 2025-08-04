//

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class MapaConRutaDesdeUrl extends StatefulWidget {
  final String apiKey; // Google Maps Directions API Key

  const MapaConRutaDesdeUrl({super.key, required this.apiKey});

  @override
  State<MapaConRutaDesdeUrl> createState() => _MapaConRutaDesdeUrlState();
}

class _MapaConRutaDesdeUrlState extends State<MapaConRutaDesdeUrl> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  final TextEditingController _urlController = TextEditingController();

  // Historial de ruta recorrida
  final List<LatLng> _historialRuta = [];
  Polyline? _historialPolyline;

  // Seguimiento y rotación
  StreamSubscription<Position>? _posSub;
  StreamSubscription<CompassEvent>? _compassSub;
  double _currentBearing = 0.0;
  LatLng? _lastUserPosition;

  // Estado de permisos
  bool _locationPermissionGranted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _iniciarSeguimientoUbicacion();
    _iniciarRotacionMapa();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _compassSub?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  /// Procesa la URL ingresada, extrae coordenadas y solicita la ruta o muestra un marcador.
  Future<void> _procesarUrl() async {
    final url = _urlController.text.trim();
    // Busca todos los pares de coordenadas en la URL
    final coordRegex = RegExp(r'(-?\d+\.\d+),(-?\d+\.\d+)');
    final matches = coordRegex.allMatches(url).toList();
    if (matches.length >= 2) {
      // Ruta: dos pares de coordenadas
      try {
        final origenLat = double.parse(matches[0].group(1)!);
        final origenLng = double.parse(matches[0].group(2)!);
        final destinoLat = double.parse(matches[1].group(1)!);
        final destinoLng = double.parse(matches[1].group(2)!);
        final origen = LatLng(origenLat, origenLng);
        final destino = LatLng(destinoLat, destinoLng);
        await _obtenerRuta(origen, destino);
      } catch (e) {
        _mostrarError('Error al analizar las coordenadas: $e');
      }
    } else if (matches.length == 1) {
      // Solo un punto: muestra marcador
      try {
        final lat = double.parse(matches[0].group(1)!);
        final lng = double.parse(matches[0].group(2)!);
        final punto = LatLng(lat, lng);
        setState(() {
          _polylines = {};
          _markers = {
            Marker(
              markerId: const MarkerId('punto'),
              position: punto,
              infoWindow: const InfoWindow(title: 'Ubicación'),
            ),
            if (_lastUserPosition != null)
              Marker(
                markerId: const MarkerId('yo'),
                position: _lastUserPosition!,
                infoWindow: const InfoWindow(title: 'Tú'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              ),
          };
        });
        // Centrar el mapa en el punto
        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(punto, 17));
        }
      } catch (e) {
        _mostrarError('Error al analizar la coordenada: $e');
      }
    } else {
      _mostrarError(
        'URL no válida. Asegúrate de que la URL contiene al menos un par de coordenadas.\n'
        'Ejemplo de ruta: https://www.google.com/maps/dir/19.432608,-99.133209/19.427025,-99.167665\n'
        'Ejemplo de punto: https://www.google.com/maps/search/?api=1&query=20.941528145713328,-89.61158860685893',
      );
    }
  }

  /// Solicita la ruta a la API de Google Directions y la dibuja en el mapa.
  Future<void> _obtenerRuta(LatLng origen, LatLng destino) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origen.latitude},${origen.longitude}&destination=${destino.latitude},${destino.longitude}&key=${widget.apiKey}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = PolylinePoints().decodePolyline(
            data['routes'][0]['overview_polyline']['points'],
          );
          final polylineCoordinates = points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('ruta'),
                color: Colors.blue,
                width: 5,
                points: polylineCoordinates,
              ),
              if (_historialPolyline != null) _historialPolyline!,
            };
            _markers = {
              Marker(
                markerId: const MarkerId('origen'),
                position: origen,
                infoWindow: const InfoWindow(title: 'Origen'),
              ),
              Marker(
                markerId: const MarkerId('destino'),
                position: destino,
                infoWindow: const InfoWindow(title: 'Destino'),
              ),
              if (_lastUserPosition != null)
                Marker(
                  markerId: const MarkerId('yo'),
                  position: _lastUserPosition!,
                  infoWindow: const InfoWindow(title: 'Tú'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
            };
          });

          // Centrar el mapa en la ruta
          if (_mapController != null) {
            final bounds = LatLngBounds(
              southwest: LatLng(
                (origen.latitude < destino.latitude)
                    ? origen.latitude
                    : destino.latitude,
                (origen.longitude < destino.longitude)
                    ? origen.longitude
                    : destino.longitude,
              ),
              northeast: LatLng(
                (origen.latitude > destino.latitude)
                    ? origen.latitude
                    : destino.latitude,
                (origen.longitude > destino.longitude)
                    ? origen.longitude
                    : destino.longitude,
              ),
            );
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 60),
            );
          }
        } else {
          _mostrarError('No se encontró una ruta.');
        }
      } else {
        _mostrarError(
          'Error al obtener la ruta. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      _mostrarError('Error de red: $e');
    }
  }

  void _mostrarError(String mensaje) {
    setState(() {
      _errorMessage = mensaje;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _iniciarSeguimientoUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (serviceEnabled &&
        permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever) {
      setState(() {
        _locationPermissionGranted = true;
        _errorMessage = null;
      });
      _posSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((Position pos) {
            final userLatLng = LatLng(pos.latitude, pos.longitude);

            // Guardar historial de ruta recorrida
            setState(() {
              _lastUserPosition = userLatLng;
              _historialRuta.add(userLatLng);
              _historialPolyline = Polyline(
                polylineId: const PolylineId('historial'),
                color: Colors.red,
                width: 4,
                points: List<LatLng>.from(_historialRuta),
              );
              // Actualizar polylines y marcador de usuario
              _polylines = {
                ..._polylines.where((p) => p.polylineId.value != 'historial'),
                _historialPolyline!,
              };
              _markers = {
                ..._markers.where((m) => m.markerId.value != 'yo'),
                Marker(
                  markerId: const MarkerId('yo'),
                  position: userLatLng,
                  infoWindow: const InfoWindow(title: 'Tú'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              };
            });

            // Centrar el mapa en la nueva posición y aplicar rotación
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: userLatLng,
                    zoom: 17,
                    bearing: _currentBearing,
                  ),
                ),
              );
            }
          });
    } else {
      setState(() {
        _locationPermissionGranted = false;
        _errorMessage = 'Permiso de ubicación denegado o servicio desactivado.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  void _iniciarRotacionMapa() {
    _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        setState(() {
          _currentBearing = event.heading!;
        });
      }
    });
  }

  void _limpiarHistorial() {
    setState(() {
      _historialRuta.clear();
      _historialPolyline = null;
      _polylines = _polylines
          .where((p) => p.polylineId.value != 'historial')
          .toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar permisos'),
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _iniciarSeguimientoUbicacion();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Pega la URL de Google Maps (dirección o punto)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _procesarUrl,
                tooltip: 'Procesar URL',
              ),
            ),
            onSubmitted: (_) => _procesarUrl(),
          ),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Limpiar historial'),
              onPressed: _limpiarHistorial,
            ),
            const SizedBox(width: 10),
            Text('Puntos en historial: ${_historialRuta.length}'),
            if (!_locationPermissionGranted)
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Icon(Icons.warning, color: Colors.red),
              ),
          ],
        ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(21.161908, -89.057106), // Mérida por defecto
              zoom: 12,
            ),
            polylines: _polylines,
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: true,
            compassEnabled: true,
          ),
        ),
      ],
    );
  }
}
