// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:cafri/administrador/cotizacion/cotizacion_editar.dart';

class HistorialCotizacionesScreen extends StatefulWidget {
  const HistorialCotizacionesScreen({super.key});

  @override
  State<HistorialCotizacionesScreen> createState() =>
      _HistorialCotizacionesScreenState();
}

class _HistorialCotizacionesScreenState
    extends State<HistorialCotizacionesScreen> {
  // DateTime? _fechaInicio; // <-- Descomenta si quieres activar el filtro de fecha
  // DateTime? _fechaFin;

  @override
  Widget build(BuildContext context) {
    Query cotizacionesQuery = FirebaseFirestore.instance.collection(
      'cotizaciones',
    );

    // Filtro por fecha (Comenta o descomenta estas líneas según necesidad)
    /*
    if (_fechaInicio != null) {
      cotizacionesQuery = cotizacionesQuery.where(
        'fecha',
        isGreaterThanOrEqualTo: _fechaInicio!.toString().substring(0, 10),
      );
    }
    if (_fechaFin != null) {
      cotizacionesQuery = cotizacionesQuery.where(
        'fecha',
        isLessThanOrEqualTo: _fechaFin!.toString().substring(0, 10),
      );
    }
    */
    cotizacionesQuery = cotizacionesQuery.orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Cotizaciones')),
      body: Column(
        children: [
          // Filtros de fechas (coméntalo todo si no deseas mostrarlo)
          /*
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaInicio ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _fechaInicio = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha inicio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        _fechaInicio == null
                            ? ''
                            : _fechaInicio!.toString().substring(0, 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaFin ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _fechaFin = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha fin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        _fechaFin == null
                            ? ''
                            : _fechaFin!.toString().substring(0, 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          */
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: cotizacionesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error en la consulta: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No hay cotizaciones encontradas.'),
                  );
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final total = data['total'] ?? 0.0;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('Folio: ${data['folio']}'),
                            subtitle: Text(
                              'Fecha: ${data['fecha'] ?? ''}\nCliente: ${data['cliente']?['nombre'] ?? ''}',
                            ),
                            trailing: Text('\$${total.toStringAsFixed(2)}'),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // BOTÓN EDITAR
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Editar cotización',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CotizacionEditarScreen(
                                        cotizacionId: doc.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // BOTÓN ELIMINAR
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Eliminar cotización',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text(
                                        '¿Eliminar cotización?',
                                      ),
                                      content: const Text(
                                        '¿Seguro que quieres borrar esta cotización? Esta acción no se puede deshacer.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await doc.reference.delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cotización eliminada'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              // BOTÓN PDF
                              IconButton(
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                ),
                                tooltip: 'Imprimir o descargar PDF',
                                onPressed: () async =>
                                    await _generarYMostrarPDF(data),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Genera y muestra el PDF de una cotización usando los datos de Firestore
  /// Genera y muestra el PDF de una cotización usando los datos completos de Firestore.
  /// Agrega logo (si tienes el asset en 'assets/logo.png') y una tabla detallada de productos/servicios.
  Future<void> _generarYMostrarPDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Lee logo local si existe (pon tu logo en assets/logo.png y agrégalo al pubspec.yaml)
    pw.MemoryImage? logoImage;
    try {
      final bytes = await rootBundle.load(
        'lib/assets/cafrilogo.png',
      ); // Cambia la ruta si la tuya es diferente
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // LOGO Y EMPRESA
              pw.Row(
                children: [
                  if (logoImage != null)
                    pw.Container(
                      height: 60,
                      width: 60,
                      margin: const pw.EdgeInsets.only(right: 16),
                      child: pw.Image(logoImage),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CAFRI',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      pw.Text(
                        "C. 59k N°518 X 112 Y 114 Col. Bojorquez Cp. 97230",
                      ),
                      pw.Text("Mérida"),
                      pw.Text("Teléfono: 999-192-123-2"),
                      pw.Text("Email: facturaciones@cafrimx.com"),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Cotización',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text('Folio: ${data['folio'] ?? '-'}'),
                      pw.Text('Fecha: ${data['fecha'] ?? '-'}'),
                    ],
                  ),
                ],
              ),
              pw.Divider(),
              pw.Text(
                'Cliente',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              pw.Text('Nombre: ${data['cliente']?['nombre'] ?? '-'}'),
              pw.Text('Email: ${data['cliente']?['email'] ?? '-'}'),
              pw.Text('Dirección: ${data['cliente']?['direccion'] ?? '-'}'),
              pw.Text('Ciudad: ${data['cliente']?['ciudad'] ?? '-'}'),
              pw.Text('Teléfono: ${data['cliente']?['telefono'] ?? '-'}'),
              pw.SizedBox(height: 12),
              pw.Text(
                'Productos/Servicios',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 8),
              if (data.containsKey('items') &&
                  data['items'] is List &&
                  (data['items'] as List).isNotEmpty)
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Código',
                    'Descripción',
                    'Cantidad',
                    'Precio',
                    'Subtotal',
                    'Impuesto',
                    'Total',
                  ],
                  data: (data['items'] as List)
                      .map(
                        (item) => [
                          item['codigo'] ?? '',
                          item['descripcion'] ?? '',
                          item['cantidad'].toString(),
                          '\$${(item['precio'] is num ? item['precio'].toStringAsFixed(2) : (item['precio'] ?? "0.00"))}',
                          '\$${(item['subtotal'] is num ? item['subtotal'].toStringAsFixed(2) : (item['subtotal'] ?? '0.00'))}',
                          '${((item['impuesto'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                          '\$${(item['total'] is num ? item['total'].toStringAsFixed(2) : (item['total'] ?? '0.00'))}',
                        ],
                      )
                      .toList(),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration: pw.BoxDecoration(color: PdfColors.blue700),
                )
              else
                pw.Text("No hay productos/servicios registrados."),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Subtotal: \$${(data['subtotal'] ?? 0.0).toStringAsFixed(2)}',
                      ),
                      pw.Text(
                        'Impuestos: \$${(data['totalImpuestos'] ?? 0.0).toStringAsFixed(2)}',
                      ),
                      pw.Text(
                        'Total: \$${(data['total'] ?? 0.0).toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Términos y condiciones:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('1.- Todo costo del servicio incluye IVA.'),
              pw.Text('2.- Los pagos son por medio de transferencia.'),
              pw.Text(
                '3.- Todo servicio es realizado con el 50% de anticipo del servicio.',
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Si usted tiene alguna pregunta sobre esta cotización, por favor, póngase en contacto con nosotros',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'CAFRI | Teléfono: 99-91-02-12-32 | E-mail: facturaciones@cafrimx.com',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'En Frio y Confort "CAFRI es la Solución"',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
