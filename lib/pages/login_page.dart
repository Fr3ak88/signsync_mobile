import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _doLogin() async {
    if (_isLoading) return;

    // Einfache Validierung
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Bitte E-Mail und Passwort eingeben.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        // Navigiert zur HomePage und entfernt den Login-Stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else {
        _showError('Login fehlgeschlagen. Bitte Daten prüfen.');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Verbindungsfehler zum Server.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      appBar: AppBar(
        title: const Text('SignSync'),
        elevation: 0,
        backgroundColor: Colors.white, 
        foregroundColor: Colors.black87, // Schriftfarbe der AppBar auf dunkel gesetzt, da Hintergrund weiß ist
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // NEU: Das Logo wird hier geladen
                ClipRRect(
                  borderRadius: BorderRadius.circular(16), // Macht die Ecken leicht rund
                  child: Image.asset(
                    'assets/icon/app_icon.png', // Dein Bildpfad
                    height: 120, // Größe des Logos
                    fit: BoxFit.cover,
                    // Fallback, falls das Bild beim Entwickeln nicht gefunden wird:
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle, 
                      size: 100, 
                      color: Color(0xFF4466F2)
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                const Text(
                  'Willkommen zurück',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Passwort',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF4466F2))
                    : ElevatedButton(
                        onPressed: _doLogin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(55),
                          backgroundColor: const Color(0xFF4466F2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Anmelden',
                            style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}