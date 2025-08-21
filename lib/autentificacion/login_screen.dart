// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cafri/autentificacion/auth_service.dart';
import 'package:cafri/administrador/admin_screen.dart';
import 'package:cafri/colaborador/colaborador_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool isPasswordHidden = true;
  bool _showSplash = true;
  String? _error;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutExpo),
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    // Splash: show for 1.4s, fade out on 0.7s animation.
    Future.delayed(const Duration(milliseconds: 1250), () {
      _animController.forward().then((_) {
        setState(() {
          _showSplash = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = "Por favor, completa todos los campos");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? result = await _authService.loginUser(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() => _isLoading = false);
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
        setState(() => _error = 'Error al iniciar sesión: $result');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ocurrió un error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1d4deb), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Splash animado con logo
          if (_showSplash)
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Center(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 72,
                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.asset(
                                "lib/assets/cafrilogo.png",
                                fit: BoxFit.contain,
                                height: 85,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            "CAFRI",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 4,
                              fontFamily: 'Arial',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          if (!_showSplash)
            Center(
              child: SingleChildScrollView(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: Card(
                      color: Colors.white.withAlpha((0.55 * 255).toInt()),
                      elevation: 16,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  "lib/assets/cafrilogo.png",
                                  fit: BoxFit.contain,
                                  height: 50,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              "Bienvenido a CAFRI",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[900],
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_error != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(
                                    (0.14 * 255).toInt(),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: Colors.white.withAlpha(
                                  (0.9 * 255).toInt(),
                                ),
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
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => isPasswordHidden = !isPasswordHidden,
                                  ),
                                  icon: Icon(
                                    isPasswordHidden
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withAlpha(
                                  (0.9 * 255).toInt(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
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
                                        backgroundColor: const Color(
                                          0xFF2193b0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 8,
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
            ),
        ],
      ),
    );
  }
}
