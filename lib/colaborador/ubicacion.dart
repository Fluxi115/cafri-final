import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class SeguimientoTiempoRealService {
  static Timer? _timer;
  static bool _isRunning = false;

  static const String ubicacionesCollection = 'ubicaciones_colaboradores';

  /// Inicia el seguimiento en tiempo real: actualiza la ubicación actual del usuario cada segundo en Firestore,
  /// incluso si no hay movimiento.
  static Future<void> start(
    String userId, {
    String? nombre,
    String? avatarUrl,
  }) async {
    if (_isRunning) return;
    _isRunning = true;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _isRunning = false;
        return;
      }
    }

    // Envía la ubicación actual al iniciar sesión
    Position initialPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    await _updateUbicacionActual(
      userId,
      position: initialPosition,
      nombre: nombre,
      avatarUrl: avatarUrl,
    );

    // Inicia un timer que actualiza la ubicación cada segundo
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await _updateUbicacionActual(
          userId,
          position: position,
          nombre: nombre,
          avatarUrl: avatarUrl,
        );
      } catch (e, stackTrace) {
        _logger.e(
          'Error obteniendo o actualizando ubicación actual',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  /// Detiene el seguimiento en tiempo real.
  static Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Actualiza la ubicación actual en Firestore.
  static Future<void> _updateUbicacionActual(
    String userId, {
    required Position position,
    String? nombre,
    String? avatarUrl,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(ubicacionesCollection)
          .doc(userId)
          .set({
            'lat': position.latitude,
            'lng': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            if (nombre != null) 'nombre': nombre,
            if (avatarUrl != null) 'avatarUrl': avatarUrl,
          }, SetOptions(merge: true));
    } catch (e, stackTrace) {
      _logger.e(
        'Error actualizando ubicación actual',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
