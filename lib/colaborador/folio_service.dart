import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class FolioService {
  static final Logger _logger = Logger();

  static const String _collection = 'config';
  static const String _document = 'folio';
  static const String _field = 'valor';
  static const int _defaultFolio = 2140669;

  /// Obtiene el siguiente folio disponible desde Firestore (NO seguro para concurrencia).
  static Future<int> getNextFolio() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_document)
          .get();

      final ultimoFolio = doc.data()?[_field] as int?;
      final siguienteFolio = (ultimoFolio ?? _defaultFolio) + 1;
      _logger.i(
        '[FolioService] getNextFolio: El siguiente folio es $siguienteFolio',
      );
      return siguienteFolio;
    } catch (e, stack) {
      _logger.e(
        '[FolioService] Error en getNextFolio',
        error: e,
        stackTrace: stack,
      );
      // Devuelve el default en caso de error
      return _defaultFolio + 1;
    }
  }

  /// Actualiza el folio en Firestore después de generar un PDF (NO seguro para concurrencia).
  static Future<void> updateFolio(int nuevoFolio) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_document)
          .set({_field: nuevoFolio}, SetOptions(merge: true));
      _logger.i('[FolioService] updateFolio: Folio actualizado a $nuevoFolio');
    } catch (e, stack) {
      _logger.e(
        '[FolioService] Error en updateFolio',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Obtiene y actualiza el folio de manera atómica usando una transacción.
  /// Garantiza que cada llamada concurrente reciba un folio único y secuencial.
  static Future<int> getAndUpdateFolio() async {
    try {
      return await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final docRef = FirebaseFirestore.instance
            .collection(_collection)
            .doc(_document);
        final snapshot = await transaction.get(docRef);
        final ultimoFolio = snapshot.data()?[_field] as int? ?? _defaultFolio;
        final nuevoFolio = ultimoFolio + 1;
        transaction.set(docRef, {_field: nuevoFolio}, SetOptions(merge: true));
        _logger.i(
          '[FolioService] getAndUpdateFolio: Folio actualizado a $nuevoFolio',
        );
        return nuevoFolio;
      });
    } catch (e, stack) {
      _logger.e(
        '[FolioService] Error en getAndUpdateFolio',
        error: e,
        stackTrace: stack,
      );
      // Devuelve el default en caso de error
      return _defaultFolio + 1;
    }
  }
}
