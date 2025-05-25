import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

var baseURL = dotenv.env['baseURL'];

class AuthProvider with ChangeNotifier {
  String _token = '';
  String _username = '';
  String _territory = '';
  String _brand = '';
  int _role = 0;
  int _circle = 0;
  int _region = 0;
  int _area = 0;
  int _branch = 0;
  int _mc = 0;
  String? _error; // Add error state

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Getter for error messages
  String? get error => _error;

  static const String tokenKey = 'token';
  static const String usernameKey = 'username';
  static const String territoryKey = 'territory';
  static const String brandKey = 'brand';
  static const String roleKey = 'role';
  static const String circleKey = 'circle';
  static const String regionKey = 'region';
  static const String areaKey = 'area';
  static const String branchKey = 'branch';
  static const String mcKey = 'mc';

  String get token => _token;
  String get username => _username;
  String get territory => _territory;
  String get brand => _brand;
  int get role => _role;
  int get circle => _circle;
  int get region => _region;
  int get area => _area;
  int get branch => _branch;
  int get mc => _mc;

  // Helper method to set error
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  // Helper method to clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to determine which dropdowns should be locked based on role
  Map<String, bool> getLockedDropdownsForRole(int role) {
    return {
      'circle': role >= 1, // Lock for roles 1-5
      'region': role >= 2, // Lock for roles 2-5
      'area': role >= 3, // Lock for roles 3-5
      'branch': role >= 4, // Lock for roles 4-5
      'mc': role >= 5, // Lock only for role 5
    };
  }

  // Initialize AuthProvider and load saved data
  Future<void> initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved data
    _token = prefs.getString(tokenKey) ?? '';
    _username = prefs.getString(usernameKey) ?? '';
    _territory = prefs.getString(territoryKey) ?? '';
    _brand = prefs.getString(brandKey) ?? '';
    _role = prefs.getInt(roleKey) ?? 0;
    _circle = prefs.getInt(circleKey) ?? 0;
    _region = prefs.getInt(regionKey) ?? 0;
    _area = prefs.getInt(areaKey) ?? 0;
    _branch = prefs.getInt(branchKey) ?? 0;
    _mc = prefs.getInt(mcKey) ?? 0;

    // If role is between 1 and 5, fetch locked dropdown data
    if (_role >= 1 && _role <= 5 && _token.isNotEmpty) {
      await fetchLockedDropdownDashboard();
      await fetchLockedDropdown();
    }

    // CRITICAL CHANGE: Only try auto-login if we don't already have a token
    // This prevents auto-login after manual logout
    if (_token.isEmpty) {
      await _tryAutoLogin();
    }

