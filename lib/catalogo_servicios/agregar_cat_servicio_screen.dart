// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicioCreateScreen extends StatefulWidget {
  const ServicioCreateScreen({super.key});

  @override
  State<ServicioCreateScreen> createState() => _ServicioCreateScreenState();
}

class _ServicioCreateScreenState extends State<ServicioCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _conceptoController = TextEditingController();
  final _precioController = TextEditingController();

  bool _isLoading = false;
  String? _codigoError;

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

  Future<bool> _codigoYaExiste(String codigo) async {
    final query = await FirebaseFirestore.instance
        .collection('servicios')
        .where('codigo', isEqualTo: codigo.trim())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> _registrarServicio() async {
    setState(() {
      _codigoError = null;
    });

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final codigo = _codigoController.text.trim();

    // Validar que el código no exista
    if (await _codigoYaExiste(codigo)) {
      setState(() {
        _isLoading = false;
        _codigoError = 'Este servicio ya está registrado';
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('servicios').add({
        'codigo': codigo,
        'concepto': _conceptoController.text.trim(),
        'precioMenudeo': double.parse(
          _precioController.text.replaceAll(',', '.'),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Servicio registrado exitosamente!')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar servicio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(
        (0.2 * 255).toInt(),
      ),
      appBar: AppBar(
        title: const Text('Registrar Servicio'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 28,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nuevo Servicio',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _codigoController,
                        validator: (v) => _validateNotEmpty(v, 'Código'),
                        decoration: InputDecoration(
                          labelText: 'Código',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.confirmation_number),
                          errorText: _codigoError,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _conceptoController,
                        validator: (v) => _validateNotEmpty(v, 'Concepto'),
                        decoration: const InputDecoration(
                          labelText: 'Concepto del servicio',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _precioController,
                        validator: _validatePrecio,
                        decoration: const InputDecoration(
                          labelText: 'Precio menudeo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text(
                                  'Registrar Servicio',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _registrarServicio,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
