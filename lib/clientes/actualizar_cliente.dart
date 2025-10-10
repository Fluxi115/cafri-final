import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore_for_file: use_build_context_synchronously

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

  // Persona y Empresa comparten "nombre" y "telefono"
  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;

  // Solo persona
  late final TextEditingController _direccionController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _correoController;

  // Solo empresa
  late final TextEditingController _razonSocialController;
  late final TextEditingController _rfcController;

  bool _isLoading = false;

  bool get _isEmpresa =>
      (widget.clienteData['tipo'] ?? '').toString().toLowerCase() == 'empresa';

  @override
  void initState() {
    super.initState();

    // Comunes
    _nombreController = TextEditingController(
      text: (widget.clienteData['nombre'] ?? '').toString(),
    );
    _telefonoController = TextEditingController(
      text: (widget.clienteData['telefono'] ?? '').toString(),
    );

    // Persona
    _direccionController = TextEditingController(
      text: (widget.clienteData['direccion'] ?? '').toString(),
    );
    _ciudadController = TextEditingController(
      text: (widget.clienteData['ciudad'] ?? '').toString(),
    );
    _correoController = TextEditingController(
      text: (widget.clienteData['correo'] ?? '').toString(),
    );

    // Empresa
    _razonSocialController = TextEditingController(
      text: (widget.clienteData['razon_social'] ?? '').toString(),
    );
    _rfcController = TextEditingController(
      text: (widget.clienteData['rfc'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();

    _direccionController.dispose();
    _ciudadController.dispose();
    _correoController.dispose();

    _razonSocialController.dispose();
    _rfcController.dispose();
    super.dispose();
  }

  // Validaciones
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

  // RFC MX: validación sencilla 12-13 alfanuméricos
  String? _validateRFC(String? value) {
    if (value == null || value.trim().isEmpty) return 'RFC es obligatorio';
    final v = value.trim().toUpperCase();
    if (!RegExp(r'^[A-ZÑ&0-9]{12,13}$').hasMatch(v)) return 'RFC inválido';
    return null;
  }

  Future<void> _actualizarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'telefono': _telefonoController.text.trim(),
        'nombre': _nombreController.text
            .trim(), // Para empresa es "Nombre de la empresa"
      };

      if (_isEmpresa) {
        updates['razon_social'] = _razonSocialController.text.trim();
        updates['rfc'] = _rfcController.text.trim().toUpperCase();
        // Para empresa no tocamos direccion/ciudad/correo (si existen, se dejan como están)
      } else {
        updates['direccion'] = _direccionController.text.trim();
        updates['ciudad'] = _ciudadController.text.trim();
        updates['correo'] = _correoController.text.trim();
        // Para persona no tocamos razon_social/rfc (si existen, se dejan como están)
      }

      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .update(updates);

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cliente actualizado exitosamente!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar cliente: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpresa = _isEmpresa;

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
                    // Nombre (persona) o Nombre de la empresa (empresa)
                    TextFormField(
                      controller: _nombreController,
                      validator: (v) => _validateNotEmpty(
                        v,
                        isEmpresa ? 'Nombre de la empresa' : 'Nombre',
                      ),
                      decoration: InputDecoration(
                        labelText: isEmpresa
                            ? 'Nombre de la empresa'
                            : 'Nombre',
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!isEmpresa) ...[
                      TextFormField(
                        controller: _direccionController,
                        validator: (v) => _validateNotEmpty(v, 'Dirección'),
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ciudadController,
                        validator: (v) => _validateNotEmpty(v, 'Ciudad'),
                        decoration: const InputDecoration(labelText: 'Ciudad'),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      TextFormField(
                        controller: _razonSocialController,
                        validator: (v) => _validateNotEmpty(v, 'Razón social'),
                        decoration: const InputDecoration(
                          labelText: 'Razón social',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _rfcController,
                        validator: _validateRFC,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'RFC'),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Teléfono (común)
                    TextFormField(
                      controller: _telefonoController,
                      validator: _validateTelefono,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    if (!isEmpresa)
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
