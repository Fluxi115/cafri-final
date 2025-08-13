// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CotizacionEditarScreen extends StatefulWidget {
  final String cotizacionId;
  const CotizacionEditarScreen({super.key, required this.cotizacionId});

  @override
  State<CotizacionEditarScreen> createState() => _CotizacionEditarScreenState();
}

class _CotizacionEditarScreenState extends State<CotizacionEditarScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCotizacion();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _loadCotizacion() async {
    final doc = await FirebaseFirestore.instance
        .collection('cotizaciones')
        .doc(widget.cotizacionId)
        .get();
    if (!doc.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cotización no encontrada')));
      Navigator.of(context).pop();
      return;
    }
    final data = doc.data()!;
    setState(() {
      _items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _clienteController.text = data['cliente']?['nombre'] ?? '';
      _fechaController.text = data['fecha'] ?? '';
      _loading = false;
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance
          .collection('cotizaciones')
          .doc(widget.cotizacionId)
          .update({
            'cliente.nombre': _clienteController.text,
            'fecha': _fechaController.text,
            'items': _items,
            // Puedes agregar aquí recálculo de subtotal/total si editas productos/precios
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotización editada correctamente')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  void _editarProducto(int index) async {
    final item = _items[index];
    final TextEditingController descController = TextEditingController(
      text: item['descripcion'] ?? '',
    );
    final TextEditingController cantController = TextEditingController(
      text: item['cantidad']?.toString() ?? '',
    );
    final TextEditingController precioController = TextEditingController(
      text: item['precio']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Editar producto/servicio"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: cantController,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: precioController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                final nuevaDesc = descController.text.trim();
                final nuevaCant = int.tryParse(cantController.text) ?? 1;
                final nuevoPrecio =
                    double.tryParse(
                      precioController.text.replaceAll(',', '.'),
                    ) ??
                    0.0;
                setState(() {
                  _items[index] = {
                    ...item,
                    'descripcion': nuevaDesc,
                    'cantidad': nuevaCant,
                    'precio': nuevoPrecio,
                    'subtotal': nuevaCant * nuevoPrecio,
                    'total':
                        (nuevaCant * nuevoPrecio) *
                        (1 + (item['impuesto'] ?? 0)),
                  };
                });
                Navigator.of(context).pop();
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _eliminarProducto(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Cotización')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _clienteController,
                decoration: const InputDecoration(labelText: 'Cliente'),
                validator: (v) => v!.isEmpty ? 'Ingresa el cliente' : null,
              ),
              TextFormField(
                controller: _fechaController,
                decoration: const InputDecoration(labelText: 'Fecha'),
                validator: (v) => v!.isEmpty ? 'Ingresa la fecha' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Productos/Servicios:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Card(
                  child: ListTile(
                    title: Text(item['descripcion'] ?? ''),
                    subtitle: Text(
                      'Cantidad: ${item['cantidad']}, Precio: \$${item['precio']}, Total: \$${item['total']?.toStringAsFixed(2) ?? '0'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editarProducto(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarProducto(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _guardarCambios,
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
