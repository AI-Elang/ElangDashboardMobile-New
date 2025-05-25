import 'package:elang_dashboard_new_ui/cari_maps.dart';
import 'package:elang_dashboard_new_ui/complain.dart';
import 'package:elang_dashboard_new_ui/dse.dart';
import 'package:elang_dashboard_new_ui/dse_report.dart';
import 'package:elang_dashboard_new_ui/dse_tracking.dart';
import 'package:elang_dashboard_new_ui/mc_maps.dart';
import 'package:elang_dashboard_new_ui/mitra.dart';
import 'package:elang_dashboard_new_ui/outlet.dart';
import 'package:elang_dashboard_new_ui/search.dart';
import 'package:elang_dashboard_new_ui/site.dart';
import 'package:elang_dashboard_new_ui/login.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/braind.dart';
import 'package:elang_dashboard_new_ui/export_doc.dart';
import 'package:elang_dashboard_new_ui/chat_feature_new.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

import 'dart:convert';
import 'dart:async';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

mixin AutoLogoutMixin<T extends StatefulWidget> on State<T> {
  Timer? _inactivityTimer;
  Timer? _tokenExpirationTimer;
  static const inactivityDuration = Duration(minutes: 90);

  void _showLogoutDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sesi Berakhir'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                // Clear all routes and navigate to login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _setupTokenExpirationTimer() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expirationTime = authProvider.getTokenExpirationTime();

    if (expirationTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeUntilExpiration = expirationTime - now;

      if (timeUntilExpiration > 0) {
        _tokenExpirationTimer = Timer(
          Duration(milliseconds: timeUntilExpiration),
          () {
            _performAutoLogout(
                'Token telah kadaluarsa, silahkan login kembali.');
          },
        );
      }
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityDuration, () {
      _performAutoLogout(
          'Anda tidak aktif selama ${inactivityDuration.inMinutes} menit, silahkan login kembali.');
    });
  }

  Future<void> _performAutoLogout(String message) async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (!mounted) return;

    _showLogoutDialog(message);
  }

  // Add method to verify authentication
  void verifyAuthentication(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn() || authProvider.token.isEmpty) {
      // Navigate to login page and clear all routes if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Verify authentication status when page loads
    verifyAuthentication(context);
    _setupTokenExpirationTimer();
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _tokenExpirationTimer?.cancel();
    super.dispose();
  }
}

class PhotoViewPage extends StatelessWidget {
  final String imageUrl;

  const PhotoViewPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo View'),
      ),
      body: Center(child: PhotoView(imageProvider: NetworkImage(imageUrl))),
    );
  }
}

class _HomepageState extends State<Homepage> with AutoLogoutMixin {
  final PageController _pageController = PageController();

  Timer? _autoScrollTimer;

