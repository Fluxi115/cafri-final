// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClienteEditarScreen extends StatefulWidget {
  final String clienteId;
  final Map<String, dynamic> clienteData;

  const ClienteEditarScreen({
    super.key,
    required this.clienteId,
    required this.clienteData,
  });

  @override
  State<ClienteEditarScreen> createState() => _ClienteEditarScreenState();
}

class _ClienteEditarScreenState extends State<ClienteEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.clienteData['nombre'] ?? '',
    );
    _direccionController = TextEditingController(
      text: widget.clienteData['direccion'] ?? '',
    );
    _ciudadController = TextEditingController(
      text: widget.clienteData['ciudad'] ?? '',
    );
    _telefonoController = TextEditingController(
      text: widget.clienteData['telefono'] ?? '',
    );
    _correoController = TextEditingController(
      text: widget.clienteData['correo'] ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  String? _validateNotEmpty(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio';
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) return 'Teléfono es obligatorio';
    if (!RegExp(r'^\d{7,}$').hasMatch(value.trim())) return 'Teléfono inválido';
    return null;
  }

  String? _validateCorreo(String? value) {
    if (value == null || value.trim().isEmpty) return 'Correo es obligatorio';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) return 'Correo inválido';
    return null;
  }

  Future<void> _actualizarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .update({
            'nombre': _nombreController.text.trim(),
            'direccion': _direccionController.text.trim(),
            'ciudad': _ciudadController.text.trim(),
            'telefono': _telefonoController.text.trim(),
            'correo': _correoController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cliente actualizado exitosamente!')),
      );
      Navigator.pop(context, true); // true para indicar que hubo actualización
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar cliente: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Cliente')),
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
                      controller: _nombreController,
                      validator: (v) => _validateNotEmpty(v, 'Nombre'),
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _direccionController,
                      validator: (v) => _validateNotEmpty(v, 'Dirección'),
                      decoration: const InputDecoration(labelText: 'Dirección'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ciudadController,
                      validator: (v) => _validateNotEmpty(v, 'Ciudad'),
                      decoration: const InputDecoration(labelText: 'Ciudad'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefonoController,
                      validator: _validateTelefono,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _correoController,
                      validator: _validateCorreo,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _actualizarCliente,
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
