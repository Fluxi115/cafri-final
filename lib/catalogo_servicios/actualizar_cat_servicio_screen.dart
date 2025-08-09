// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicioEditarScreen extends StatefulWidget {
  final String servicioId;
  final Map<String, dynamic> servicioData;

  const ServicioEditarScreen({
    super.key,
    required this.servicioId,
    required this.servicioData,
  });

  @override
  State<ServicioEditarScreen> createState() => _ServicioEditarScreenState();
}

class _ServicioEditarScreenState extends State<ServicioEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _conceptoController;
  late final TextEditingController _precioController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(
      text: widget.servicioData['codigo'] ?? '',
    );
    _conceptoController = TextEditingController(
      text: widget.servicioData['concepto'] ?? '',
    );
    _precioController = TextEditingController(
      text: (widget.servicioData['precioMenudeo'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _conceptoController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  String? _validateNotEmpty(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio';
    return null;
  }

  String? _validatePrecio(String? value) {
    if (value == null || value.trim().isEmpty) return 'Precio es obligatorio';
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 'Precio inválido';
    return null;
  }

  Future<void> _actualizarServicio() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('servicios')
          .doc(widget.servicioId)
          .update({
            'codigo': _codigoController.text.trim(),
            'concepto': _conceptoController.text.trim(),
            'precioMenudeo': double.parse(
              _precioController.text.replaceAll(',', '.'),
            ),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Servicio actualizado exitosamente!')),
      );
      Navigator.pop(context, true); // true para indicar que hubo actualización
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar servicio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Servicio')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codigoController,
                      validator: (v) => _validateNotEmpty(v, 'Código'),
                      decoration: const InputDecoration(labelText: 'Código'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _conceptoController,
                      validator: (v) => _validateNotEmpty(v, 'Concepto'),
                      decoration: const InputDecoration(
                        labelText: 'Concepto del servicio',
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _precioController,
                      validator: _validatePrecio,
                      decoration: const InputDecoration(
                        labelText: 'Precio menudeo',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _actualizarServicio,
                            child: const Text('Guardar Cambios'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
