// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClienteCreateScreen extends StatefulWidget {
  const ClienteCreateScreen({super.key});

  @override
  State<ClienteCreateScreen> createState() => _ClienteCreateScreenState();
}

class _ClienteCreateScreenState extends State<ClienteCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingCodigo = true;

  @override
  void initState() {
    super.initState();
    _generarCodigoCliente();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _generarCodigoCliente() async {
    // Busca el último código generado en la colección
    final snapshot = await FirebaseFirestore.instance
        .collection('clientes')
        .orderBy('codigo', descending: true)
        .limit(1)
        .get();

    String nuevoCodigo;
    if (snapshot.docs.isNotEmpty) {
      final ultimoCodigo = snapshot.docs.first['codigo'] ?? '';
      // Extrae el número del código (ej: CLI001 -> 1)
      final match = RegExp(r'^CLI(\d+)$').firstMatch(ultimoCodigo);
      int siguiente = 1;
      if (match != null) {
        siguiente = int.parse(match.group(1)!) + 1;
      }
      nuevoCodigo = 'CLI${siguiente.toString().padLeft(3, '0')}';
    } else {
      nuevoCodigo = 'CLI001';
    }
    _codigoController.text = nuevoCodigo;
    setState(() {
      _isLoadingCodigo = false;
    });
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

  Future<void> _registrarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('clientes')
          .add({
            'codigo': _codigoController.text.trim(),
            'nombre': _nombreController.text.trim(),
            'direccion': _direccionController.text.trim(),
            'ciudad': _ciudadController.text.trim(),
            'telefono': _telefonoController.text.trim(),
            'correo': _correoController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Cliente registrado exitosamente! ID: ${docRef.id}'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar cliente: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Cliente')),
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
                    // Campo de código autogenerado, solo lectura
                    TextFormField(
                      controller: _codigoController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Código de Cliente',
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingCodigo)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      ),
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
                            onPressed: _isLoadingCodigo
                                ? null
                                : _registrarCliente,
                            child: const Text('Registrar Cliente'),
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
