import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'inicio_screen.dart';
import 'registro_perfil_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  bool _modoRegistro = false; // alterna entre Login y Registro

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // ── Iniciar sesión ──────────────────────────────────────────────────────────
  Future<void> _iniciarSesion() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _mostrarError('Por favor completa todos los campos');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InicioScreen()),
        );
      }
    } on AuthException catch (e) {
      _mostrarError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Registrarse ─────────────────────────────────────────────────────────────
  Future<void> _registrarse() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _mostrarError('Por favor completa todos los campos');
      return;
    }
    if (_passController.text.length < 6) {
      _mostrarError('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      if (res.user != null && mounted) {
        // Va a completar el perfil médico
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegistroPerfilScreen()),
        );
      }
    } on AuthException catch (e) {
      _mostrarError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB2EBF2), Color(0xFFE0F7FA)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      size: 48,
                      color: Color(0xFF00BCD4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MedFind',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00BCD4),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    _modoRegistro ? 'Crea tu cuenta' : 'Bienvenido de vuelta',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 28),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Contraseña
                  TextField(
                    controller: _passController,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_modoRegistro ? _registrarse : _iniciarSesion),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _modoRegistro ? 'Crear Cuenta' : 'Iniciar Sesión',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Alternar modo
                  TextButton(
                    onPressed: () =>
                        setState(() => _modoRegistro = !_modoRegistro),
                    child: Text(
                      _modoRegistro
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Regístrate',
                      style: const TextStyle(color: Color(0xFF00BCD4)),
                    ),
                  ),

                  if (!_modoRegistro)
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}