  String? _selectedDropdown1 = 'Circle Java';
  String? _selectedDropdown2 = 'ALL';
  String? _selectedDropdown3 = 'ALL';
  String? _selectedDropdown4 = 'ALL';
  String? _selectedDropdown5 = 'ALL';
  String? lastUpdate;
  String _appVersion = '';
  String _formattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hours = now.hour.toString().padLeft(2, '0');
    final minutes = now.minute.toString().padLeft(2, '0');
    return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year} - $hours:$minutes';
  }

  int _selectedTabIndex = 0;
  int _currentPage = 0;

  // Loading states
  bool _isLoadingTable = false;
  bool _isLoadingRegions = false;
  bool _isLoadingSubRegions = false;
  bool _isLoadingAreas = false;
  bool _isLoadingMCs = false;
  bool _isFilterExpanded = true;
  bool _isLoadingData = true;
  bool _isLoadingSlider = true;
  bool _isDropdownLocked(int dropdownNumber) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.role == 5) {
      return dropdownNumber <= 5; // Locks dropdowns 1-5
    } else if (authProvider.role == 4) {
      return dropdownNumber <= 4; // Locks dropdowns 1-4
    } else if (authProvider.role == 3) {
      return dropdownNumber <= 3; // Locks dropdowns 1-3
    } else if (authProvider.role == 2) {
      return dropdownNumber <= 2; // Locks dropdowns 1-2
    } else if (authProvider.role == 1) {
      return dropdownNumber == 1; // Only locks dropdown 1 for role 1
    }
    return false; // No locks for other roles
  }

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _subRegions = [];
  List<Map<String, dynamic>> _subAreas = [];
  List<Map<String, dynamic>> _mcList = [];
  List<Map<String, dynamic>> _statusTableData = [];
  List<Map<String, dynamic>> _profileTableData = [];
  List<Map<String, dynamic>> _manPowerTableData = [];
  List<Map<String, dynamic>> _dseRuralTableData = [];
  List<Map<String, dynamic>> _rtvTableData = [];
  List<Map<String, dynamic>> _championsTableData = [];
  List<Map<String, dynamic>> _sliderData = [];

  static const autoScrollDuration = Duration(seconds: 25);

  var baseURL = dotenv.env['baseURL'];

  // Last update
  Future<void> _fetchLastUpdate(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/dashboard/as-of-date',
    );

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          lastUpdate = data['data']['asof_dt'];
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  // REGION DATA (Dropdown 2)
  Future<void> fetchRegions(String? token) async {
    setState(() {
      _isLoadingRegions = true; // Start loading
      _regions = [
        {'id': null, 'name': 'ALL'}
      ]; // Reset with ALL
      _selectedDropdown2 = 'ALL';
      _subRegions = [
        {'id': null, 'name': 'ALL'}
      ]; // Reset subsequent dropdowns
      _selectedDropdown3 = 'ALL';
      _subAreas = [
        {'id': null, 'name': 'ALL'}
      ];
      _selectedDropdown4 = 'ALL';
      _mcList = [
        {'id': null, 'name': 'ALL'}
      ];
      _selectedDropdown5 = 'ALL';
    });

    final url = '$baseURL/api/v1/dropdown/get-region-dashboard?circle=1';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> regionsData = data['data'];

        setState(() {
          _regions = regionsData
              .map((region) => {'id': region['id'], 'name': region['name']})
              .toList();
          _regions.insert(0, {'id': null, 'name': 'ALL'});
          _selectedDropdown2 =
              _regions.isNotEmpty ? _regions[0]['name'] : 'ALL';
        });
      } else {
        SnackBar(
            content: Text('Failed to load regions: ${response.statusCode}'));
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching data'));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRegions = false; // Stop loading
        });
      }
    }
  }

  // AREA DATA (Dropdown 3)
  Future<void> fetchSubRegions(int regionId, String? token) async {
    setState(() {
      _isLoadingSubRegions = true; // Start loading
      _subRegions = [
        {'id': null, 'name': 'ALL'}
      ]; // Reset with ALL
      _selectedDropdown3 = 'ALL';
      _subAreas = [
        {'id': null, 'name': 'ALL'}
      ]; // Reset subsequent dropdowns
      _selectedDropdown4 = 'ALL';
      _mcList = [
        {'id': null, 'name': 'ALL'}
      ];
      _selectedDropdown5 = 'ALL';
    });

    final url =
        '$baseURL/api/v1/dropdown/get-region-dashboard?circle=1&region=$regionId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> subRegionsData = data['data'];

        setState(() {
          _subRegions = subRegionsData
              .map((subRegion) =>
                  {'id': subRegion['id'], 'name': subRegion['name']})
              .toList();
          _subRegions.insert(0, {'id': null, 'name': 'ALL'});
          _selectedDropdown3 =
              _subRegions.isNotEmpty ? _subRegions[0]['name'] : 'ALL';
        });
      } else {
        SnackBar(
            content:
                Text('Failed to load sub-regions: ${response.statusCode}'));
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching data'));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSubRegions = false; // Stop loading
        });
      }
    }
  }

  // BRANCH DATA (Dropdown 4)
  Future<void> fetchAreas(int regionId, int subRegionId, String? token) async {
    setState(() {
      _isLoadingAreas = true; // Start loading
      _subAreas = [
        {'id': null, 'name': 'ALL'}
      ]; // Reset with ALL
      _selectedDropdown4 = 'ALL';
      _mcList = [
        {'id': null, 'name': 'ALL'}
      ]; // Reset subsequent dropdowns
      _selectedDropdown5 = 'ALL';
    });

    final url =
        '$baseURL/api/v1/dropdown/get-region-dashboard?circle=1&region=$regionId&area=$subRegionId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> areasData = data['data'];

        setState(() {
          _subAreas = areasData
              .map((area) => {'id': area['id'], 'name': area['name']})
              .toList();
          _subAreas.insert(0, {'id': null, 'name': 'ALL'});
          _selectedDropdown4 =
              _subAreas.isNotEmpty ? _subAreas[0]['name'] : 'ALL';
        });
      } else {
        SnackBar(content: Text('Failed to load areas: ${response.statusCode}'));
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching data'));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAreas = false; // Stop loading
        });
      }
    }
  }

  // MC DATA (Dropdown 5)
  Future<void> fetchMC(int circleId, int regionId, int areaId, int branchId,
      String? token) async {
    setState(() {
      _isLoadingMCs = true; // Start loading
      _mcList = [
        {'id': null, 'name': 'ALL'}
      ]; // Reset with ALL
      _selectedDropdown5 = 'ALL';
    });

    final url =
        '$baseURL/api/v1/dropdown/get-region-dashboard?circle=$circleId&region=$regionId&area=$areaId&branch=$branchId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> mcData = data['data'];

        setState(() {
          _mcList = mcData
              .map((mc) => {
                    'id': mc['id'],
                    'id_secondary': mc['id_secondary'],
                    'name': mc['name'],
                    'display_name': '${mc['name']} (${mc['id']})'
                  })
              .toList();

          // Add 'ALL' as first option
          _mcList.insert(0, {
            'id': null,
            'id_secondary': null,
            'name': 'ALL',
            'display_name': 'ALL'
          });

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.mc != 0) {
            final mcEntry = _mcList.firstWhere(
                (mc) => mc['id'] == authProvider.mc,
                orElse: () => _mcList[0]);
            _selectedDropdown5 = mcEntry['name'];
          } else {
            _selectedDropdown5 = _mcList[0]['name'];
          }
        });
      } else {
        SnackBar(content: Text('Failed to load MCs: ${response.statusCode}'));
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching data'));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMCs = false; // Stop loading
        });
      }
    }
  }

  // LAUNCH BROWSER
  Future<void> _launchInBrowserView(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      throw Exception('Could not launch $url');
    }
  }

  // Status table data
  Future<void> fetchStatusTable({
    int? circleId,
    int? regionId,
    int? areaId,
    int? branchId,
    int? mcId,
    String? token,
  }) async {
    circleId = 1;
    String url = '$baseURL/api/v1/dashboard/status?circle=$circleId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Add parameters based on selection hierarchy
    if (_selectedDropdown2 != 'ALL') {
      if (branchId != null && _selectedDropdown3 != 'ALL') {
        areaId = _subRegions
            .firstWhere((sr) => sr['name'] == _selectedDropdown3)['id'];
      }

      if (areaId != null) {
        regionId =
            _regions.firstWhere((r) => r['name'] == _selectedDropdown2)['id'];
      }

      if (regionId != null &&
          areaId == null &&
          branchId == null &&
          mcId == null) {
        url += '&region=$regionId';
      } else if (regionId != null &&
          areaId != null &&
          branchId == null &&
          mcId == null) {
        url += '&region=$regionId&area=$areaId';
      } else if (regionId != null &&
          areaId != null &&
          branchId != null &&
          mcId == null) {
        url += '&region=$regionId&area=$areaId&branch=$branchId';
      } else if (regionId != null &&
          areaId != null &&
          branchId != null &&
          mcId != null) {
        url += '&region=$regionId&area=$areaId&branch=$branchId&mc=$mcId';
      }
    }

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return; // Check mount status before setState
        setState(() {
          _statusTableData = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        if (!mounted) return; // Check mount status before setState
        setState(() {
          _statusTableData = [];
        });
        SnackBar(
          content: Text('Failed to load status table: ${response.statusCode}'),
        );
      }
    } catch (e) {
      if (!mounted) return; // Check mount status before setState
      setState(() {
        _statusTableData = [];
      });
      const SnackBar(content: Text('Error fetching data'));
    } finally {
      // Ensure loading state is reset regardless of success/failure
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // Profiles table data
  Future<void> fetchProfileTable({
    int? circleId,
    int? regionId,
    int? areaId,
    int? branchId,
    int? mcId,
    String? token,
  }) async {
    circleId = 1;
    String url = '$baseURL/api/v1/dashboard/profile?circle=$circleId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Add parameters based on selection hierarchy
    if (_selectedDropdown2 != 'ALL') {
      if (branchId != null && _selectedDropdown3 != 'ALL') {
        areaId = _subRegions
            .firstWhere((sr) => sr['name'] == _selectedDropdown3)['id'];
      }
      if (areaId != null) {
        regionId =
            _regions.firstWhere((r) => r['name'] == _selectedDropdown2)['id'];
      }

      if (regionId != null &&
          areaId == null &&
          branchId == null &&
          mcId == null) {
        url += '&region=$regionId';
      } else if (regionId != null &&
          areaId != null &&
          branchId == null &&
          mcId == null) {
        url += '&region=$regionId&area=$areaId';
      } else if (regionId != null &&
          areaId != null &&
          branchId != null &&
          mcId == null) {
        url += '&region=$regionId&area=$areaId&branch=$branchId';
      } else if (regionId != null &&
          areaId != null &&
          branchId != null &&
          mcId != null) {
        url += '&region=$regionId&area=$areaId&branch=$branchId&mc=$mcId';
      }
    }

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _profileTableData = List<Map<String, dynamic>>.from(data['data']);
          _manPowerTableData = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        if (!mounted) return;
        setState(() {
          _profileTableData = [];
          _manPowerTableData = [];
        });
        SnackBar(
          content:
              Text('Failed to load profiles table: ${response.statusCode}'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileTableData = [];
        _manPowerTableData = [];
      });
      const SnackBar(content: Text('Error fetching data'));
    } finally {
      // Ensure loading state is reset regardless of success/failure
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // Dse rural table data
  Future<void> fetchDseRuralTable({
    int? circleId,
    int? regionId,
    int? areaId,
    int? branchId,
    String? token,
  }) async {
    circleId = 1;
    String url = '$baseURL/api/v1/dashboard/dse-rural?circle=$circleId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Add parameters based on selection hierarchy
    if (_selectedDropdown2 != 'ALL') {
      if (branchId != null && _selectedDropdown3 != 'ALL') {
        areaId = _subRegions
            .firstWhere((sr) => sr['name'] == _selectedDropdown3)['id'];
      }

      if (areaId != null) {
        regionId =
            _regions.firstWhere((r) => r['name'] == _selectedDropdown2)['id'];
      }

      if (regionId != null && areaId == null && branchId == null) {
        url += '&region=$regionId';
      } else if (regionId != null && areaId != null && branchId == null) {
        url += '&region=$regionId&area=$areaId';
      } else if (regionId != null && areaId != null && branchId != null) {
        url += '&region=$regionId&area=$areaId&branch=$branchId';
      }
    }

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _dseRuralTableData = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        if (!mounted) return;
        setState(() {
          _dseRuralTableData = [];
        });
        SnackBar(
          content: Text('Failed to load status table: ${response.statusCode}'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dseRuralTableData = [];
      });
      const SnackBar(content: Text('Error fetching data'));
    } finally {
      // Ensure loading state is reset regardless of success/failure
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // Rtv table data
  Future<void> fetchRTVTable({
    int? circleId,
    int? regionId,
    int? areaId,
    int? branchId,
    int? mcId,
    String? token,
  }) async {
    circleId = 1;
    String url = '$baseURL/api/v1/dashboard/rtv?circle=$circleId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Add parameters based on selection hierarchy
    if (_selectedDropdown2 != 'ALL') {
      if (branchId != null && _selectedDropdown3 != 'ALL') {
        areaId = _subRegions
            .firstWhere((sr) => sr['name'] == _selectedDropdown3)['id'];
      }

      if (areaId != null) {
        regionId =
            _regions.firstWhere((r) => r['name'] == _selectedDropdown2)['id'];
      }

      if (regionId != null &&
          areaId == null &&
          branchId == null &&
          mcId == null) {
        url += '&region=$regionId';
      } else if (regionId != null &&
          areaId != null &&
          branchId == null &&
          mcId == null) {
        url += '&region=$regionId&area=$areaId';
      } else if (regionId != null &&
          areaId != null &&
          branchId != null &&
          mcId == null) {
        url += '&region=$regionId&area=$areaId&branch=$branchId';
      } else if (regionId != null &&
          areaId != null &&
          branchId != null &&
          mcId != null) {
        url += '&region=$regionId&area=$areaId&branch=$branchId&mc=$mcId';
      }
    }

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _rtvTableData = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        if (!mounted) return;
        setState(() {
          _rtvTableData = [];
        });
        SnackBar(
          content: Text('Failed to load status table: ${response.statusCode}'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rtvTableData = [];
      });
      const SnackBar(content: Text('Error fetching data'));
    } finally {
      // Ensure loading state is reset regardless of success/failure
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // Champions table data
  Future<void> fetchChampionsTable({
    int? circleId,
    int? regionId,
    int? areaId,
    int? branchId,
    int? mcId,
    String? token,
  }) async {
    if (!mounted) return;
    setState(() {
      _isLoadingTable = true;
      _championsTableData = [];
    });

    circleId = 1;
    String url = '$baseURL/api/v1/dashboard/champions?circle=$circleId';

    // Find IDs based on selected names, handle 'ALL' case
    if (_selectedDropdown2 != 'ALL') {
      regionId =
          _regions.firstWhere((r) => r['name'] == _selectedDropdown2)['id'];
      url += '&region=$regionId';

      if (_selectedDropdown3 != 'ALL') {
        areaId = _subRegions
            .firstWhere((sr) => sr['name'] == _selectedDropdown3)['id'];
        url += '&area=$areaId';

        if (_selectedDropdown4 != 'ALL') {
          branchId = _subAreas
              .firstWhere((area) => area['name'] == _selectedDropdown4)['id'];
          url += '&branch=$branchId';

          if (_selectedDropdown5 != 'ALL') {
            mcId = _mcList
                .firstWhere((mc) => mc['name'] == _selectedDropdown5)['id'];
            url += '&mc=$mcId';
          }
        }
      }
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _championsTableData = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _championsTableData = []; // Clear data on failure
          });
        }
        SnackBar(
          content: Text('Failed to load status table: ${response.statusCode}'),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _championsTableData = []; // Clear data on error
        });
      }
      const SnackBar(content: Text('Error fetching data'));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTable = false; // Stop loading table
        });
      }
    }
  }

  // Fetch slider data
  Future<void> fetchSliderData({String? token}) async {
    setState(() {
      _isLoadingSlider = true;
    });

    final url = Uri.parse('$baseURL/api/v1/app/sliders');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Filter only active sliders and sort by order
          _sliderData = List<Map<String, dynamic>>.from(data['data']
              .where((slider) => slider['is_active'] == true)
              .toList())
            ..sort((a, b) => a['order'].compareTo(b['order']));
          _isLoadingSlider = false;
        });
      } else {
        setState(() {
          _sliderData = [];
          _isLoadingSlider = false;
        });
        SnackBar(
          content: Text('Failed to load slider data: ${response.statusCode}'),
        );
      }
    } catch (e) {
      setState(() {
        _sliderData = [];
        _isLoadingSlider = false;
      });
      const SnackBar(content: Text('Error fetching slider data'));
    }
  }

  // LOCKED DROPDOWNS
  Future<void> _initializeLockedDropdowns() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    // Set loading states true initially for locked dropdowns
    setState(() {
      _isLoadingRegions = authProvider.role >= 1;
      _isLoadingSubRegions = authProvider.role >= 2;
      _isLoadingAreas = authProvider.role >= 3;
      _isLoadingMCs = authProvider.role >= 4;
      _isLoadingTable = true; // Also load table initially
    });

    await authProvider.fetchLockedDropdownDashboard();
    if (!mounted) return;

    setState(() {
      _selectedDropdown1 = 'Circle Java';
    });

    // Fetch regions and wait
    await fetchRegions(token);
    if (!mounted) return;
    if (authProvider.region != 0) {
      final regionName = _regions.firstWhere(
          (r) => r['id'] == authProvider.region,
          orElse: () => {'id': null, 'name': 'ALL'})['name'];
      if (mounted) {
        setState(() {
          _selectedDropdown2 = regionName;
        });
      }

      // Fetch sub-regions and wait
      await fetchSubRegions(authProvider.region, token);
      if (!mounted) return;
      if (authProvider.area != 0) {
        final areaName = _subRegions.firstWhere(
            (a) => a['id'] == authProvider.area,
            orElse: () => {'id': null, 'name': 'ALL'})['name'];
        if (mounted) {
          setState(() {
            _selectedDropdown3 = areaName;
          });
        }

        // Fetch areas and wait
        await fetchAreas(authProvider.region, authProvider.area, token);
        if (!mounted) return;
        if (authProvider.branch != 0) {
          final branchName = _subAreas.firstWhere(
              (b) => b['id'] == authProvider.branch,
              orElse: () => {'id': null, 'name': 'ALL'})['name'];
          if (mounted) {
            setState(() {
              _selectedDropdown4 = branchName;
            });
          }

          // Fetch MCs and wait
          await fetchMC(authProvider.circle, authProvider.region,
              authProvider.area, authProvider.branch, token);
          if (!mounted) return;
          if (authProvider.mc != 0) {
            final mcData = _mcList.firstWhere(
                (mc) => mc['id'] == authProvider.mc,
                orElse: () => {'id': null, 'name': 'ALL'});
            if (mounted) {
              setState(() {
                _selectedDropdown5 = mcData['name'];
              });
            }
          }
        }
      }
    }

    // Finally, fetch the table data based on the initialized locked dropdowns
    await fetchChampionsTable(
      token: token,
      circleId: authProvider.circle,
      regionId: authProvider.region == 0 ? null : authProvider.region,
      areaId: authProvider.area == 0 ? null : authProvider.area,
      branchId: authProvider.branch == 0 ? null : authProvider.branch,
      mcId: authProvider.mc == 0 ? null : authProvider.mc,
    );
  }

  // LOGOUT
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Tampilkan dialog konfirmasi
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Ensure we disable auto-login but keep credentials for pre-fill
        await authProvider.logout();

        if (!mounted) return;

        // Redirect ke halaman login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }

  // Method untuk mendapatkan versi aplikasi
  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  // Show Under Maintenance Dialog
  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Under Maintenance'),
          content: const Text(
              'This feature is currently under maintenance. Please check back later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Auto scroll images
  void _startAutoScroll() {
    // Only start auto-scroll if there are multiple slides
    if (_sliderData.length > 1) {
      _autoScrollTimer = Timer.periodic(autoScrollDuration, (Timer timer) {
        if (_pageController.hasClients) {
          if (_currentPage < _sliderData.length - 1) {
            _pageController.animateToPage(
              _currentPage + 1,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }
  }

  // PhotoOpen
  void _openPhoto(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewPage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    // Pastikan widget sudah ter-mount sepenuhnya
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Berikan sedikit delay untuk memastikan context sudah siap
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      // Lanjutkan dengan inisialisasi lainnya
      if (authProvider.role == 5) {
        await _initializeLockedDropdowns();
        if (mounted) {
          await fetchStatusTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchProfileTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchDseRuralTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
          );
          await fetchRTVTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchChampionsTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
        }
      } else if (authProvider.role == 4) {
        await _initializeLockedDropdowns();
        if (mounted) {
          await fetchStatusTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchProfileTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchDseRuralTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
          );
          await fetchRTVTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchChampionsTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
        }
      } else if (authProvider.role == 3) {
        await _initializeLockedDropdowns();
        if (mounted) {
          await fetchStatusTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchProfileTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchDseRuralTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
          );
          await fetchRTVTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchChampionsTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
        }
      } else if (authProvider.role == 2) {
        await _initializeLockedDropdowns();
        if (mounted) {
          await fetchStatusTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchProfileTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchDseRuralTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
          );
          await fetchRTVTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
          await fetchChampionsTable(
            token: token,
            circleId: authProvider.circle,
            regionId: authProvider.region,
            areaId: authProvider.area,
            branchId: authProvider.branch,
            mcId: authProvider.mc,
          );
        }
      } else {
        await fetchRegions(token);
        await fetchStatusTable(token: token);
        await fetchProfileTable(token: token);
        await fetchDseRuralTable(token: token);
        await fetchRTVTable(token: token);
        await fetchChampionsTable(token: token);
      }

      await _fetchLastUpdate(token);
      await fetchSliderData(token: token);
      _startAutoScroll();
      _getAppVersion();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;
    final Uri whatsappUrl = Uri.parse(
        'https://api.whatsapp.com/send?phone=6285851715758&text=ELANG');

    // Define our color scheme
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    return GestureDetector(
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      onPanUpdate: (_) => _resetInactivityTimer(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // App header with gradient background
                  Container(
                    height: mediaQueryHeight * 0.06,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, accentColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ELANG JAVA DASHBOARD',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Main content area
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: backgroundColor,
                        image: DecorationImage(
                          image: AssetImage('assets/LOGO.png'),
                          fit: BoxFit.cover,
                          opacity: 0.08,
                          alignment: Alignment.bottomRight,
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Profile & Filters Section
                              Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: cardColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      // User info row
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Avatar with ring
                                          Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: accentColor
                                                    .withOpacity(0.6),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: const CircleAvatar(
                                              radius: 30,
                                              backgroundImage:
                                                  AssetImage('assets/100.png'),
                                              backgroundColor:
                                                  Colors.transparent,
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          // User info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  territory,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: textSecondaryColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  role == 5
                                                      ? 'MC'
                                                      : role == 1
                                                          ? 'CIRCLE'
                                                          : role == 2
                                                              ? 'HOR'
                                                              : role == 3
                                                                  ? 'HOS'
                                                                  : role == 4
                                                                      ? 'BSM'
                                                                      : 'No Role',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: textPrimaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Date + Version info
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: primaryColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  _formattedDate(),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: textSecondaryColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: primaryColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'Version: $_appVersion',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: textPrimaryColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),

                                      // Filter dropdowns
                                      Container(
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Header with toggle icon
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _isFilterExpanded =
                                                      !_isFilterExpanded;
                                                });
                                              },
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    "Filters",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                  Icon(
                                                    _isFilterExpanded
                                                        ? Icons.arrow_drop_up
                                                        : Icons.arrow_drop_down,
                                                    color: primaryColor,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Collapsible content
                                            if (_isFilterExpanded) ...[
                                              const SizedBox(height: 8),
                                              // Dropdown row 1
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildFilterDropdown(
                                                      "Circle",
                                                      _selectedDropdown1!,
                                                      _isDropdownLocked(1),
                                                      (value) {
                                                        setState(() {
                                                          _selectedDropdown1 =
                                                              value;
                                                        });
                                                      },
                                                      ['Circle Java'],
                                                      _isLoadingRegions, // Pass loading state
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: _buildFilterDropdown(
                                                      "Region",
                                                      _selectedDropdown2!,
                                                      _isDropdownLocked(2),
                                                      (value) async {
                                                        if (_isLoadingRegions ||
                                                            _isLoadingSubRegions) {
                                                          return; // Prevent change if loading
                                                        }
                                                        if (value ==
                                                            _selectedDropdown2) {
                                                          return; // No change
                                                        }

                                                        setState(() {
                                                          _selectedDropdown2 =
                                                              value;
                                                          _selectedDropdown3 =
                                                              'ALL';
                                                          _selectedDropdown4 =
                                                              'ALL';
                                                          _selectedDropdown5 =
                                                              'ALL';
                                                          _subRegions = [
                                                            {
                                                              'id': null,
                                                              'name': 'ALL'
                                                            }
                                                          ];
                                                          _subAreas = [
                                                            {
                                                              'id': null,
                                                              'name': 'ALL'
                                                            }
                                                          ];
                                                          _mcList = [
                                                            {
                                                              'id': null,
                                                              'name': 'ALL'
                                                            }
                                                          ];
                                                          _championsTableData =
                                                              [];
                                                        });

                                                        final token = Provider.of<
                                                                    AuthProvider>(
                                                                context,
                                                                listen: false)
                                                            .token;

                                                        if (value == 'ALL') {
                                                          await fetchChampionsTable(
                                                              token: token);
                                                        } else {
                                                          int regionId = _regions
                                                              .firstWhere((r) =>
                                                                  r['name'] ==
                                                                  value)['id'];
                                                          await Future.wait([
                                                            fetchSubRegions(
                                                                regionId,
                                                                token),
                                                            fetchStatusTable(
                                                                regionId:
                                                                    regionId,
                                                                token: token),
                                                            fetchProfileTable(
                                                                regionId:
                                                                    regionId,
                                                                token: token),
                                                            fetchRTVTable(
                                                                regionId:
                                                                    regionId,
                                                                token: token),
                                                            fetchChampionsTable(
                                                                regionId:
                                                                    regionId,
                                                                token: token)
                                                          ]);
                                                        }
                                                      },
                                                      _regions
                                                          .map((r) => r['name']
                                                              as String)
                                                          .toList(),
                                                      _isLoadingRegions ||
                                                          _isLoadingSubRegions, // Pass loading state
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),

                                              // Dropdown row 2
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildFilterDropdown(
                                                      "Area",
                                                      _selectedDropdown2 ==
                                                              'ALL'
                                                          ? null
                                                          : _selectedDropdown3, // Handle null value for hint
                                                      _isDropdownLocked(3) ||
                                                          _selectedDropdown2 ==
                                                              'ALL',
                                                      (value) async {
                                                        if (_isLoadingSubRegions ||
                                                            _isLoadingAreas) {
                                                          return; // Prevent change if loading
                                                        }
                                                        if (value ==
                                                            _selectedDropdown3) {
                                                          return; // No change
                                                        }

                                                        setState(() {
                                                          _selectedDropdown3 =
                                                              value;
                                                          _selectedDropdown4 =
                                                              'ALL';
                                                          _selectedDropdown5 =
                                                              'ALL';
                                                          _subAreas = [
                                                            {
                                                              'id': null,
                                                              'name': 'ALL'
                                                            }
                                                          ];
                                                          _mcList = [
                                                            {
                                                              'id': null,
                                                              'name': 'ALL'
                                                            }
                                                          ];
                                                          _championsTableData =
                                                              [];
                                                        });

                                                        final token = Provider.of<
                                                                    AuthProvider>(
                                                                context,
                                                                listen: false)
                                                            .token;
                                                        int regionId = _regions
                                                            .firstWhere((r) =>
                                                                r['name'] ==
                                                                _selectedDropdown2)['id'];

                                                        if (value == 'ALL') {
                                                          await fetchStatusTable(
                                                              regionId:
                                                                  regionId,
                                                              token: token);
                                                          await fetchProfileTable(
                                                              regionId:
                                                                  regionId,
                                                              token: token);
                                                          await fetchRTVTable(
                                                              regionId:
                                                                  regionId,
                                                              token: token);
                                                          await fetchChampionsTable(
                                                              regionId:
                                                                  regionId,
                                                              token: token);
                                                        } else {
                                                          int areaId = _subRegions
                                                              .firstWhere((sr) =>
                                                                  sr['name'] ==
                                                                  value)['id'];
                                                          await Future.wait([
                                                            fetchAreas(regionId,
                                                                areaId, token),
                                                            fetchStatusTable(
                                                                regionId:
                                                                    regionId,
                                                                areaId: areaId,
                                                                token: token),
                                                            fetchProfileTable(
                                                                regionId:
                                                                    regionId,
                                                                areaId: areaId,
                                                                token: token),
                                                            fetchRTVTable(
                                                                regionId:
                                                                    regionId,
                                                                areaId: areaId,
                                                                token: token),
                                                            fetchChampionsTable(
                                                                regionId:
                                                                    regionId,
                                                                areaId: areaId,
                                                                token: token)
                                                          ]);
                                                        }
                                                      },
                                                      _subRegions
                                                          .map((sr) =>
                                                              sr['name']
                                                                  as String)
                                                          .toList(),
                                                      _isLoadingSubRegions ||
                                                          _isLoadingAreas, // Pass loading state
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: _buildFilterDropdown(
                                                      "Branch",
                                                      _selectedDropdown3 ==
                                                              'ALL'
                                                          ? null
                                                          : _selectedDropdown4, // Handle null value for hint
                                                      _isDropdownLocked(4) ||
                                                          _selectedDropdown3 ==
                                                              'ALL',
                                                      (value) async {
                                                        if (_isLoadingAreas ||
                                                            _isLoadingMCs) {
                                                          return; // Prevent change if loading
                                                        }
                                                        if (value ==
                                                            _selectedDropdown4) {
                                                          return; // No change
                                                        }

                                                        setState(() {
                                                          _selectedDropdown4 =
                                                              value;
                                                          _selectedDropdown5 =
                                                              'ALL';
                                                          _mcList = [
                                                            {
                                                              'id': null,
                                                              'name': 'ALL'
                                                            }
                                                          ];
                                                          _championsTableData =
                                                              [];
                                                        });

                                                        final token = Provider.of<
                                                                    AuthProvider>(
                                                                context,
                                                                listen: false)
                                                            .token;
                                                        int regionId = _regions
                                                            .firstWhere((r) =>
                                                                r['name'] ==
                                                                _selectedDropdown2)['id'];
                                                        int areaId = _subRegions
                                                            .firstWhere((sr) =>
                                                                sr['name'] ==
                                                                _selectedDropdown3)['id'];

                                                        if (value == 'ALL') {
                                                          await fetchStatusTable(
                                                              regionId:
                                                                  regionId,
                                                              areaId: areaId,
                                                              token: token);
                                                          await fetchProfileTable(
                                                              regionId:
                                                                  regionId,
                                                              areaId: areaId,
                                                              token: token);
                                                          await fetchRTVTable(
                                                              regionId:
                                                                  regionId,
                                                              areaId: areaId,
                                                              token: token);
                                                          await fetchChampionsTable(
                                                              regionId:
                                                                  regionId,
                                                              areaId: areaId,
                                                              token: token);
                                                        } else {
                                                          int branchId = _subAreas
                                                              .firstWhere((area) =>
                                                                  area[
                                                                      'name'] ==
                                                                  value)['id'];
                                                          await Future.wait([
                                                            fetchMC(
                                                                1,
                                                                regionId,
                                                                areaId,
                                                                branchId,
                                                                token),
                                                            fetchStatusTable(
                                                                regionId:
                                                                    regionId,
                                                                areaId: areaId,
                                                                branchId:
                                                                    branchId,
                                                                token: token),
                                                            fetchProfileTable(
                                                                regionId:
                                                                    regionId,
                                                                areaId: areaId,
                                                                branchId:
                                                                    branchId,
                                                                token: token),
                                                            fetchRTVTable(
                                                                regionId:
                                                                    regionId,
                                                                areaId: areaId,
                                                                branchId:
                                                                    branchId,
                                                                token: token),
                                                            fetchChampionsTable(
                                                                regionId:
                                                                    regionId,
                                                                areaId: areaId,
                                                                branchId:
                                                                    branchId,
                                                                token: token),
                                                          ]);
                                                        }
                                                      },
                                                      _subAreas
                                                          .map((a) => a['name']
                                                              as String)
                                                          .toList(),
                                                      _isLoadingAreas ||
                                                          _isLoadingMCs, // Pass loading state
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),

                                              // Dropdown row 3
                                              _buildFilterDropdown(
                                                "MC",
                                                _selectedDropdown4 == 'ALL'
                                                    ? null
                                                    : _selectedDropdown5, // Handle null value for hint
                                                _isDropdownLocked(5) ||
                                                    _selectedDropdown4 == 'ALL',
                                                (value) async {
                                                  if (_isLoadingMCs) {
                                                    return; // Prevent change if loading
                                                  }
                                                  if (value ==
                                                      _selectedDropdown5) {
                                                    return; // No change
                                                  }

                                                  setState(() {
                                                    _selectedDropdown5 = value;
                                                    _championsTableData = [];
                                                  });

                                                  final token =
                                                      Provider.of<AuthProvider>(
                                                              context,
                                                              listen: false)
                                                          .token;
                                                  int regionId =
                                                      _regions.firstWhere((r) =>
                                                              r['name'] ==
                                                              _selectedDropdown2)[
                                                          'id'];
                                                  int areaId = _subRegions
                                                          .firstWhere((sr) =>
                                                              sr['name'] ==
                                                              _selectedDropdown3)[
                                                      'id'];
                                                  int branchId = _subAreas
                                                          .firstWhere((area) =>
                                                              area['name'] ==
                                                              _selectedDropdown4)[
                                                      'id'];

                                                  if (value == 'ALL') {
                                                    await fetchStatusTable(
                                                        regionId: regionId,
                                                        areaId: areaId,
                                                        branchId: branchId,
                                                        token: token);
                                                    await fetchProfileTable(
                                                        regionId: regionId,
                                                        areaId: areaId,
                                                        branchId: branchId,
                                                        token: token);
                                                    await fetchRTVTable(
                                                        regionId: regionId,
                                                        areaId: areaId,
                                                        branchId: branchId,
                                                        token: token);
                                                    await fetchChampionsTable(
                                                        regionId: regionId,
                                                        areaId: areaId,
                                                        branchId: branchId,
                                                        token: token);
                                                  } else {
                                                    int mcId = _mcList
                                                        .firstWhere((mc) =>
                                                            mc['name'] ==
                                                            value)['id'];
                                                    await fetchStatusTable(
                                                        regionId: regionId,
                                                        areaId: areaId,
                                                        branchId: branchId,
                                                        mcId: mcId,
                                                        token: token);
                                                    await fetchProfileTable(
                                                        regionId: regionId,
                                                        areaId: areaId,
                                                        branchId: branchId,
                                                        mcId: mcId,
                                                        token: token);
                                                    await fetchRTVTable(
                                                        regionId: regionId,
                                                        areaId: areaId,
                                                        branchId: branchId,
                                                        mcId: mcId,
                                                        token: token);
                                                    await fetchChampionsTable(
                                                        regionId: regionId,
                                                        areaId: areaId,
                                                        branchId: branchId,
                                                        mcId: mcId,
                                                        token: token);
                                                  }
                                                },
                                                _mcList
                                                    .map((mc) =>
                                                        mc['name'] as String)
                                                    .toList(),
                                                _isLoadingMCs, // Pass loading state
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Tabs Section
                              Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, // Adjusted padding
                                    vertical: 8), // Adjusted padding
                                child: Row(
                                  // Removed const
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceEvenly, // Align to center
                                  children: [
                                    _buildTabButton(0, 'Champions',
                                        primaryColor, textPrimaryColor),
                                    _buildTabButton(1, 'RTV', primaryColor,
                                        textPrimaryColor),
                                    _buildTabButton(2, 'Status', primaryColor,
                                        textPrimaryColor),
                                    _buildTabButton(3, 'Profile', primaryColor,
                                        textPrimaryColor),
                                    _buildTabButton(4, 'DSE Rural',
                                        primaryColor, textPrimaryColor),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Tables content based on selected tab
                              Container(
                                height: mediaQueryHeight * 0.35,
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _isLoadingTable // Check loading state here
                                    ? const Center(
                                        child: SizedBox(
                                          width: 24, // Adjust size as needed
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    primaryColor),
                                          ),
                                        ),
                                      )
                                    : _selectedTabIndex == 0
                                        // Champions Tables
                                        ? Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              child: Row(
                                                children: [
                                                  // IM3 Table
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    child: _buildChampionsTableCard(
                                                        'IM3 (Last Update: $lastUpdate)',
                                                        true),
                                                  ),
                                                  // 3ID Table
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    child: _buildChampionsTableCard(
                                                        '3ID (Last Update: $lastUpdate)',
                                                        false),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : _selectedTabIndex == 1
                                            // RTV Table
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: _buildRTVTableCard(
                                                    'RTV (Last Update: $lastUpdate)'),
                                              )
                                            : _selectedTabIndex == 2
                                                // Status Tables
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    child:
                                                        SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      physics:
                                                          const BouncingScrollPhysics(),
                                                      child: Row(
                                                        children: [
                                                          // IM3 Status Table
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(4.0),
                                                            child: _buildStatusTableCard(
                                                                'IM3 (Last Update: $lastUpdate)',
                                                                true),
                                                          ),
                                                          // 3ID Status Table
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(4.0),
                                                            child: _buildStatusTableCard(
                                                                '3ID (Last Update: $lastUpdate)',
                                                                false),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : _selectedTabIndex == 3
                                                    // Profile & Man Power Tables
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4.0),
                                                        child:
                                                            SingleChildScrollView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          physics:
                                                              const BouncingScrollPhysics(),
                                                          child: Row(
                                                            children: [
                                                              // Profile Table
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        4.0),
                                                                child: _buildProfileTableCard(
                                                                    'Profile (Last Update: $lastUpdate)'),
                                                              ),
                                                              // Man Power Table
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        4.0),
                                                                child: _buildManPowerTableCard(
                                                                    'Man Power (Last Update: $lastUpdate)'),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    : _selectedTabIndex == 4
                                                        // DSE Rural Tables
                                                        ? Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(4.0),
                                                            child:
                                                                SingleChildScrollView(
                                                              scrollDirection:
                                                                  Axis.horizontal,
                                                              physics:
                                                                  const BouncingScrollPhysics(),
                                                              child: Row(
                                                                children: [
                                                                  // IM3 DSE Rural Table
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: _buildDseRuralTableCard(
                                                                        'IM3 (Last Update: $lastUpdate)',
                                                                        true),
                                                                  ),
                                                                  // 3ID DSE Rural Table
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: _buildDseRuralTableCard(
                                                                        '3ID (Last Update: $lastUpdate)',
                                                                        false),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          )
                                                        : Container(), // Placeholder for other tabs
                              ),

                              const SizedBox(height: 16),

                              // Information Gambar
                              const SizedBox(height: 5),
                              SizedBox(
                                height: mediaQueryHeight * 0.20,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: _isLoadingSlider
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : _sliderData.isEmpty
                                              ? Center(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      color: Colors.grey[200],
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        'NO IMAGE',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : CarouselSlider(
                                                  items:
                                                      _sliderData.map((slider) {
                                                    return Builder(
                                                      builder: (BuildContext
                                                          context) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      4.0,
                                                                  vertical:
                                                                      2.0),
                                                          child: Stack(
                                                            children: [
                                                              // Background gradient & shadow
                                                              Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              18),
                                                                  gradient:
                                                                      LinearGradient(
                                                                    colors: [
                                                                      Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.85),
                                                                      Colors
                                                                          .purple
                                                                          .withOpacity(
                                                                              0.08),
                                                                    ],
                                                                    begin: Alignment
                                                                        .topLeft,
                                                                    end: Alignment
                                                                        .bottomRight,
                                                                  ),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.10),
                                                                      blurRadius:
                                                                          10,
                                                                      spreadRadius:
                                                                          2,
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              4),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              18),
                                                                  child: Stack(
                                                                    fit: StackFit
                                                                        .expand,
                                                                    children: [
                                                                      // Image
                                                                      slider['image'] != null &&
                                                                              slider['image'].toString().isNotEmpty
                                                                          ? InkWell(
                                                                              onTap: () async {
                                                                                final Uri url = Uri.parse(slider['link_to'] ?? '');
                                                                                if (slider['status'] != 'image') {
                                                                                  try {
                                                                                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                                                                      throw Exception('Could not launch $url');
                                                                                    }
                                                                                  } catch (e) {
                                                                                    if (!mounted) return;
                                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                                      const SnackBar(content: Text('Could not open website')),
                                                                                    );
                                                                                  }
                                                                                } else {
                                                                                  _openPhoto(slider['link_to']);
                                                                                }
                                                                              },
                                                                              child: Hero(
                                                                                tag: slider['image'],
                                                                                child: Image.network(
                                                                                  slider['image'],
                                                                                  fit: BoxFit.cover,
                                                                                  width: double.infinity,
                                                                                  height: double.infinity,
                                                                                  loadingBuilder: (context, child, loadingProgress) {
                                                                                    if (loadingProgress == null) return child;
                                                                                    return Center(
                                                                                      child: CircularProgressIndicator(
                                                                                        value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                  errorBuilder: (context, error, stackTrace) {
                                                                                    return Container(
                                                                                      color: Colors.grey[200],
                                                                                      child: const Center(
                                                                                        child: Text(
                                                                                          'NO IMAGE',
                                                                                          style: TextStyle(
                                                                                            fontSize: 16,
                                                                                            fontWeight: FontWeight.bold,
                                                                                            color: Colors.grey,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                ),
                                                                              ),
                                                                            )
                                                                          : Container(
                                                                              color: Colors.grey[200],
                                                                              child: const Center(
                                                                                child: Text(
                                                                                  'NO IMAGE',
                                                                                  style: TextStyle(
                                                                                    fontSize: 16,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    color: Colors.grey,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                      // Overlay for effect
                                                                      Positioned
                                                                          .fill(
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(18),
                                                                            gradient:
                                                                                LinearGradient(
                                                                              colors: [
                                                                                Colors.black.withOpacity(0.08),
                                                                                Colors.transparent,
                                                                              ],
                                                                              begin: Alignment.bottomCenter,
                                                                              end: Alignment.topCenter,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      // Optional: Label or badge
                                                                      if ((slider['title'] ??
                                                                              '')
                                                                          .toString()
                                                                          .isNotEmpty)
                                                                        Positioned(
                                                                          left:
                                                                              10,
                                                                          bottom:
                                                                              10,
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Colors.white.withOpacity(0.85),
                                                                              borderRadius: BorderRadius.circular(12),
                                                                              boxShadow: [
                                                                                BoxShadow(
                                                                                  color: Colors.black.withOpacity(0.08),
                                                                                  blurRadius: 4,
                                                                                  offset: const Offset(0, 2),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Icon(Icons.info_outline, size: 14, color: Colors.purple[400]),
                                                                                const SizedBox(width: 4),
                                                                                Text(
                                                                                  slider['title'] ?? '',
                                                                                  style: TextStyle(
                                                                                    fontSize: 11,
                                                                                    fontWeight: FontWeight.w600,
                                                                                    color: Colors.purple[700],
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              // Optional: Floating action button for link
                                                              if (slider[
                                                                      'status'] !=
                                                                  'image')
                                                                Positioned(
                                                                  top: 10,
                                                                  right: 10,
                                                                  child:
                                                                      Material(
                                                                    color: Colors
                                                                        .transparent,
                                                                    child:
                                                                        InkWell(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              20),
                                                                      onTap:
                                                                          () async {
                                                                        final Uri
                                                                            url =
                                                                            Uri.parse(slider['link_to'] ??
                                                                                '');
                                                                        try {
                                                                          if (!await launchUrl(
                                                                              url,
                                                                              mode: LaunchMode.externalApplication)) {
                                                                            throw Exception('Could not launch $url');
                                                                          }
                                                                        } catch (e) {
                                                                          if (!mounted) {
                                                                            return;
                                                                          }
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            const SnackBar(content: Text('Could not open website')),
                                                                          );
                                                                        }
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color: Colors
                                                                              .white
                                                                              .withOpacity(0.85),
                                                                          borderRadius:
                                                                              BorderRadius.circular(20),
                                                                          boxShadow: [
                                                                            BoxShadow(
                                                                              color: Colors.black.withOpacity(0.08),
                                                                              blurRadius: 4,
                                                                              offset: const Offset(0, 2),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            6),
                                                                        child: const Icon(
                                                                            Icons
                                                                                .open_in_new,
                                                                            size:
                                                                                18,
                                                                            color:
                                                                                Color(0xFF6A62B7)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  }).toList(),
                                                  options: CarouselOptions(
                                                    height: 180.0,
                                                    enlargeCenterPage: true,
                                                    autoPlay: true,
                                                    aspectRatio: 16 / 9,
                                                    autoPlayCurve:
                                                        Curves.fastOutSlowIn,
                                                    enableInfiniteScroll: true,
                                                    autoPlayAnimationDuration:
                                                        const Duration(
                                                            milliseconds: 800),
                                                    viewportFraction: 0.8,
                                                    onPageChanged:
                                                        (index, reason) {
                                                      setState(() {
                                                        _currentPage = index;
                                                      });
                                                    },
                                                  ),
                                                ),
                                    ),
                                    // Page Indicators
                                    if (_sliderData.length > 1) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          _sliderData.length,
                                          (index) => AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            width:
                                                _currentPage == index ? 18 : 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: _currentPage == index
                                                  ? const Color.fromARGB(
                                                      255, 250, 45, 208)
                                                  : Colors.grey
                                                      .withOpacity(0.4),
                                              boxShadow: _currentPage == index
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.pinkAccent
                                                            .withOpacity(0.25),
                                                        blurRadius: 6,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Additional Menu buttons section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  GridView(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      childAspectRatio: 1.0,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 12,
                                    ),
                                    children: [
                                      // DSE AI button
                                      _buildMenuButton(
                                        FontAwesomeIcons.table,
                                        'DSE AI',
                                        primaryColor,
                                        () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const DseReport(),
                                            ),
                                          );
                                        },
                                      ),
                                      // BRAIND button
                                      _buildMenuButton(
                                        FontAwesomeIcons.brain, // Example icon
                                        'BRAIND',
                                        primaryColor,
                                        () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const Braind(),
                                            ),
                                          );
                                        },
                                      ),
                                      // PAID PRO button
                                      _buildMenuButton(
                                        FontAwesomeIcons
                                            .dollarSign, // Example icon
                                        'PAID PRO',
                                        primaryColor,
                                        _showMaintenanceDialog,
                                      ),
                                      // DAILY SF button
                                      _buildMenuButton(
                                        FontAwesomeIcons
                                            .calendarDay, // Example icon
                                        'DAILY SF',
                                        primaryColor,
                                        _showMaintenanceDialog,
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Menu buttons section
                              Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: cardColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Menu",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GridView(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          childAspectRatio: 1.0,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 12,
                                        ),
                                        children: [
                                          // Main Menu Icons

                                          // DSE button
                                          _buildMenuButton(
                                            FontAwesomeIcons.motorcycle,
                                            'DSE',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Dse(),
                                                ),
                                              );
                                            },
                                          ),

                                          // Track button
                                          _buildMenuButton(
                                            FontAwesomeIcons.laptopFile,
                                            'TRACK',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const DseTracking(),
                                                ),
                                              );
                                            },
                                          ),

                                          // Outlet button
                                          _buildMenuButton(
                                            FontAwesomeIcons.home,
                                            'OUTLET',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Outlet(),
                                                ),
                                              );
                                            },
                                          ),

                                          // Site button
                                          _buildMenuButton(
                                            FontAwesomeIcons.towerCell,
                                            'SITE',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Site(),
                                                ),
                                              );
                                            },
                                          ),

                                          // Mitra button
                                          _buildMenuButton(
                                            FontAwesomeIcons.handshake,
                                            'MITRA',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Mitra(),
                                                ),
                                              );
                                            },
                                          ),

                                          // Search button
                                          _buildMenuButton(
                                            FontAwesomeIcons.magnifyingGlass,
                                            'SEARCH',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Search(),
                                                ),
                                              );
                                            },
                                          ),

                                          // Near Me button
                                          _buildMenuButton(
                                            FontAwesomeIcons.locationCrosshairs,
                                            'NEAR ME',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const McMaps(),
                                                ),
                                              );
                                            },
                                          ),

                                          // Maps button
                                          _buildMenuButton(
                                            FontAwesomeIcons.mapLocationDot,
                                            'MAPS',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const CariMaps(),
                                                ),
                                              );
                                            },
                                          ),

                                          // Complain button
                                          _buildMenuButton(
                                            FontAwesomeIcons.screwdriverWrench,
                                            'KELUHAN',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Complain(),
                                                ),
                                              );
                                            },
                                          ),

                                          // Complain button
                                          _buildMenuButton(
                                            FontAwesomeIcons.fileArrowDown,
                                            'EXPORT',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ExportDoc(),
                                                ),
                                              );
                                            },
                                          ),

                                          // Chat button
                                          _buildMenuButton(
                                            FontAwesomeIcons.starOfLife,
                                            'ASK ME',
                                            primaryColor,
                                            () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ChatWelcomePage(),
                                                ),
                                              );
                                            },
                                          ),

                                          // WhatsApp button
                                          _buildMenuButton(
                                            FontAwesomeIcons.whatsapp,
                                            'WHATSAPP',
                                            const Color.fromARGB(
                                                255, 37, 211, 102),
                                            () => _launchInBrowserView(
                                                whatsappUrl), // Updated onTap
                                          ),

                                          // Logout button
                                          _buildMenuButton(
                                            FontAwesomeIcons.rightFromBracket,
                                            'LOGOUT',
                                            Colors.redAccent.shade200,
                                            _handleLogout,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(
                                  height: 70), // Space for bottom bar
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom navigation bar

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomNavItem(
                          Icons.home, 'Home', true, primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildFilterDropdown
  Widget _buildFilterDropdown(
      String label,
      String? value, // Allow null for hint display
      bool isLocked,
      Function(String) onChanged,
      List<String> items,
      bool isLoading, // Add isLoading parameter
      {String? hint} // Add optional hint parameter
      ) {
    // Check if dropdown should be disabled (locked or loading)
    final bool isDisabled = isLocked || isLoading;
    // Use hint if value is null and hint is provided
    final String? displayValue = value;
    final bool showHint = displayValue == null && hint != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDisabled
            ? Colors.grey.shade100 // Use a grey background when disabled
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDisabled
                  ? Colors.grey.shade400 // Dimmer text color when disabled
                  : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: displayValue, // Use displayValue which can be null
              hint: showHint
                  ? Text(
                      // Show hint text if needed
                      hint,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDisabled
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              isDense: true,
              isExpanded: true,
              icon: isLoading // Show loading indicator if loading
                  ? Container(
                      alignment: Alignment.centerRight,
                      width: 16,
                      height: 16,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.arrow_drop_down,
                      color: isDisabled
                          ? Colors.grey.shade400
                          : Colors.grey.shade700, // Dimmer icon
                    ),
              onChanged: isDisabled
                  ? null
                  : (newValue) => onChanged(newValue!), // Disable onChanged
              items: items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDisabled
                          ? Colors.grey.shade400 // Dimmer item text color
                          : const Color(0xFF2D3142),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Menu Button
  Widget _buildMenuButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation Item
  Widget _buildBottomNavItem(
      IconData icon, String label, bool isActive, Color primaryColor) {
    return InkWell(
      onTap: () {
        // Navigation logic would go here
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? primaryColor : Colors.grey,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? primaryColor : Colors.grey,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Tab Button
  Widget _buildTabButton(
      int index, String label, Color primaryColor, Color textColor) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Helper method for table headers - more elegant style
  Widget _buildTableHeader(String text, double flex) {
    return Expanded(
      flex: (flex * 100).toInt(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 8,
            letterSpacing: 0.2,
            color: Color(0xFF455A64),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Helper method for table cells with improved styling
  Widget _buildTableCell(String text, double flex, bool isNumeric,
      {Color? valueColor}) {
    return Expanded(
      flex: (flex * 100).toInt(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
            color: valueColor ?? const Color(0xFF37474F),
          ),
          textAlign: isNumeric ? TextAlign.center : TextAlign.left,
          overflow: TextOverflow.visible, // Changed from ellipsis to visible
          softWrap: true, // Enable text wrapping
          maxLines: 2, // Allow up to 2 lines for wrapped text
        ),
      ),
    );
  }

  // Helper method to determine growth color with softer tones
  Color _getGrowthColor(String? growth) {
    if (growth == null || growth == 'No Data') return const Color(0xFF546E7A);

    final cleanValue = growth.replaceAll('%', '').trim();

    try {
      final value = double.parse(cleanValue);
      if (value > 0) return const Color(0xFF66BB6A); // Softer green
      if (value < 0) return const Color(0xFFEF5350); // Softer red
      return const Color(0xFF546E7A); // Neutral blue-grey
    } catch (e) {
      return const Color(0xFF546E7A);
    }
  }

  // Status Table Card
  Widget _buildStatusTableCard(String title, bool isIM3) {
    final mediaQueryWidth = MediaQuery.of(context).size.width;

    // Colors with reduced intensity
    final primaryColor =
        isIM3 ? const Color(0xFFAB47BC) : const Color(0xFFEC407A);
    final bgColor = isIM3 ? const Color(0xFFF3E5F5) : const Color(0xFFFCE4EC);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: mediaQueryWidth * 0.875,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - simplified with subtle colors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isIM3
                            ? Icons.insert_chart_outlined
                            : Icons.bar_chart_outlined,
                        size: 10,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isIM3 ? "IM3" : "3ID",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 10),

            // Table - No loading check here anymore
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              _buildTableHeader('ITEM', 0.55),
                              _buildTableHeader('MTD', 0.75),
                              _buildTableHeader('LMTD', 0.75),
                              _buildTableHeader('GROWTH', 0.75),
                            ],
                          ),
                        ),
                      ),

                      // Data Rows
                      ..._statusTableData.map((row) {
                        String prefix = isIM3 ? '_IM3' : '_3ID';
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            color: _statusTableData.indexOf(row).isEven
                                ? Colors.white
                                : bgColor.withOpacity(0.1),
                          ),
                          child: Row(
                            children: [
                              _buildTableCell(
                                  row['ITEM$prefix'] ?? 'No Data', 0.55, false),
                              _buildTableCell(
                                  row['MTD$prefix'] ?? 'No Data', 0.75, true),
                              _buildTableCell(
                                  row['LMTD$prefix'] ?? 'No Data', 0.75, true),
                              _buildTableCell(
                                  row['GROWTH$prefix'] ?? 'No Data', 0.75, true,
                                  valueColor:
                                      _getGrowthColor(row['GROWTH$prefix'])),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation button
            Container(
              height: 24,
              margin: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment:
                    isIM3 ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (!isIM3)
                          Icon(Icons.arrow_back_ios,
                              size: 8, color: primaryColor),
                        const SizedBox(width: 2),
                        Text(
                          isIM3 ? "Next" : "Prev",
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        if (isIM3)
                          Icon(Icons.arrow_forward_ios,
                              size: 8, color: primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // RTV Table Card
  Widget _buildRTVTableCard(String title) {
    // Added default title
    final mediaQueryWidth = MediaQuery.of(context).size.width;

    // Colors with reduced intensity (using a single color scheme now)
    const primaryColor = Color.fromARGB(255, 235, 135, 193); // Example: Indigo
    const bgColor = Color.fromARGB(255, 238, 202, 222); // Example: Light Indigo

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: mediaQueryWidth * 0.875,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - simplified
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$title (Last Update: $lastUpdate)', // Include lastUpdate in title
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                      maxLines: 1,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Table
            Expanded(
              child: _isLoadingData // Check loading state
                  ? const Center(child: CircularProgressIndicator())
                  : _rtvTableData.isEmpty // Check if RTV data is empty
                      ? const Center(
                          child:
                              Text('No Data', style: TextStyle(fontSize: 10)))
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Header Row
                                Container(
                                  decoration: BoxDecoration(
                                    color: bgColor.withOpacity(0.7),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        _buildTableHeader(
                                            'ITEM', 0.75), // Adjusted flex
                                        _buildTableHeader('TARGET', 0.75),
                                        _buildTableHeader('ACTUAL', 0.75),
                                        _buildTableHeader('ACHV', 0.75),
                                      ],
                                    ),
                                  ),
                                ),

                                // Data Rows
                                ..._rtvTableData.map((row) {
                                  // Use _rtvTableData
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                          width: 1,
                                        ),
                                      ),
                                      color: _rtvTableData.indexOf(row).isEven
                                          ? Colors.white
                                          : bgColor.withOpacity(0.1),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildTableCell(
                                            row['ITEM'] ?? 'No Data',
                                            0.75,
                                            false), // Use direct keys
                                        _buildTableCell(
                                            row['TARGET'] ?? 'No Data',
                                            0.75,
                                            true),
                                        _buildTableCell(
                                            row['ACTUAL'] ?? 'No Data',
                                            0.75,
                                            true),
                                        _buildTableCell(
                                          row['ACHV'] ?? 'No Data',
                                          0.75,
                                          true,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
            ),

            // Removed Navigation button area
            const SizedBox(height: 24), // Keep consistent height if needed
          ],
        ),
      ),
    );
  }

  //_buildProfileTableCard
  Widget _buildProfileTableCard(String title) {
    final mediaQueryWidth = MediaQuery.of(context).size.width;

    // Colors with reduced intensity
    const primaryColor =
        Color.fromARGB(255, 71, 188, 100); // Example color, adjust as needed
    const bgColor =
        Color.fromARGB(255, 200, 230, 208); // Example color, adjust as needed

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: mediaQueryWidth * 0.875,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - simplified
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
                // Removed the IM3/3ID indicator container
              ],
            ),

            const SizedBox(height: 10),

            // Table
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : _profileTableData.isEmpty
                      ? const Center(
                          child:
                              Text('No Data', style: TextStyle(fontSize: 10)))
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Header Row
                                Container(
                                  decoration: BoxDecoration(
                                    color: bgColor.withOpacity(0.7),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        _buildTableHeader(
                                            'PROFILE', 1.0), // Adjusted flex
                                        _buildTableHeader(
                                            'JUMLAH', 1.0), // Adjusted flex
                                      ],
                                    ),
                                  ),
                                ),

                                // Data Rows
                                ..._profileTableData.map((row) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                          width: 1,
                                        ),
                                      ),
                                      color:
                                          _profileTableData.indexOf(row).isEven
                                              ? Colors.white
                                              : bgColor.withOpacity(0.1),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildTableCell(
                                            row['PROFILE'] ?? 'No Data',
                                            1.0, // Adjusted flex
                                            false),
                                        _buildTableCell(
                                            row['JUMLAH'] ?? 'No Data',
                                            1.0, // Adjusted flex
                                            true),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
            ),

            // Navigation button (Simplified or removed if not needed)
            Container(
              height: 24,
              margin: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          "Next", // Or keep as is, or remove
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios,
                            size: 8, color: primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //_buildManPowerTableCard
  Widget _buildManPowerTableCard(String title) {
    final mediaQueryWidth = MediaQuery.of(context).size.width;

    // Colors with reduced intensity
    const primaryColor = Color(0xFFAB47BC); // Example color, adjust as needed
    const bgColor = Color(0xFFF3E5F5); // Example color, adjust as needed

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: mediaQueryWidth * 0.875,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - simplified
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
                // Removed the IM3/3ID indicator container
              ],
            ),

            const SizedBox(height: 10),

            // Table
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : _manPowerTableData.isEmpty
                      ? const Center(
                          child:
                              Text('No Data', style: TextStyle(fontSize: 10)))
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Header Row
                                Container(
                                  decoration: BoxDecoration(
                                    color: bgColor.withOpacity(0.7),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        _buildTableHeader(
                                            'MAN_POWER', 1.0), // Adjusted flex
                                        _buildTableHeader(
                                            'JUMLAH', 1.0), // Adjusted flex
                                      ],
                                    ),
                                  ),
                                ),

                                // Data Rows
                                ..._manPowerTableData.map((row) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                          width: 1,
                                        ),
                                      ),
                                      color:
                                          _manPowerTableData.indexOf(row).isEven
                                              ? Colors.white
                                              : bgColor.withOpacity(0.1),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildTableCell(
                                            row['MAN_POWER'] ?? 'No Data',
                                            1.0, // Adjusted flex
                                            false),
                                        _buildTableCell(
                                            row['JUMLAH'] ?? 'No Data',
                                            1.0, // Adjusted flex
                                            true),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
            ),

            // Navigation button (Simplified or removed if not needed)
            Container(
              height: 24,
              margin: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start, // Or .end
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios,
                            size: 8, color: primaryColor),
                        SizedBox(width: 2),
                        Text(
                          "Prev", // Or keep as is, or remove
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        // Removed the conditional forward arrow
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dse Rural Table Card
  Widget _buildDseRuralTableCard(String title, bool isIM3) {
    final mediaQueryWidth = MediaQuery.of(context).size.width;

    // Colors with reduced intensity
    final primaryColor = isIM3
        ? const Color.fromARGB(255, 105, 39, 211)
        : const Color.fromARGB(255, 100, 121, 236);
    final bgColor = isIM3
        ? const Color.fromARGB(255, 200, 188, 219)
        : const Color.fromARGB(255, 204, 220, 240);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: mediaQueryWidth * 0.875,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - simplified with subtle colors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isIM3
                            ? Icons.insert_chart_outlined
                            : Icons.bar_chart_outlined,
                        size: 10,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isIM3 ? "IM3" : "3ID",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 10),

            // Table - No loading check here anymore
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              _buildTableHeader('ITEM', 0.55),
                              _buildTableHeader('MTD', 0.75),
                              _buildTableHeader('LMTD', 0.75),
                              _buildTableHeader('GROWTH', 0.75),
                            ],
                          ),
                        ),
                      ),

                      // Data Rows
                      ..._dseRuralTableData.map((row) {
                        String prefix = isIM3 ? '_IM3' : '_3ID';
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            color: _dseRuralTableData.indexOf(row).isEven
                                ? Colors.white
                                : bgColor.withOpacity(0.1),
                          ),
                          child: Row(
                            children: [
                              _buildTableCell(
                                  row['ITEM$prefix'] ?? 'No Data', 0.55, false),
                              _buildTableCell(
                                  row['MTD$prefix'] ?? 'No Data', 0.75, true),
                              _buildTableCell(
                                  row['LMTD$prefix'] ?? 'No Data', 0.75, true),
                              _buildTableCell(
                                  row['GROWTH$prefix'] ?? 'No Data', 0.75, true,
                                  valueColor:
                                      _getGrowthColor(row['GROWTH$prefix'])),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation button
            Container(
              height: 24,
              margin: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment:
                    isIM3 ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (!isIM3)
                          Icon(Icons.arrow_back_ios,
                              size: 8, color: primaryColor),
                        const SizedBox(width: 2),
                        Text(
                          isIM3 ? "Next" : "Prev",
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        if (isIM3)
                          Icon(Icons.arrow_forward_ios,
                              size: 8, color: primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Champions Table Card
  Widget _buildChampionsTableCard(String title, bool isIM3) {
    final mediaQueryWidth = MediaQuery.of(context).size.width;

    // Colors with reduced intensity
    final primaryColor =
        isIM3 ? const Color(0xFFAB47BC) : const Color(0xFFEC407A);
    final bgColor = isIM3 ? const Color(0xFFF3E5F5) : const Color(0xFFFCE4EC);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: mediaQueryWidth * 0.875,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - simplified with subtle colors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isIM3
                            ? Icons.insert_chart_outlined
                            : Icons.bar_chart_outlined,
                        size: 10,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isIM3 ? "IM3" : "3ID",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 10),

            // Table - No loading check here anymore
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              _buildTableHeader('ITEM', 0.55),
                              _buildTableHeader('MTD', 0.75),
                              _buildTableHeader('TARGET', 0.75),
                              _buildTableHeader('ACHV', 0.75),
                            ],
                          ),
                        ),
                      ),

                      // Data Rows
                      ..._championsTableData.map((row) {
                        String prefix = isIM3 ? '_IM3' : '_3ID';
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            color: _championsTableData.indexOf(row).isEven
                                ? Colors.white
                                : bgColor.withOpacity(0.1),
                          ),
                          child: Row(
                            children: [
                              _buildTableCell(
                                  row['ITEM$prefix'] ?? 'No Data', 0.55, false),
                              _buildTableCell(
                                  row['MTD$prefix'] ?? 'No Data', 0.75, true),
                              _buildTableCell(
                                  row['LMTD$prefix'] ?? 'No Data', 0.75, true),
                              _buildTableCell(
                                  row['GROWTH$prefix'] ?? 'No Data', 0.75, true,
                                  valueColor:
                                      _getGrowthColor(row['GROWTH$prefix'])),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation button
            Container(
              height: 24,
              margin: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment:
                    isIM3 ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (!isIM3)
                          Icon(Icons.arrow_back_ios,
                              size: 8, color: primaryColor),
                        const SizedBox(width: 2),
                        Text(
                          isIM3 ? "Next" : "Prev",
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        if (isIM3)
                          Icon(Icons.arrow_forward_ios,
                              size: 8, color: primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
