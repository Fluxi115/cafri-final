import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

Future<String> subirPdfTarea(Uint8List pdfBytes, int folio) async {
  try {
    final ref = FirebaseStorage.instance.ref('pdfs/tareas/Tarea_$folio.pdf');
    await ref.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    return await ref.getDownloadURL();
  } on FirebaseException catch (e) {
    throw Exception('Error subiendo PDF: ${e.code} - ${e.message}');
  }
}
