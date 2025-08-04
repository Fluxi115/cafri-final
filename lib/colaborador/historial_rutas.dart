// import 'package:background_locator_2/background_locator.dart';
// import 'package:background_locator_2/location_dto.dart';
// import 'package:background_locator_2/settings/android_settings.dart';
// import 'package:background_locator_2/settings/ios_settings.dart';
// import 'package:background_locator_2/settings/locator_settings.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:logger/logger.dart';

// final Logger _logger = Logger();

// class HistorialRutasBackgroundService {
//   static const String ubicacionesCollection = 'ubicaciones_colaboradores';
//   static const String _prefsUserIdKey = 'ubicacion_user_id';
//   static const String _prefsNombreKey = 'ubicacion_nombre';
//   static const String _prefsAvatarUrlKey = 'ubicacion_avatar_url';

//   /// Inicia el rastreo en segundo plano y guarda en historial.
//   static Future<void> start(
//     String userId, {
//     String? nombre,
//     String? avatarUrl,
//     double distanceFilterMeters = 1.0, // metros
//     int intervalSeconds = 5, // intervalo mínimo permitido por Android
//   }) async {
//     // Guarda los datos en SharedPreferences para acceso en el callback
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_prefsUserIdKey, userId);
//     if (nombre != null) await prefs.setString(_prefsNombreKey, nombre);
//     if (avatarUrl != null) await prefs.setString(_prefsAvatarUrlKey, avatarUrl);

//     await BackgroundLocator.initialize();

//     BackgroundLocator.registerLocationUpdate(
//       _callback,
//       autoStop: false,
//       androidSettings: AndroidSettings(
//         accuracy: LocationAccuracy.NAVIGATION,
//         interval: intervalSeconds,
//         distanceFilter: distanceFilterMeters,
//         androidNotificationSettings: AndroidNotificationSettings(
//           notificationChannelName: 'Ubicación en segundo plano',
//           notificationTitle: 'Enviando historial de ruta',
//           notificationMsg:
//               'Tu historial de ruta se está guardando en segundo plano',
//           notificationBigMsg:
//               'Tu historial de ruta se está guardando en segundo plano para la app.',
//           notificationIcon: '@mipmap/ic_launcher',
//         ),
//       ),
//       iosSettings: IOSSettings(
//         accuracy: LocationAccuracy.NAVIGATION,
//         distanceFilter: distanceFilterMeters,
//       ),
//     );
//   }

//   /// Callback que se ejecuta en segundo plano para guardar en historial.
//   static Future<void> _callback(LocationDto locationDto) async {
//     final prefs = await SharedPreferences.getInstance();
//     final String? userId = prefs.getString(_prefsUserIdKey);
//     final String? nombre = prefs.getString(_prefsNombreKey);
//     final String? avatarUrl = prefs.getString(_prefsAvatarUrlKey);

//     if (userId == null) return;

//     try {
//       await FirebaseFirestore.instance
//           .collection(ubicacionesCollection)
//           .doc(userId)
//           .collection('historial')
//           .add({
//             'lat': locationDto.latitude,
//             'lng': locationDto.longitude,
//             'timestamp': FieldValue.serverTimestamp(),
//             if (nombre != null) 'nombre': nombre,
//             if (avatarUrl != null) 'avatarUrl': avatarUrl,
//           });
//     } catch (e, stackTrace) {
//       _logger.e(
//         'Error guardando historial en background',
//         error: e,
//         stackTrace: stackTrace,
//       );
//     }
//   }

//   /// Detiene el rastreo en segundo plano.
//   static Future<void> stop() async {
//     await BackgroundLocator.unRegisterLocationUpdate();
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_prefsUserIdKey);
//     await prefs.remove(_prefsNombreKey);
//     await prefs.remove(_prefsAvatarUrlKey);
//   }
// }
