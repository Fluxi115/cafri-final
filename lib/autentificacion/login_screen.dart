// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cafri/autentificacion/auth_service.dart';
import 'package:cafri/administrador/admin_screen.dart';
import 'package:cafri/colaborador/colaborador_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool isPasswordHidden = true;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Simula un splash de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? result = await _authService.loginUser(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result == 'administrador') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      } else if (result == 'colaborador') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ColaboradorScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: $result')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ocurrió un error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showSplash
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 29, 77, 235),
                    Color.fromARGB(255, 0, 0, 0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(92, 29, 77, 235),
                  ),
                  strokeWidth: 5,
                ),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 29, 77, 235),
                    Color.fromARGB(255, 0, 0, 0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              "lib/assets/cafrilogo.png",
                              height: 90,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Bienvenido a CAFRI",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 0, 0),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.email),
                              filled: true,
                              fillColor: Colors.blueGrey[50],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: isPasswordHidden,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPasswordHidden = !isPasswordHidden;
                                  });
                                },
                                icon: Icon(
                                  isPasswordHidden
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.blueGrey[50],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      backgroundColor: const Color(0xFF2193b0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 6,
                                    ),
                                    child: const Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 18),
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
