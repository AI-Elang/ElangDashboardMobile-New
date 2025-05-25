import 'package:elang_dashboard_new_ui/services/update_service.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final UpdateService _updateService = UpdateService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  var user = 4;
  var pass = 4;
  var baseURL = dotenv.env['baseURL'];

  bool _obscurePassword = true;
  bool _isCheckingUpdate = true;
  bool _rememberMe = false;
  bool _locationSent = false;

  Position? _lastKnownGoodPosition;

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);

    try {
      await _updateService.startUpdateCheck(context);
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Future<void> _checkForStoredCredentials() async {
    const secureStorage = FlutterSecureStorage();
    final storedUsername = await secureStorage.read(key: 'username');
    final storedPassword = await secureStorage.read(key: 'password');
    final rememberMe = await secureStorage.read(key: 'remember_me');

    // Pre-fill form with stored credentials if they exist
    if (storedUsername != null) {
      setState(() {
        _usernameController.text = storedUsername;
      });
    }

    if (storedPassword != null) {
      setState(() {
        _passwordController.text = storedPassword;
      });
    }

    // Set remember me checkbox state - always respect the stored preference
    setState(() {
      _rememberMe = rememberMe == 'true';
    });

    // Only auto-login if remember_me is true AND user didn't explicitly logout
    if (rememberMe == 'true' &&
        storedUsername != null &&
        storedPassword != null) {
      await _login();
    }
  }

  Future<bool> _isMockLocation(Position position) async {
    // Direct check for mock location
    if (position.isMocked) {
      return true;
    }

    // Additional checks for suspicious location data
    if (position.accuracy <= 0 || position.accuracy > 100) {
      return true;
    }

    // Store valid location as reference point
    _lastKnownGoodPosition ??= position;

    return false;
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Force open location settings
        await Geolocator.openLocationSettings();
        // Wait briefly for user to enable location
        await Future.delayed(const Duration(seconds: 3));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return null;
        }
      }

      // Request location permissions if needed
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Check for mock location
      bool isMocked = await _isMockLocation(position);
      if (isMocked) {
        // Return previously stored good location if available
        return _lastKnownGoodPosition;
      }

      // Store this as a good location reference
      _lastKnownGoodPosition = position;
      return position;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error getting location data'),
        ),
      );
      return null;
    }
  }

  Future<void> _sendLocationData(String? token) async {
    // Only send once per login session
    if (_locationSent) {
      return;
    }

    final position = await _getCurrentLocation();
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get location data'),
        ),
      );
      return;
    }

    try {
      final url = Uri.parse('$baseURL/api/v1/activity-logs');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'type': 'login',
        }),
      );

      // Mark as sent to prevent duplicate submissions
      _locationSent = true;

      if (response.statusCode == 200) {
        debugPrint('Location data sent successfully');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send location data'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send location data'),
        ),
      );
    }
  }

  Future<void> _stopLocationServices() async {
    // Cancel location stream
    await Geolocator.getPositionStream().listen(null).cancel();

    // Clear stored location data
    _lastKnownGoodPosition = null;

    // Reset location sent flag
    _locationSent = false;
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Username dan Password harus diisi');
      return;
    }

    if (_usernameController.text.length < user) {
      _showErrorDialog('Username harus memiliki minimal $user karakter');
      return;
    }

    if (_passwordController.text.length < pass) {
      _showErrorDialog('Password harus memiliki minimal $pass karakter');
      return;
    }

    // Store or clear credentials based on remember me checkbox
    const secureStorage = FlutterSecureStorage();
    if (_rememberMe) {
      // If checked, save credentials and set remember_me flag
      await Provider.of<AuthProvider>(context, listen: false)
          .saveCredentials(_usernameController.text, _passwordController.text);
    } else {
      // If not checked, clear credentials but explicitly set remember_me to false
      // This ensures we track the user's preference
      await secureStorage.delete(key: 'username');
      await secureStorage.delete(key: 'password');
      await secureStorage.write(key: 'remember_me', value: 'false');
    }

    final url = Uri.parse('$baseURL/api/v1/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['meta']['success']) {
          final token = data['token'];
          final username = data['data']['username'];
          final territory = data['data']['territory'];
          final role = data['data']['role'];
          final brand = data['data']['brand'];

          await _sendLocationData(token);

          // Save user data
          await Provider.of<AuthProvider>(context, listen: false)
              .setUserData(token, username, territory, role, 1, brand);

          // If role is between 1 and 5, fetch locked dropdown data
          if (role >= 1 && role <= 5) {
            await Provider.of<AuthProvider>(context, listen: false)
                .fetchLockedDropdown();
          }

          // Navigate to Homepage
          await _stopLocationServices();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Homepage(),
            ),
          );
        } else {
          _showErrorDialog(data['meta']['error']);
        }
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        String errorMessage = '';

        if (data['meta']['error']['username'] != null) {
          errorMessage += data['meta']['error']['username'].join(', ') + '\n';
        }

        if (data['meta']['error']['password'] != null) {
          errorMessage += data['meta']['error']['password'].join(', ') + '\n';
        }
        _showErrorDialog(errorMessage.trim());
      } else {
        final data = jsonDecode(response.body);
        _showErrorDialog(data['meta']['message']);
      }
    } catch (e) {
      _showErrorDialog('Ada Kesalahan.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Gagal'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForUpdates();
    _checkForStoredCredentials();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateService.stopUpdateCheck();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateService.triggerUpdateCheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define a color scheme for the login page
    const primaryColor = Color(0xFF3F51B5); // Indigo
    const accentColor = Color(0xFF03A9F4); // Light Blue
    const backgroundColor = Color(0xFFF5F5F7);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundColor, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and login form - existing code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Image(
                        image: AssetImage('assets/LOGO3.png'),
                        width: 80,
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Welcome text
                    const Text(
                      'Elang Dashboard',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Card
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Username field
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: const Icon(Icons.person_outline,
                                      color: primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16.0, horizontal: 16.0),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: primaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16.0, horizontal: 16.0),
                                ),
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Remember me checkbox - properly aligned
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: accentColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Remember Me',
                                      style: TextStyle(
                                        color: Color(0xFF757575),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Login button
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    _login();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (_isCheckingUpdate)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
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
