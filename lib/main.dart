import 'package:flutter/material.dart';
import 'api_service.dart';

void main() {
  runApp(const SignSyncApp());
}

class SignSyncApp extends StatelessWidget {
  const SignSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignSync',
      debugShowCheckedModeBanner: false, // Entfernt das Banner oben rechts
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// --- LOGIN SCREEN ---
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
    // Verhindert mehrfaches Klicken
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final success = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Falls der User den Screen während des Wartens verlassen hat
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        // DER ENTSCHEIDENDE WECHSEL:
        // Wir nutzen hier eine Callback-Funktion, um sicherzugehen, dass
        // die UI bereit für den Wechsel ist.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) =>
                false, // Entfernt alle vorherigen Screens (Login) aus dem Stack
          );
        });
      } else {
        _showError('Login fehlgeschlagen. Daten prüfen.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Verbindungsfehler zum Server.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SignSync Login')),
      body: Center(
        // Center sorgt für bessere Optik im Web
        child: Container(
          constraints:
              const BoxConstraints(maxWidth: 400), // Begrenzt Breite im Browser
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock_outlined,
                  size: 80, color: Colors.blue),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
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
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _doLogin,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Anmelden',
                          style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HOME SCREEN (DASHBOARD) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SignSync Dashboard'),
        backgroundColor: Colors.blue.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Erfolgreich angemeldet!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hier kommen bald die Schüler-Listen hin.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