    notifyListeners();
  }

  // Save user data to SharedPreferences
  Future<void> setUserData(String token, String username, String territory,
      int role, int circle, String brand) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(usernameKey, username);
    await prefs.setString(territoryKey, territory);
    await prefs.setInt(roleKey, role);
    await prefs.setInt(circleKey, circle);
    await prefs.setString(brandKey, brand);

    _token = token;
    _username = username;
    _territory = territory;
    _role = role;
    _circle = circle;
    _brand = brand;

    notifyListeners();
  }

  // To lock dropdown
  Future<void> fetchLockedDropdown() async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/api/v1/dropdown/selected-dropdown'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // Get which dropdowns should be locked based on role
        final lockedDropdowns = getLockedDropdownsForRole(_role);

        // Only save and update values for dropdowns that should be locked for current role
        if (lockedDropdowns['circle']!) {
          await prefs.setInt(circleKey, data['data']['circle']);
          _circle = data['data']['circle'];
        }

        if (lockedDropdowns['region']!) {
          await prefs.setInt(regionKey, data['data']['region']);
          _region = data['data']['region'];
        }

        if (lockedDropdowns['area']!) {
          await prefs.setInt(areaKey, data['data']['area']);
          _area = data['data']['area'];
        }

        if (lockedDropdowns['branch']!) {
          await prefs.setInt(branchKey, data['data']['branch']);
          _branch = data['data']['branch'];
        }

        if (lockedDropdowns['mc']!) {
          await prefs.setInt(mcKey, data['data']['mc']);
          _mc = data['data']['mc'];
        }

        // Brand is locked for all roles that have any locked dropdowns
        if (lockedDropdowns.containsValue(true)) {
          await prefs.setString(brandKey, data['data']['brand']);
          _brand = data['data']['brand'];
        }

        clearError(); // Clear any existing errors
        notifyListeners();
      } else {
        _setError('Failed to fetch locked dropdown data');
      }
    } catch (e) {
      _setError('Error fetching locked dropdown: ${e.toString()}');
    }
  }

  Future<void> fetchLockedDropdownDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/api/v1/dropdown/selected-dropdown-dashboard'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // Get which dropdowns should be locked based on role
        final lockedDropdowns = getLockedDropdownsForRole(_role);

        // Only save and update values for dropdowns that should be locked for current role
        if (lockedDropdowns['circle']!) {
          await prefs.setInt(circleKey, data['data']['circle']);
          _circle = data['data']['circle'];
        }

        if (lockedDropdowns['region']!) {
          await prefs.setInt(regionKey, data['data']['region']);
          _region = data['data']['region'];
        }

        if (lockedDropdowns['area']!) {
          await prefs.setInt(areaKey, data['data']['area']);
          _area = data['data']['area'];
        }

        if (lockedDropdowns['branch']!) {
          await prefs.setInt(branchKey, data['data']['branch']);
          _branch = data['data']['branch'];
        }

        if (lockedDropdowns['mc']!) {
          await prefs.setInt(mcKey, data['data']['mc']);
          _mc = data['data']['mc'];
        }

        // Brand is locked for all roles that have any locked dropdowns
        if (lockedDropdowns.containsValue(true)) {
          await prefs.setString(brandKey, data['data']['brand']);
          _brand = data['data']['brand'];
        }

        clearError(); // Clear any existing errors
        notifyListeners();
      } else {
        _setError('Failed to fetch locked dropdown data');
      }
    } catch (e) {
      _setError('Error fetching locked dropdown: ${e.toString()}');
    }
  }

  // Method to check and revalidate token state
  Future<void> checkAndRevalidateToken() async {
    // If token is empty, we're already logged out
    if (_token.isEmpty) return;

    // If token is expired, clear everything
    if (isTokenExpired(_token)) {
      await clearUserData();
      notifyListeners();
    }
  }

  // API call for logout
  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/api/v1/logout'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      // Ensure we are disabling auto-login by explicitly setting remember_me to false
      await _secureStorage.write(key: 'remember_me', value: 'false');

      if (response.statusCode == 200) {
        // Clear authentication data but keep credentials for form pre-fill
        await clearUserData();
        clearError();
      } else {
        _setError('Logout failed: ${response.statusCode}');
        // Still clear authentication data
        await clearUserData();
      }
    } catch (e) {
      _setError('Error during logout: ${e.toString()}');
      // Still clear authentication data
      await clearUserData();
      // Make absolutely sure remember_me is set to false
      await _secureStorage.write(key: 'remember_me', value: 'false');
    }
  }

  // Add a new method for complete logout (clears everything)
  Future<void> completeLogout() async {
    await logout();
    await clearAllCredentials();
  }

  // Clear all user data from SharedPreferences
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all data including dropdown values
    await prefs.remove(tokenKey);
    await prefs.remove(usernameKey);
    await prefs.remove(territoryKey);
    await prefs.remove(roleKey);
    await prefs.remove(circleKey);
    await prefs.remove(regionKey);
    await prefs.remove(areaKey);
    await prefs.remove(branchKey);
    await prefs.remove(mcKey);
    await prefs.remove(brandKey);

    _token = '';
    _username = '';
    _territory = '';
    _role = 0;
    _circle = 0;
    _region = 0;
    _area = 0;
    _branch = 0;
    _mc = 0;
    _brand = '';

    notifyListeners();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    if (_token.isEmpty) return false;
    return !isTokenExpired(_token);
  }

  // Token expiration check
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

      if (payload['exp'] == null) return false;

      final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      const SnackBar(content: Text('Error checking token expiration'));
      return true;
    }
  }

  // Get token expiration time in milliseconds
  int? getTokenExpirationTime() {
    try {
      if (_token.isEmpty) return null;

      final parts = _token.split('.');
      if (parts.length != 3) return null;

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

      if (payload['exp'] == null) return null;

      return payload['exp'] * 1000; // Convert to milliseconds
    } catch (e) {
      const SnackBar(content: Text('Error getting token expiration time'));
      return null;
    }
  }

  // Try to login automatically with stored credentials
  Future<bool> _tryAutoLogin() async {
    try {
      final username = await _secureStorage.read(key: 'username');
      final password = await _secureStorage.read(key: 'password');
      final rememberMe = await _secureStorage.read(key: 'remember_me');

      // Double-check the remember_me flag is exactly 'true' before auto-login
      if (username != null && password != null && rememberMe == 'true') {
        final success = await login(username, password);
        return success;
      }
    } catch (e) {
      // Handle errors on failure
      await clearAllCredentials();
    }
    return false;
  }

  // Save credentials for Remember Me feature
  Future<void> saveCredentials(String username, String password) async {
    await _secureStorage.write(key: 'username', value: username);
    await _secureStorage.write(key: 'password', value: password);
    await _secureStorage.write(key: 'remember_me', value: 'true');
  }

  // Clear stored credentials
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: 'username');
    await _secureStorage.delete(key: 'password');
    await _secureStorage.delete(key: 'remember_me');
  }

  // Clear ALL credentials (for complete logout)
  Future<void> clearAllCredentials() async {
    await _secureStorage.delete(key: 'username');
    await _secureStorage.delete(key: 'password');
    await _secureStorage.delete(key: 'remember_me');
  }

  // Add login method that can be called from auth provider
  Future<bool> login(String username, String password) async {
    try {
      final url = Uri.parse('${dotenv.env['baseURL']}/api/v1/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
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

          await setUserData(token, username, territory, role, 0, brand);

          if (role >= 1 && role <= 5) {
            await fetchLockedDropdownDashboard();
            await fetchLockedDropdown();
          }

          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
