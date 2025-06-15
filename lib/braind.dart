import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:elang_dashboard_new_ui/widgets/reusable_data_table_section.dart';

import 'dart:convert';

class Braind extends StatefulWidget {
  const Braind({super.key});

  @override
  State<Braind> createState() => _BraindState();
}

class _BraindState extends State<Braind> {
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
  final bool _isLoading =
      false; // Added for consistency with dse.dart UI patterns
  bool _isFiltersCollapsed = true; // For collapsible filters

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

  // Initialize locked dropdowns
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

  // Fetch Braind data
  Future<void> fetchDashboardBraind({
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
    String url = '$baseURL/api/v1/brand-stock/dashboard/?circle=$circleId';

    // Build URL parameters in order
    if (_selectedDropdown2 != 'Pilih Region' && _selectedDropdown2 != null) {
      final region = _regions.firstWhere((r) => r['name'] == _selectedDropdown2,
          orElse: () => <String, dynamic>{});
      if (region.isNotEmpty && region['id'] != null) {
        regionId = region['id'];
        url += '&region=$regionId';
      }
    }

    if (_selectedDropdown3 != 'Pilih Area' && _selectedDropdown3 != null) {
      final area = _subRegions.firstWhere(
          (a) => a['name'] == _selectedDropdown3,
          orElse: () => <String, dynamic>{});
      if (area.isNotEmpty && area['id'] != null) {
        areaId = area['id'];
        url += '&area=$areaId';
      }
    }

    if (_selectedDropdown4 != 'Pilih Branch' && _selectedDropdown4 != null) {
      final branch = _subAreas.firstWhere(
          (b) => b['name'] == _selectedDropdown4,
          orElse: () => <String, dynamic>{});
      if (branch.isNotEmpty && branch['id'] != null) {
        branchId = branch['id'];
        url += '&branch=$branchId';
      }
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
                      'matpro': item['matpro'],
                      'promo': item['promo'],
                      'allocation': item['allocation'] ?? '0',
                      'actual': item['actual'] ?? '0',
                      'remainder': item['remainder'] ?? '0',
                    })
                .toList();
          } else {
            // For other roles, show all data
            _mcData = reportData
                .map((item) => {
                      'matpro': item['matpro'],
                      'promo': item['promo'],
                      'allocation': item['allocation'] ?? '0',
                      'actual': item['actual'] ?? '0',
                      'remainder': item['remainder'] ?? '0',
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
      // The user requested no changes to logic, so _isLoading is not set here.
      // It's available for _buildFilterDropdown if its logic were to be fully aligned with dse.dart's fetch cycles.
      try {
        if (authProvider.role >= 1 && authProvider.role <= 5) {
          await _initializeLockedDropdowns();
          // After initializing, fetch dashboard data based on pre-filled filters
          fetchDashboardBraind(token: authProvider.token);
        } else {
          await fetchRegions(token);
          fetchDashboardBraind(token: authProvider.token);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error initializing page: ${e.toString()}')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    // final mediaQueryWidth = MediaQuery.of(context).size.width; // Not used in new design
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define our color scheme - matching dse.dart style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content column
            Column(
              children: [
                // Header container from dse.dart
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
                      child: Text(
                        'BRAIND',
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
                      color:
                          backgroundColor, // Use the defined background color
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO3.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08, // Softer opacity
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: SingleChildScrollView(
                      // Wrap Column with SingleChildScrollView
                      child: Column(
                        children: [
                          // Profile & Filters Card
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
                                    // User info row
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  accentColor.withOpacity(0.6),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const CircleAvatar(
                                            radius: 30,
                                            backgroundImage:
                                                AssetImage('assets/LOGO3.png'),
                                            backgroundColor: Colors.transparent,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
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
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),

                                    // Filters section
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
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
                                                      ? 0.25
                                                      : 0,
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
                                        AnimatedCrossFade(
                                          firstChild: const SizedBox(
                                              height: 0,
                                              width: double.infinity),
                                          secondChild: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: backgroundColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Circle",
                                                          _selectedDropdown1!,
                                                          _isDropdownLocked(
                                                              1), // Pass lock status
                                                          (newValue) {
                                                            setState(() {
                                                              _selectedDropdown1 =
                                                                  newValue;
                                                              final authProvider =
                                                                  Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                              fetchDashboardBraind(
                                                                  token:
                                                                      authProvider
                                                                          .token);
                                                            });
                                                          },
                                                          ['Circle Java'],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Region",
                                                          _selectedDropdown2!,
                                                          _isDropdownLocked(
                                                              2), // Pass lock status
                                                          (newValue) {
                                                            setState(() {
                                                              _selectedDropdown2 =
                                                                  newValue;
                                                              _selectedDropdown3 =
                                                                  'Pilih Area';
                                                              _selectedDropdown4 =
                                                                  'Pilih Branch';
                                                              _subRegions
                                                                  .clear();
                                                              _subAreas.clear();
                                                              _mcData
                                                                  .clear(); // Clear table data

                                                              final authProvider =
                                                                  Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                              if (newValue ==
                                                                  'Pilih Region') {
                                                                fetchDashboardBraind(
                                                                    token: authProvider
                                                                        .token);
                                                              } else {
                                                                int regionId = _regions
                                                                    .firstWhere((r) =>
                                                                        r['name'] ==
                                                                        newValue)['id'];
                                                                fetchSubRegions(
                                                                    regionId,
                                                                    authProvider
                                                                        .token);
                                                                fetchDashboardBraind(
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
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Area",
                                                          _selectedDropdown3!,
                                                          _isDropdownLocked(
                                                              3), // Pass lock status
                                                          (newValue) {
                                                            setState(() {
                                                              _selectedDropdown3 =
                                                                  newValue;
                                                              _selectedDropdown4 =
                                                                  'Pilih Branch';
                                                              _subAreas.clear();
                                                              _mcData
                                                                  .clear(); // Clear table data

                                                              final authProvider =
                                                                  Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                              if (newValue ==
                                                                  'Pilih Area') {
                                                                fetchDashboardBraind(
                                                                    token: authProvider
                                                                        .token);
                                                              } else {
                                                                int areaId = _subRegions
                                                                    .firstWhere((sr) =>
                                                                        sr['name'] ==
                                                                        newValue)['id'];
                                                                int regionId = _regions
                                                                    .firstWhere((r) =>
                                                                        r['name'] ==
                                                                        _selectedDropdown2)['id'];
                                                                fetchAreas(
                                                                    regionId,
                                                                    areaId,
                                                                    authProvider
                                                                        .token);
                                                                fetchDashboardBraind(
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
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Branch",
                                                          _selectedDropdown4!,
                                                          _isDropdownLocked(
                                                              4), // Pass lock status
                                                          (newValue) {
                                                            setState(() {
                                                              _selectedDropdown4 =
                                                                  newValue;
                                                              _mcData
                                                                  .clear(); // Clear table data

                                                              final authProvider =
                                                                  Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                              if (newValue ==
                                                                  'Pilih Branch') {
                                                                fetchDashboardBraind(
                                                                    token: authProvider
                                                                        .token);
                                                              } else {
                                                                // int branchId = _subAreas.firstWhere((area) => area['name'] == newValue)['id'];
                                                                // fetchMCData(branchId, authProvider.token); // This was for a different dropdown in original code
                                                                fetchDashboardBraind(
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

                          const SizedBox(height: 2),

                          // Data Section Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20), // Adjusted padding
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
                                    '${_mcData.length} entries',
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
                          const SizedBox(height: 8),

                          // Data Table Area - SCROLLABLE
                          Padding(
                            // This Padding was the child of the removed Expanded
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ReusableDataTableSection(
                              title: 'BRAIND Data',
                              icon: Icons.table_chart_outlined,
                              sectionColor: primaryColor,
                              textPrimaryColor: textPrimaryColor,
                              cardColor: cardColor,
                              data: _mcData,
                              fixedColumn: const {
                                'key': 'matpro',
                                'header': 'MATPRO',
                                'width': 100.0
                              },
                              scrollableColumns: const [
                                {'key': 'promo', 'header': 'PROMO'},
                                {'key': 'allocation', 'header': 'ALLOCATION'},
                                {'key': 'actual', 'header': 'ACTUAL'},
                                {'key': 'remainder', 'header': 'REMAINDER'},
                              ],
                              isLoading: _isLoadingTable,
                              emptyStateTitle: 'No BRAIND Data Found',
                              emptyStateSubtitle:
                                  'Select filters to load data or data is empty.',
                              emptyStateIcon: Icons.table_chart_outlined,
                              numberFormatter: (dynamic value) {
                                // Basic formatter, adjust if specific numeric formatting is needed
                                return value?.toString() ?? '0';
                              },
                              // onFixedCellTap: (rowData) {
                              //   // Define action if MATPRO cell tap is needed
                              //   print('Tapped on MATPRO: ${rowData['matpro']}');
                              // },
                            ),
                          ),
                          const SizedBox(
                              height: 90), // Space for bottom nav bar
                        ],
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
                height: 60, // Standard height
                decoration: BoxDecoration(
                  color: cardColor, // Use cardColor for consistency
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
                            Icons.home, // Or Icons.home
                            color: primaryColor,
                            size: 22,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Home',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add other navigation items here if needed
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build styled dropdowns (adapted from dse.dart)
  Widget _buildFilterDropdown(
    String label,
    String? value, // Changed to String?
    bool isLocked,
    Function(String)
        onChanged, // Remains Function(String) as "Pilih X" are items
    List<String> items,
  ) {
    final bool isDisabled =
        isLocked || _isLoading; // _isLoading is from _DseState
    final String? displayValue = value;

    // Define colors (matching dse.dart style)
    final Color enabledBorderColor = Colors.grey.shade300;
    final Color disabledBorderColor = Colors.grey.shade200;
    const Color enabledTextColor = Color(0xFF2D3142); // textPrimaryColor
    final Color disabledTextColor = Colors.grey.shade500;
    final Color labelTextColor = Colors.grey.shade600;
    final Color hintTextColorLocal = Colors.grey.shade500;
    const Color primaryThemeColor = Color(0xFF6A62B7); // primaryColor

    Widget hintForDropdownButton = Text(
      "Pilih $label", // Default hint text
      style: TextStyle(
        fontSize: 11,
        color: isDisabled
            ? disabledTextColor.withOpacity(0.7)
            : hintTextColorLocal,
        fontWeight: FontWeight.w500,
      ),
      softWrap: true, // Ensure hint text wraps
      // Removed overflow: TextOverflow.ellipsis to allow wrapping
    );

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10.0, vertical: 4.0), // Reduced vertical padding
      decoration: BoxDecoration(
        color: isDisabled
            ? Colors.grey.shade100
            : Colors.white, // cardColor is Colors.white
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDisabled ? disabledBorderColor : enabledBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              color: Colors.grey.withOpacity(0.08), // Softer shadow
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Important for column height
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9, // Smaller label
              fontWeight: FontWeight.w500,
              color: isDisabled ? disabledTextColor : labelTextColor,
            ),
          ),
          const SizedBox(height: 5.0), // Added spacing
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  displayValue, // This will be "Pilih X" if that's the current state value
              hint: hintForDropdownButton, // Shown if displayValue is null
              isDense: true, // Makes the dropdown vertically compact
              isExpanded:
                  true, // Allows the dropdown to expand and text to wrap
              style: TextStyle(
                // Style for the selected item text
                fontSize: 11, // Compact item text
                color: isDisabled ? disabledTextColor : enabledTextColor,
                fontWeight: FontWeight.w500,
              ),
              icon:
                  _isLoading // Use _isLoading from _DseState for the icon state
                      ? const SizedBox(
                          width: 14, // Smaller loading indicator
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                primaryThemeColor),
                          ),
                        )
                      : Icon(
                          Icons.keyboard_arrow_down_rounded, // Modern icon
                          size: 20, // Adjust icon size
                          color: isDisabled
                              ? disabledTextColor
                              : Colors.grey.shade700,
                        ),
              onChanged: isDisabled
                  ? null
                  : (newValue) {
                      if (newValue != null) {
                        onChanged(newValue);
                      }
                    },
              items: items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    // Added padding for internal spacing
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2.0), // Small horizontal padding
                    child: Text(
                      item,
                      softWrap: true, // Ensure item text wraps
                      // Removed overflow property to allow full text display
                    ),
                  ),
                );
              }).toList(),
              selectedItemBuilder: (BuildContext context) {
                // Ensures selected item also wraps
                return items.map<Widget>((String item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      item,
                      softWrap: true, // Ensure selected item text wraps
                      style: TextStyle(
                        // Explicitly define style for selected item to ensure consistency
                        fontSize: 11,
                        color:
                            isDisabled ? disabledTextColor : enabledTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      // Removed overflow property to allow full text display
                    ),
                  );
                }).toList();
              },
              dropdownColor:
                  Colors.white, // Background of the dropdown menu (cardColor)
              elevation: 2, // Shadow for the dropdown menu
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ],
      ),
    );
  }
}
