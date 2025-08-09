// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class CotizacionesListarScreen extends StatelessWidget {
  const CotizacionesListarScreen({super.key});

  Future<void> _descargarPDF(
    BuildContext context,
    Map<String, dynamic> cotizacion,
  ) async {
    final pdf = pw.Document();

    // Cargar imágenes si existen (ajusta la ruta si es necesario)
    final logoBytes = await DefaultAssetBundle.of(
      context,
    ).load('lib/assets/cafrilogo.png');
    final firmaBytes = await DefaultAssetBundle.of(
      context,
    ).load('lib/assets/firma.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final firmaImage = pw.MemoryImage(firmaBytes.buffer.asUint8List());

    final cliente = cotizacion['cliente'] ?? {};
    final empresa = cotizacion['empresa'] ?? {};
    final items = List<Map<String, dynamic>>.from(cotizacion['items'] ?? []);

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(width: 80, height: 80, child: pw.Image(logoImage)),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(empresa['direccion'] ?? ''),
                    pw.Text("Ciudad: ${empresa['ciudad'] ?? ''}"),
                    pw.Text("Sitio web: ${empresa['sitioWeb'] ?? ''}"),
                    pw.Text("Teléfono: ${empresa['telefono'] ?? ''}"),
                    pw.Text("E-mail: ${empresa['email'] ?? ''}"),
                    pw.Text("Responsable: ${empresa['responsable'] ?? ''}"),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Fecha: ${cotizacion['fecha'] ?? ''}"),
                  pw.Text("Folio: ${cotizacion['folio'] ?? ''}"),
                  pw.Text("Cliente ID: ${cotizacion['clienteId'] ?? ''}"),
                  pw.Text("Válido hasta: ${cotizacion['validoHasta'] ?? ''}"),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.Text(
            "Cliente",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text("Nombre: ${cliente['nombre'] ?? ''}"),
          pw.Text("Email: ${cliente['email'] ?? ''}"),
          pw.Text("Dirección: ${cliente['direccion'] ?? ''}"),
          pw.Text("Ciudad: ${cliente['ciudad'] ?? ''}"),
          pw.Text("Teléfono: ${cliente['telefono'] ?? ''}"),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.Text(
            "Productos/Servicios",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
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
            data: items
                .map(
                  (item) => [
                    item['codigo'] ?? '',
                    item['descripcion'] ?? '',
                    '${item['cantidad'] ?? ''}',
                    '\$${(item['precio'] ?? 0).toStringAsFixed(2)}',
                    '\$${(item['subtotal'] ?? 0).toStringAsFixed(2)}',
                    '\$${((item['subtotal'] ?? 0) * (item['impuesto'] ?? 0)).toStringAsFixed(2)}',
                    '\$${(item['total'] ?? 0).toStringAsFixed(2)}',
                  ],
                )
                .toList(),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue50),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Subtotal: \$${(cotizacion['subtotal'] ?? 0).toStringAsFixed(2)}',
                  ),
                  pw.Text(
                    'Impuestos: \$${(cotizacion['totalImpuestos'] ?? 0).toStringAsFixed(2)}',
                  ),
                  pw.Text(
                    'Total: \$${(cotizacion['total'] ?? 0).toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Términos y condiciones',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('1.- Todo costo del servicio incluye IVA.'),
                    pw.Text('2.- Los pagos son por medio de transferencia.'),
                    pw.Text(
                      '3.- Todo servicio es realizado con el 50% de anticipo del servicio.',
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 120,
                      height: 40,
                      child: pw.Image(firmaImage),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'FIRMA DE ENCARGADA',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
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
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotizaciones Guardadas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cotizaciones')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay cotizaciones guardadas.'));
          }
          final cotizaciones = snapshot.data!.docs;
          return ListView.separated(
            itemCount: cotizaciones.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final cotizacion =
                  cotizaciones[index].data() as Map<String, dynamic>;
              final folio = cotizacion['folio'] ?? '';
              final fecha = cotizacion['fecha'] ?? '';
              final cliente = cotizacion['cliente']?['nombre'] ?? '';
              final total = cotizacion['total'] ?? 0.0;
              return ListTile(
                title: Text('Folio: $folio'),
                subtitle: Text('Fecha: $fecha\nCliente: $cliente'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\$${total.toStringAsFixed(2)}'),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      tooltip: 'Descargar PDF',
                      onPressed: () => _descargarPDF(context, cotizacion),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
