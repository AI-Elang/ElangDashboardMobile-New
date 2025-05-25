import 'package:elang_dashboard_new_ui/pt.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class Outlet extends StatefulWidget {
  const Outlet({super.key});

  @override
  State<Outlet> createState() => _OutletState();
}

class _OutletState extends State<Outlet> {
  // Helper function to format numbers with commas for values >= 999
  String _formatNumber(dynamic value) {
    if (value == null) return '0';

    // Convert value to string first
    String stringValue = value.toString();

    // Try parsing as int
    try {
      int intValue = int.parse(stringValue);

      // Apply formatting only if the value is >= 999
      if (intValue >= 999) {
        // Convert to string with comma separators
        return intValue.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
      }

      // Return as is if < 999
      return stringValue;
    } catch (e) {
      // If it can't be parsed as int, try as double
      try {
        double doubleValue = double.parse(stringValue);
        if (doubleValue >= 999) {
          return doubleValue.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
        }
        return stringValue;
      } catch (e) {
        // If not a valid number, return as is
        return stringValue;
      }
    }
  }

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
    return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
  }

  String? _selectedDropdown1 = 'Circle Java';
  String? _selectedDropdown2 = 'Pilih Region';
  String? _selectedDropdown3 = 'Pilih Area';
  String? _selectedDropdown4 = 'Pilih Branch';
  String _getTableHeaderText() {
    if (_selectedDropdown2 == 'Pilih Region') {
      return 'REGION ID';
    } else if (_selectedDropdown3 == 'Pilih Area') {
      return 'AREA ID';
    } else if (_selectedDropdown4 == 'Pilih Branch') {
      return 'BRANCH ID';
    } else {
      return 'MC ID';
    }
  }

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _subRegions = [];
  List<Map<String, dynamic>> _subAreas = [];
  List<Map<String, dynamic>> _mcData = [];

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

  bool _isLoadingTable = false;
  bool _isFiltersCollapsed =
      true; // Add a state variable to track if filters are collapsed

  var baseURL = dotenv.env['baseURL'];

  // REGION DATA (Dropdown 2)
  Future<void> fetchRegions(String? token) async {
    final url = '$baseURL/api/v1/dropdown/get-region?circle=1';
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
          // Tambahkan 'ALL' sebagai pilihan pertama
          _regions.insert(0, {'id': null, 'name': 'Pilih Region'});
          if (!_regions.any((r) => r['name'] == _selectedDropdown2)) {
            _selectedDropdown2 = 'Pilih Region';
          }
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  // AREA DATA (Dropdown 3)
  Future<void> fetchSubRegions(int regionId, String? token) async {
    final url = '$baseURL/api/v1/dropdown/get-region?circle=1&region=$regionId';

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
          // Tambahkan 'ALL' sebagai pilihan pertama
          _subRegions.insert(0, {'id': null, 'name': 'Pilih Area'});
          if (!_subRegions.any((sr) => sr['name'] == _selectedDropdown3)) {
            _selectedDropdown3 = 'Pilih Area';
          }
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  // BRANCH DATA (Dropdown 4)
  Future<void> fetchAreas(int regionId, int subRegionId, String? token) async {
    final url =
        '$baseURL/api/v1/dropdown/get-region?circle=1&region=$regionId&area=$subRegionId';
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
          _subAreas.insert(0, {'id': null, 'name': 'Pilih Branch'});
          if (!_subAreas.any((a) => a['name'] == _selectedDropdown4)) {
            _selectedDropdown4 = 'Pilih Branch';
          }
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  // MC DATA (Dropdown 5)
  Future<void> fetchMCData(int branchId, String? token) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final territory = authProvider.territory;
    final brand = authProvider.brand;
    final url = '$baseURL/api/v1/dropdown/get-region-mc?branch=$branchId';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> mcDataReceived = data['data'];

        setState(
          () {
            // Jika role MC (5), filter berdasarkan territory dan juga brand
            if (authProvider.role == 5) {
              _mcData = mcDataReceived
                  .where((mc) =>
                      mc['name'].toString().startsWith(territory) &&
                      mc['name'].toString().contains(brand))
                  .map((mc) => {'id': mc['id'], 'name': mc['name']})
                  .toList();
            } else {
              // Untuk role lain (termasuk Circle), tampilkan semua data
              _mcData = mcDataReceived
                  .map((mc) => {'id': mc['id'], 'name': mc['name']})
                  .toList();
            }
          },
        );
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  // Inisialisasi dropdown yang terkunci
  Future<void> _initializeLockedDropdowns() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    await authProvider.fetchLockedDropdown();

    if (!mounted) return;

    setState(() {
      _selectedDropdown1 = 'Circle Java';
    });

    // Initialize region dropdown and wait until complete
    await fetchRegions(token);

    if (!mounted) return;

    setState(() {
      // Find the region by ID, default to first item if not found
      final regionItem = _regions.firstWhere(
        (r) => r['id'] == authProvider.region,
        orElse: () => _regions.first,
      );

      _selectedDropdown2 = regionItem['name'];
    });

    // Initialize area dropdown if region exists
    if (authProvider.region != 0) {
      await fetchSubRegions(authProvider.region, token);
      if (!mounted) return;

      setState(() {
        // Find the area by ID, default to first item if not found
        final areaItem = _subRegions.firstWhere(
          (a) => a['id'] == authProvider.area,
          orElse: () => _subRegions.first,
        );
        _selectedDropdown3 = areaItem['name'];
      });

      // Initialize branch dropdown if area exists
      if (authProvider.area != 0) {
        await fetchAreas(authProvider.region, authProvider.area, token);
        if (!mounted) return;

        setState(() {
          // Find the branch by ID, default to first item if not found
          final branchItem = _subAreas.firstWhere(
            (b) => b['id'] == authProvider.branch,
            orElse: () => _subAreas.first,
          );
          _selectedDropdown4 = branchItem['name'];
        });

        // Initialize MC dropdown if branch exists
        if (authProvider.branch != 0) {
          await fetchMCData(authProvider.branch, token);
        }
      }
    }
  }

  // Fetch DSE Report data
  Future<void> fetchDashboardOutlet({
    int? circleId,
    int? regionId,
    int? areaId,
    int? branchId,
    String? token,
  }) async {
    setState(() {
      _isLoadingTable = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    circleId = 1;

    // Start with base URL and circle parameter
    String url = '$baseURL/api/v1/outlet/dashboard?circle=$circleId';

    // Build URL parameters in order
    if (_selectedDropdown2 != 'Pilih Region') {
      regionId =
          _regions.firstWhere((r) => r['name'] == _selectedDropdown2)['id'];
      url += '&region=$regionId';
    }

    if (_selectedDropdown3 != 'Pilih Area') {
      areaId =
          _subRegions.firstWhere((a) => a['name'] == _selectedDropdown3)['id'];
      url += '&area=$areaId';
    }

    if (_selectedDropdown4 != 'Pilih Branch') {
      branchId =
          _subAreas.firstWhere((b) => b['name'] == _selectedDropdown4)['id'];
      url += '&branch=$branchId';
    }

    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> reportData = data['data'];

        setState(() {
          // Filter MC data based on territory and brand for role 5
          if (authProvider.role == 5) {
            _mcData = reportData
                .where((mc) =>
                    mc['name'].toString().startsWith(authProvider.territory) &&
                    mc['name'].toString().contains(authProvider.brand))
                .map((item) => {
                      'id': item['id'],
                      'name': item['name'],
                      'outlet_count': item['outlet_count'] ?? '0',
                      'PestaIM3': item['PestaIM3'] ?? '0',
                      'FUNtasTRI': item['FUNtasTRI'] ?? '0',
                    })
                .toList();
          } else {
            // For other roles, show all data
            _mcData = reportData
                .map((item) => {
                      'id': item['id'],
                      'name': item['name'],
                      'outlet_count': item['outlet_count'] ?? '0',
                      'PestaIM3': item['PestaIM3'] ?? '0',
                      'FUNtasTRI': item['FUNtasTRI'] ?? '0',
                    })
                .toList();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching data')),
      );
    } finally {
      setState(() {
        _isLoadingTable = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Fetch initial data
      if (authProvider.role >= 1 && authProvider.role <= 5) {
        await _initializeLockedDropdowns();
        // No need to call fetchRegions here again as it's called in _initializeLockedDropdowns
        fetchDashboardOutlet(token: authProvider.token);
      } else {
        await fetchRegions(token);
        fetchDashboardOutlet(token: authProvider.token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    // final mediaQueryWidth = MediaQuery.of(context).size.width; // Keep if needed elsewhere
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define color scheme - matching dse_report style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray
    final headerTableTextColor =
        primaryColor.withOpacity(0.8); // For table headers

    return Scaffold(
      backgroundColor: backgroundColor, // Use defined background color
      body: SafeArea(
        child: Stack(
          children: [
            // App structure
            Column(
              children: [
                // Header container with gradient (like dse_report)
                Container(
                  height: mediaQueryHeight * 0.06, // Adjusted height
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
                      child: Text(
                        'OUTLET', // Updated title
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main content area
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: backgroundColor, // Use defined background color
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08, // Adjusted opacity
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // User profile and filters section (Card like dse_report)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  // User info row (like dse_report)
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
                                            color: accentColor.withOpacity(0.6),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const CircleAvatar(
                                          radius: 30, // Adjusted size
                                          backgroundImage:
                                              AssetImage('assets/100.png'),
                                          backgroundColor: Colors.transparent,
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
                                      // Date info
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color:
                                                  primaryColor.withOpacity(0.1),
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
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),

                                  // Filters section with collapsible functionality
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Filter header with toggle icon
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Filters",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                          InkWell(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            onTap: () {
                                              setState(() {
                                                _isFiltersCollapsed =
                                                    !_isFiltersCollapsed;
                                              });
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: AnimatedRotation(
                                                turns: _isFiltersCollapsed
                                                    ? 0.25 // Pointing right/down
                                                    : 0, // Pointing down/up
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                child: Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.black
                                                      .withOpacity(0.7),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Animated container for filters content
                                      AnimatedCrossFade(
                                        firstChild: const SizedBox(
                                          height: 0,
                                          width: double.infinity,
                                        ),
                                        secondChild: Column(
                                          children: [
                                            const SizedBox(height: 8),
                                            // Filter cards grid
                                            Container(
                                              decoration: BoxDecoration(
                                                color: backgroundColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                children: [
                                                  // First row of filters
                                                  Row(
                                                    children: [
                                                      // Circle filter
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Circle",
                                                          _selectedDropdown1!,
                                                          _isDropdownLocked(1),
                                                          (value) {
                                                            setState(() {
                                                              _selectedDropdown1 =
                                                                  value;
                                                              final authProvider =
                                                                  Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                              fetchDashboardOutlet(
                                                                  token:
                                                                      authProvider
                                                                          .token);
                                                            });
                                                          },
                                                          ['Circle Java'],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      // Region filter
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Region",
                                                          _selectedDropdown2!,
                                                          _isDropdownLocked(2),
                                                          (value) {
                                                            setState(() {
                                                              _selectedDropdown2 =
                                                                  value;
                                                              _selectedDropdown3 =
                                                                  'Pilih Area';
                                                              _selectedDropdown4 =
                                                                  'Pilih Branch';
                                                              _subRegions
                                                                  .clear();
                                                              _subAreas.clear();
                                                              _mcData.clear();

                                                              final authProvider =
                                                                  Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                              if (value ==
                                                                  'Pilih Region') {
                                                                fetchDashboardOutlet(
                                                                    token: authProvider
                                                                        .token);
                                                              } else {
                                                                int regionId =
                                                                    _regions
                                                                        .firstWhere(
                                                                  (r) =>
                                                                      r['name'] ==
                                                                      value,
                                                                )['id'];
                                                                fetchSubRegions(
                                                                    regionId,
                                                                    authProvider
                                                                        .token);
                                                                fetchDashboardOutlet(
                                                                    token: authProvider
                                                                        .token);
                                                              }
                                                            });
                                                          },
                                                          _regions
                                                              .map((r) =>
                                                                  r['name']
                                                                      as String)
                                                              .toList(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Second row of filters
                                                  Row(
                                                    children: [
                                                      // Area filter
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Area",
                                                          _selectedDropdown3!,
                                                          _isDropdownLocked(3),
                                                          (value) {
                                                            setState(() {
                                                              _selectedDropdown3 =
                                                                  value;
                                                              _selectedDropdown4 =
                                                                  'Pilih Branch';
                                                              _subAreas.clear();
                                                              _mcData.clear();

                                                              final authProvider =
                                                                  Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                              if (value ==
                                                                  'Pilih Area') {
                                                                fetchDashboardOutlet(
                                                                    token: authProvider
                                                                        .token);
                                                              } else {
                                                                int areaId =
                                                                    _subRegions
                                                                        .firstWhere(
                                                                  (sr) =>
                                                                      sr['name'] ==
                                                                      value,
                                                                )['id'];
                                                                int regionId =
                                                                    _regions
                                                                        .firstWhere(
                                                                  (r) =>
                                                                      r['name'] ==
                                                                      _selectedDropdown2,
                                                                )['id'];
                                                                fetchAreas(
                                                                    regionId,
                                                                    areaId,
                                                                    authProvider
                                                                        .token);
                                                                fetchDashboardOutlet(
                                                                    token: authProvider
                                                                        .token);
                                                              }
                                                            });
                                                          },
                                                          _subRegions
                                                              .map((sr) =>
                                                                  sr['name']
                                                                      as String)
                                                              .toList(),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      // Branch filter
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Branch",
                                                          _selectedDropdown4!,
                                                          _isDropdownLocked(4),
                                                          (value) {
                                                            setState(() {
                                                              _selectedDropdown4 =
                                                                  value;
                                                              _mcData.clear();

                                                              final authProvider =
                                                                  Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                              if (value ==
                                                                  'Pilih Branch') {
                                                                fetchDashboardOutlet(
                                                                    token: authProvider
                                                                        .token);
                                                              } else {
                                                                int branchId =
                                                                    _subAreas
                                                                        .firstWhere(
                                                                  (area) =>
                                                                      area[
                                                                          'name'] ==
                                                                      value,
                                                                )['id'];
                                                                fetchMCData(
                                                                    branchId,
                                                                    authProvider
                                                                        .token);
                                                                fetchDashboardOutlet(
                                                                    token: authProvider
                                                                        .token);
                                                              }
                                                            });
                                                          },
                                                          _subAreas
                                                              .map((a) =>
                                                                  a['name']
                                                                      as String)
                                                              .toList(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        crossFadeState: _isFiltersCollapsed
                                            ? CrossFadeState.showFirst
                                            : CrossFadeState.showSecond,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        reverseDuration:
                                            const Duration(milliseconds: 200),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                            height: 16), // Spacing before table header

                        // Outlet List Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_mcData.length} entries', // Show entry count
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16), // Spacing before table

                        // Data table section
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _isLoadingTable
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _mcData.isNotEmpty
                                    ? Container(
                                        // Container for table styling
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          // Added ClipRRect for consistent corner clipping
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                          child: SingleChildScrollView(
                                            // Vertical scroll for rows
                                            child: Padding(
                                              // Padding inside the "card" before the border/table
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Container(
                                                // Container for border around the table
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade200),
                                                ),
                                                child: ClipRRect(
                                                  // Clip for the inner table border radius
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  child: Row(
                                                    // Removed intermediate Column
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // ID Column - Fixed Left
                                                      SizedBox(
                                                        // Constrain width of fixed column
                                                        width:
                                                            185, // Adjust as needed
                                                        child: DataTable(
                                                          horizontalMargin:
                                                              8, // Matched
                                                          columnSpacing:
                                                              4, // Matched
                                                          headingRowHeight:
                                                              36, // Matched
                                                          dataRowHeight:
                                                              32, // Matched
                                                          headingRowColor:
                                                              WidgetStateProperty
                                                                  .all(
                                                            primaryColor
                                                                .withOpacity(
                                                                    0.1), // Matched
                                                          ),
                                                          // Removed border here, parent container has it
                                                          columns: [
                                                            _buildStyledColumn(
                                                              // Use updated helper
                                                              _getTableHeaderText(),
                                                              headerTableTextColor,
                                                              isHeaderLeft:
                                                                  true,
                                                            ),
                                                          ],
                                                          rows:
                                                              _mcData.map((mc) {
                                                            final index =
                                                                _mcData.indexOf(
                                                                    mc);
                                                            return DataRow(
                                                              color: WidgetStateProperty
                                                                  .resolveWith<
                                                                      Color>(
                                                                (states) => index %
                                                                            2 ==
                                                                        0
                                                                    ? Colors
                                                                        .white
                                                                    : const Color(
                                                                        0xFFFAFAFF),
                                                              ),
                                                              cells: [
                                                                _buildStyledDataCell(
                                                                  // Use updated helper
                                                                  mc['name']
                                                                      .toString(),
                                                                  isLeftAligned:
                                                                      true,
                                                                  isTappable:
                                                                      _getTableHeaderText() ==
                                                                          'MC ID',
                                                                  onTap: _getTableHeaderText() ==
                                                                          'MC ID'
                                                                      ? () {
                                                                          Navigator
                                                                              .push(
                                                                            context,
                                                                            MaterialPageRoute(
                                                                              builder: (context) => PT(
                                                                                mcId: int.parse(mc['id'].toString()),
                                                                                selectedRegion: _selectedDropdown2 ?? 'Pilih Region',
                                                                                selectedArea: _selectedDropdown3 ?? 'Pilih Area',
                                                                                selectedBranch: _selectedDropdown4 ?? 'Pilih Branch',
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                      : null,
                                                                  textColor: _getTableHeaderText() !=
                                                                          'MC ID'
                                                                      ? textPrimaryColor
                                                                      : null,
                                                                ),
                                                              ],
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),

                                                      // Scrollable parameters columns
                                                      Expanded(
                                                        child:
                                                            SingleChildScrollView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          child: ConstrainedBox(
                                                            // Added ConstrainedBox
                                                            constraints:
                                                                const BoxConstraints(
                                                                    minWidth:
                                                                        250), // Adjust minWidth
                                                            child: DataTable(
                                                              horizontalMargin:
                                                                  8, // Matched
                                                              columnSpacing:
                                                                  10, // Matched
                                                              headingRowHeight:
                                                                  36, // Matched
                                                              dataRowHeight:
                                                                  32, // Matched
                                                              headingRowColor:
                                                                  WidgetStateProperty
                                                                      .all(
                                                                primaryColor
                                                                    .withOpacity(
                                                                        0.1), // Matched
                                                              ),
                                                              // Removed border
                                                              columns: [
                                                                _buildStyledColumn(
                                                                    'OUTLET COUNT',
                                                                    headerTableTextColor),
                                                                _buildStyledColumn(
                                                                    'PESTA IM3',
                                                                    headerTableTextColor),
                                                                _buildStyledColumn(
                                                                    'FUNTAS TRI',
                                                                    headerTableTextColor),
                                                              ],
                                                              rows: _mcData
                                                                  .map((mc) {
                                                                final index =
                                                                    _mcData
                                                                        .indexOf(
                                                                            mc);
                                                                return DataRow(
                                                                  color: WidgetStateProperty
                                                                      .resolveWith<
                                                                          Color>(
                                                                    (states) => index %
                                                                                2 ==
                                                                            0
                                                                        ? Colors
                                                                            .white
                                                                        : const Color(
                                                                            0xFFFAFAFF),
                                                                  ),
                                                                  cells: [
                                                                    _buildStyledDataCell(_formatNumber(
                                                                        mc['outlet_count'] ??
                                                                            '0')),
                                                                    _buildStyledDataCell(_formatNumber(
                                                                        mc['PestaIM3'] ??
                                                                            '0')),
                                                                    _buildStyledDataCell(_formatNumber(
                                                                        mc['FUNtasTRI'] ??
                                                                            '0')),
                                                                  ],
                                                                );
                                                              }).toList(),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : _buildEmptyState('No Data Available',
                                        'Try changing filters'), // Use helper for empty state
                          ),
                        ),
                        const SizedBox(
                            height: 75), // Spacing before bottom navigation
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom navigation bar (styled like dse_report)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60, // Adjusted height
                decoration: BoxDecoration(
                  color: cardColor, // Use card color
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20), // Rounded corners
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15), // Softer shadow
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Home Button (styled like dse_report)
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Homepage()),
                        );
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home, // Use appropriate icon
                            color: primaryColor, // Use primary color
                            size: 22, // Adjust size
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Home', // Label
                            style: TextStyle(
                              color: primaryColor, // Use primary color
                              fontSize: 11, // Adjust size
                              fontWeight: FontWeight.w600, // Adjust weight
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add other navigation items here if needed, following the same style
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build filter dropdowns (copied from dse_report style)
  Widget _buildFilterDropdown(
    String label,
    String value,
    bool isLocked,
    Function(String) onChanged,
    List<String> items,
  ) {
    // Define colors locally or pass them if needed
    const textPrimaryColor = Color(0xFF2D3142);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Background for dropdown area
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600, // Lighter color for label
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4), // Spacing between label and dropdown
          DropdownButtonHideUnderline(
            // Hides the default underline
            child: DropdownButton<String>(
              value: value,
              isDense: true, // Reduces vertical padding
              isExpanded: true, // Makes dropdown take available width
              icon: Icon(
                Icons.arrow_drop_down, // Standard dropdown icon
                color: isLocked
                    ? Colors.grey.shade400
                    : Colors.grey.shade700, // Icon color based on lock state
              ),
              onChanged: (_isLoadingTable || isLocked)
                  ? null
                  : (newValue) =>
                      onChanged(newValue!), // Disable if loading or locked
              items: items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12, // Font size for items
                      color: (_isLoadingTable || isLocked)
                          ? Colors.grey
                          : textPrimaryColor, // Text color based on state
                      fontWeight: FontWeight.w500,
                    ),
                    overflow:
                        TextOverflow.ellipsis, // Prevent long text overflow
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for styled table columns and cells (Updated to match reusable_data_table_section.dart)
  DataColumn _buildStyledColumn(String title, Color headerTextColor,
      {bool isHeaderLeft = false}) {
    return DataColumn(
      label: Container(
        alignment: isHeaderLeft ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11, // Matched
            fontWeight: FontWeight.w600, // Matched
            color: headerTextColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  DataCell _buildStyledDataCell(
    String text, {
    bool isLeftAligned = false,
    VoidCallback? onTap,
    bool isTappable = false,
    Color? textColor,
    FontWeight? fontWeight,
  }) {
    Widget cellContent = Text(
      text,
      style: TextStyle(
        fontSize: 11, // Matched
        color: isTappable ? Colors.blue : (textColor ?? Colors.grey.shade800),
        fontWeight: fontWeight ?? FontWeight.w500, // Matched
        decoration: isTappable ? TextDecoration.underline : TextDecoration.none,
      ),
      overflow: TextOverflow.ellipsis,
    );

    if (onTap != null) {
      cellContent = InkWell(
        onTap: onTap,
        child: cellContent,
      );
    }

    return DataCell(
      Container(
        alignment: isLeftAligned ? Alignment.centerLeft : Alignment.centerRight,
        padding:
            const EdgeInsets.symmetric(vertical: 4, horizontal: 4.0), // Matched
        child: cellContent,
      ),
    );
  }

  // Helper method to build empty state (copied from dse_report style)
  Widget _buildEmptyState(String title, String subtitle) {
    const textPrimaryColor = Color(0xFF2D3142);
    const textSecondaryColor = Color(0xFF8D8D92);

    return Container(
      // Wrap in a container for potential styling or margin
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Match card background
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.grey.shade200, width: 1), // Subtle border
      ),
      child: Center(
        child: Padding(
          // Add padding inside the empty state
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take minimum space
            children: [
              Icon(
                Icons.search_off_rounded, // Icon indicating no results
                size: 48,
                color: Colors.grey.shade400, // Muted color for icon
              ),
              const SizedBox(height: 12), // Space between icon and text
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor, // Use defined primary text color
                ),
              ),
              const SizedBox(height: 4), // Space between title and subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondaryColor, // Use defined secondary text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
