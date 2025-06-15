import 'package:elang_dashboard_new_ui/switch_dse_report.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DseReport extends StatefulWidget {
  const DseReport({super.key});

  @override
  State<DseReport> createState() => _DseReportState();
}

class _DseReportState extends State<DseReport> {
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

  bool _isLoadingTable = false;
  bool _isLoading = false; // Add this line
  bool _isFiltersCollapsed =
      true; // Add a state variable to track if filters are collapsed
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

  DateTime selectedDate = DateTime.now();

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

  // Fetch DSE Report data
  Future<void> fetchDashboardDSEReport({
    int? circleId,
    int? regionId,
    int? areaId,
    int? branchId,
    String? token,
  }) async {
    // Set _isLoading true at the beginning
    setState(() {
      _isLoading = true;
      _isLoadingTable = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    circleId = 1;

    // Start with base URL and circle parameter
    String url = '$baseURL/api/v1/dse-ai/dashboard/data?circle=$circleId';

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

    // Add date parameter at the end
    url += '&date=$formattedDate';

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
                      'total_dse': item['total_dse'] ?? '0',
                      'dse_active': item['dse_active'] ?? '0',
                      'sp': item['sp'] ?? '0',
                      'vou': item['vou'] ?? '0',
                      'salmo': item['salmo'] ?? '0',
                      'outlet': item['outlet'] ?? '0',
                      'visit': item['visit'] ?? '0',
                    })
                .toList();
          } else {
            // For other roles, show all data
            _mcData = reportData
                .map((item) => {
                      'id': item['id'],
                      'name': item['name'],
                      'total_dse': item['total_dse'] ?? '0',
                      'dse_active': item['dse_active'] ?? '0',
                      'sp': item['sp'] ?? '0',
                      'vou': item['vou'] ?? '0',
                      'salmo': item['salmo'] ?? '0',
                      'outlet': item['outlet'] ?? '0',
                      'visit': item['visit'] ?? '0',
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
      // Set both loading states false in finally
      if (mounted) {
        setState(() {
          _isLoadingTable = false;
          _isLoading = false; // Add this line
        });
      }
    }
  }

  // Select date
  Future<void> _selectDate(BuildContext context) async {
    if (_isLoading) return; // Prevent action if already loading

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        // Don't set loading here, fetchDashboardDSEReport will handle it
      });
      // Call fetch function which now handles loading state
      await fetchDashboardDSEReport(
          token: Provider.of<AuthProvider>(context, listen: false).token);
    }
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Set loading true at the start of initial fetch
      setState(() {
        _isLoading = true;
        _isLoadingTable = true;
      });
      try {
        if (authProvider.role >= 2 && authProvider.role <= 5) {
          await _initializeLockedDropdowns();
          // fetchDashboardDSEReport is called within _initializeLockedDropdowns or after
          // No need to call it again here explicitly for roles 2-5 if _initializeLockedDropdowns handles it
          // Ensure fetchDashboardDSEReport is called appropriately within or after _initializeLockedDropdowns
          // If _initializeLockedDropdowns doesn't call fetchDashboardDSEReport, call it here:
          // await fetchDashboardDSEReport(token: authProvider.token);
        } else {
          await fetchRegions(token);
          await fetchDashboardDSEReport(token: authProvider.token);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error initializing page')),
        );
      } finally {
        // Set loading false when initial fetch completes or fails
        if (mounted) {
          setState(() {
            _isLoading = false;
            // _isLoadingTable is handled by fetchDashboardDSEReport's finally block
          });
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
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define our color scheme - matching MC style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // App structure
            Column(
              children: [
                // Header container with gradient
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
                                'DSE REPORT',
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
                        image: AssetImage('assets/LOGO3.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // User profile and filters section
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
                                          radius: 30,
                                          backgroundImage:
                                              AssetImage('assets/LOGO3.png'),
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

                                      // Animated container for filters content
                                      AnimatedCrossFade(
                                        firstChild: const SizedBox(
                                          // This is an empty container with minimal height
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
                                                          (value) async {
                                                            // Make async
                                                            if (_isLoading) {
                                                              return; // Add check
                                                            }
                                                            // Set loading state handled by fetchDashboardDSEReport
                                                            setState(() {
                                                              _selectedDropdown1 =
                                                                  value;
                                                            });
                                                            await fetchDashboardDSEReport(
                                                              // await the fetch
                                                              token: Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .token,
                                                            );
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
                                                          (value) async {
                                                            // Make async
                                                            if (_isLoading) {
                                                              return; // Add check
                                                            }

                                                            // Set state immediately for UI feedback, but fetch handles main loading
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
                                                              // Set loading here before async operations
                                                              _isLoading = true;
                                                              _isLoadingTable =
                                                                  true;
                                                            });

                                                            final token =
                                                                Provider.of<AuthProvider>(
                                                                        context,
                                                                        listen:
                                                                            false)
                                                                    .token;
                                                            try {
                                                              if (value ==
                                                                  'Pilih Region') {
                                                                await fetchDashboardDSEReport(
                                                                    token:
                                                                        token);
                                                              } else {
                                                                int regionId = _regions
                                                                    .firstWhere((r) =>
                                                                        r['name'] ==
                                                                        value)['id'];
                                                                // Fetch sub-regions first
                                                                await fetchSubRegions(
                                                                    regionId,
                                                                    token);
                                                                // Then fetch the main report data
                                                                await fetchDashboardDSEReport(
                                                                    token:
                                                                        token);
                                                              }
                                                            } finally {
                                                              // Reset loading state regardless of success/failure
                                                              // Note: fetchDashboardDSEReport also sets these, potentially redundant but safe
                                                              if (mounted) {
                                                                setState(() {
                                                                  _isLoading =
                                                                      false;
                                                                  // _isLoadingTable is handled by fetchDashboardDSEReport
                                                                });
                                                              }
                                                            }
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
                                                          (value) async {
                                                            // Make async
                                                            if (_isLoading) {
                                                              return; // Add check
                                                            }

                                                            setState(() {
                                                              _selectedDropdown3 =
                                                                  value;
                                                              _selectedDropdown4 =
                                                                  'Pilih Branch';
                                                              _subAreas.clear();
                                                              _mcData.clear();
                                                              _isLoading = true;
                                                              _isLoadingTable =
                                                                  true;
                                                            });

                                                            final token =
                                                                Provider.of<AuthProvider>(
                                                                        context,
                                                                        listen:
                                                                            false)
                                                                    .token;
                                                            try {
                                                              if (value ==
                                                                  'Pilih Area') {
                                                                await fetchDashboardDSEReport(
                                                                    token:
                                                                        token);
                                                              } else {
                                                                int areaId = _subRegions
                                                                    .firstWhere((sr) =>
                                                                        sr['name'] ==
                                                                        value)['id'];
                                                                int regionId = _regions
                                                                    .firstWhere((r) =>
                                                                        r['name'] ==
                                                                        _selectedDropdown2)['id'];
                                                                await fetchAreas(
                                                                    regionId,
                                                                    areaId,
                                                                    token);
                                                                await fetchDashboardDSEReport(
                                                                    token:
                                                                        token);
                                                              }
                                                            } finally {
                                                              if (mounted) {
                                                                setState(() {
                                                                  _isLoading =
                                                                      false;
                                                                });
                                                              }
                                                            }
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
                                                          (value) async {
                                                            // Make async
                                                            if (_isLoading) {
                                                              return; // Add check
                                                            }

                                                            setState(() {
                                                              _selectedDropdown4 =
                                                                  value;
                                                              _mcData.clear();
                                                              _isLoading = true;
                                                              _isLoadingTable =
                                                                  true;
                                                            });

                                                            final token =
                                                                Provider.of<AuthProvider>(
                                                                        context,
                                                                        listen:
                                                                            false)
                                                                    .token;
                                                            try {
                                                              if (value ==
                                                                  'Pilih Branch') {
                                                                await fetchDashboardDSEReport(
                                                                    token:
                                                                        token);
                                                              } else {
                                                                // Fetch MC data first if needed (though fetchDashboardDSEReport might be sufficient)
                                                                // await fetchMCData(branchId, token); // Decide if this is needed before the main report
                                                                await fetchDashboardDSEReport(
                                                                    token:
                                                                        token);
                                                              }
                                                            } finally {
                                                              if (mounted) {
                                                                setState(() {
                                                                  _isLoading =
                                                                      false;
                                                                });
                                                              }
                                                            }
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

                                      const SizedBox(height: 8),

                                      // Date picker
                                      InkWell(
                                        onTap: _isLoading
                                            ? null
                                            : () => _selectDate(
                                                context), // Disable onTap when loading
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: _isLoading
                                                ? Colors.grey.shade100
                                                : backgroundColor, // Visual feedback
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                color: _isLoading
                                                    ? Colors.grey.shade400
                                                    : Colors.grey
                                                        .shade600, // Dim icon
                                                size: 18,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                DateFormat('dd MMMM yyyy')
                                                    .format(selectedDate),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: _isLoading
                                                      ? Colors.grey.shade400
                                                      : textPrimaryColor, // Dim text
                                                ),
                                              ),
                                              const Spacer(),
                                              Icon(
                                                Icons.arrow_drop_down,
                                                color: _isLoading
                                                    ? Colors.grey.shade400
                                                    : Colors.grey
                                                        .shade600, // Dim icon
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // DSE Report List Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
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
                                _getTableHeaderText(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimaryColor,
                                ),
                              ),
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

                        const SizedBox(height: 16),

                        // Data table
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child:
                                _isLoadingTable // Keep using _isLoadingTable for the table indicator
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : _mcData.isNotEmpty
                                        ? Container(
                                            constraints: BoxConstraints(
                                              minHeight: 100,
                                              maxHeight:
                                                  mediaQueryHeight * 0.580,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                children: [
                                                  // Table Layout
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // ID Column - Fixed Left
                                                      DataTable(
                                                        horizontalMargin: 12,
                                                        columnSpacing: 8,
                                                        headingRowHeight: 40,
                                                        headingRowColor:
                                                            WidgetStateProperty
                                                                .all(
                                                          const Color(
                                                              0xFFF0F2FF),
                                                        ),
                                                        border: TableBorder(
                                                          top: BorderSide(
                                                              color: Colors.grey
                                                                  .shade200),
                                                          bottom: BorderSide(
                                                              color: Colors.grey
                                                                  .shade200),
                                                        ),
                                                        columns: [
                                                          DataColumn(
                                                            label: Text(
                                                              _getTableHeaderText(),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    primaryColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                        rows: _mcData
                                                            .map(
                                                                (mc) => DataRow(
                                                                      color: WidgetStateProperty.resolveWith<
                                                                              Color>(
                                                                          (states) {
                                                                        final index =
                                                                            _mcData.indexOf(mc);
                                                                        return index % 2 ==
                                                                                0
                                                                            ? Colors.white
                                                                            : const Color(0xFFFAFAFF);
                                                                      }),
                                                                      cells: [
                                                                        DataCell(
                                                                          (_getTableHeaderText() == 'MC ID')
                                                                              ? InkWell(
                                                                                  onTap: _isLoading
                                                                                      ? null
                                                                                      : () {
                                                                                          // Disable onTap when loading
                                                                                          Navigator.push(
                                                                                            context,
                                                                                            MaterialPageRoute(
                                                                                              builder: (context) => SwitchDseReport(
                                                                                                mcId: mc['id'],
                                                                                                selectedRegion: _selectedDropdown2!,
                                                                                                selectedArea: _selectedDropdown3!,
                                                                                                selectedBranch: _selectedDropdown4!,
                                                                                              ),
                                                                                            ),
                                                                                          );
                                                                                        },
                                                                                  child: Container(
                                                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                                                    child: Text(
                                                                                      mc['name'].toString(),
                                                                                      style: TextStyle(
                                                                                        // Adjust style when disabled
                                                                                        fontSize: 12,
                                                                                        color: _isLoading ? Colors.grey : Colors.blue,
                                                                                        decoration: _isLoading ? TextDecoration.none : TextDecoration.underline,
                                                                                        fontWeight: FontWeight.w500,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                )
                                                                              : Container(
                                                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                                                  child: Text(
                                                                                    mc['name'].toString(),
                                                                                    style: const TextStyle(
                                                                                      fontSize: 12,
                                                                                      fontWeight: FontWeight.w500,
                                                                                      color: textPrimaryColor,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                        ),
                                                                      ],
                                                                    ))
                                                            .toList(),
                                                      ),

                                                      // Scrollable parameters columns
                                                      Expanded(
                                                        child:
                                                            SingleChildScrollView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          child: DataTable(
                                                            horizontalMargin:
                                                                12,
                                                            columnSpacing: 16,
                                                            headingRowHeight:
                                                                40,
                                                            dataRowHeight: 48,
                                                            headingRowColor:
                                                                WidgetStateProperty
                                                                    .all(
                                                              const Color(
                                                                  0xFFF0F2FF),
                                                            ),
                                                            border: TableBorder(
                                                              top: BorderSide(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200),
                                                              bottom: BorderSide(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200),
                                                            ),
                                                            columns: [
                                                              _buildStyledColumn(
                                                                  '#DSE'),
                                                              _buildStyledColumn(
                                                                  'DSE IN'),
                                                              _buildStyledColumn(
                                                                  '#OUTLET'),
                                                              _buildStyledColumn(
                                                                  '#VISIT'),
                                                              _buildStyledColumn(
                                                                  'SP'),
                                                              _buildStyledColumn(
                                                                  'VOU'),
                                                              _buildStyledColumn(
                                                                  'SALMO'),
                                                            ],
                                                            rows: _mcData
                                                                .map(
                                                                    (mc) =>
                                                                        DataRow(
                                                                          color:
                                                                              WidgetStateProperty.resolveWith<Color>((states) {
                                                                            final index =
                                                                                _mcData.indexOf(mc);
                                                                            return index % 2 == 0
                                                                                ? Colors.white
                                                                                : const Color(0xFFFAFAFF);
                                                                          }),
                                                                          cells: [
                                                                            _buildStyledDataCell(mc['total_dse']?.toString() ??
                                                                                '0'),
                                                                            _buildStyledDataCell(mc['dse_active']?.toString() ??
                                                                                '0'),
                                                                            _buildStyledDataCell(mc['outlet']?.toString() ??
                                                                                '0'),
                                                                            _buildStyledDataCell(mc['visit']?.toString() ??
                                                                                '0'),
                                                                            _buildHighlightedDataCell(mc['sp']?.toString() ?? '0',
                                                                                accentColor),
                                                                            _buildHighlightedDataCell(mc['vou']?.toString() ?? '0',
                                                                                Colors.amber),
                                                                            _buildHighlightedDataCell(mc['salmo']?.toString() ?? '0',
                                                                                Colors.green),
                                                                          ],
                                                                        ))
                                                                .toList(),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : _buildEmptyState('No Data Available',
                                            'Try changing filters or date'),
                          ),
                        ),

                        const SizedBox(height: 70), // Space for bottom nav
                      ],
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
                            Icons.home,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build filter dropdowns
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

  // Helper methods for styled table
  DataColumn _buildStyledColumn(String title) {
    return DataColumn(
      label: Container(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A62B7),
          ),
        ),
      ),
    );
  }

  DataCell _buildStyledDataCell(String text) {
    return DataCell(
      Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  DataCell _buildHighlightedDataCell(String text, Color color) {
    return DataCell(
      Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w600,
            // Add a subtle color highlight to important metrics
            shadows: [
              Shadow(
                color: color.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build empty state
  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8D8D92),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
