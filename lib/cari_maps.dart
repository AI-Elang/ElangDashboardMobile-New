import 'package:elang_dashboard_new_ui/kecamatan_maps.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class CariMaps extends StatefulWidget {
  const CariMaps({super.key});

  @override
  State<CariMaps> createState() => _CariMapsState();
}

class _CariMapsState extends State<CariMaps> {
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
  bool _isFiltersCollapsed = true; // Use collapsed state like outlet.dart
  bool _isLoading = false; // Track loading state for dropdowns and list

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

  var baseURL = dotenv.env['baseURL'];

  // REGION DATA (Dropdown 2)
  Future<void> fetchRegions(String? token) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Start loading
    });
    final url = '$baseURL/api/v1/dropdown/get-region?circle=1';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> regionsData = data['data'];

        setState(() {
          _regions = regionsData
              .map((region) => {'id': region['id'], 'name': region['name']})
              .toList();
          _regions.insert(0, {'id': null, 'name': 'Pilih Region'});
          if (!_regions.any((r) => r['name'] == _selectedDropdown2)) {
            _selectedDropdown2 = 'Pilih Region';
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load regions: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching regions')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  // AREA DATA (Dropdown 3)
  Future<void> fetchSubRegions(int regionId, String? token) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Start loading
      _subRegions.clear(); // Clear previous data
      _subAreas.clear();
      _mcData.clear();
      _selectedDropdown3 = 'Pilih Area';
      _selectedDropdown4 = 'Pilih Branch';
    });
    final url = '$baseURL/api/v1/dropdown/get-region?circle=1&region=$regionId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> subRegionsData = data['data'];

        setState(() {
          _subRegions = subRegionsData
              .map((subRegion) =>
                  {'id': subRegion['id'], 'name': subRegion['name']})
              .toList();
          _subRegions.insert(0, {'id': null, 'name': 'Pilih Area'});
          if (!_subRegions.any((sr) => sr['name'] == _selectedDropdown3)) {
            _selectedDropdown3 = 'Pilih Area';
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load areas: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching areas')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  // BRANCH DATA (Dropdown 4)
  Future<void> fetchAreas(int regionId, int subRegionId, String? token) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Start loading
      _subAreas.clear(); // Clear previous data
      _mcData.clear();
      _selectedDropdown4 = 'Pilih Branch';
    });
    final url =
        '$baseURL/api/v1/dropdown/get-region?circle=1&region=$regionId&area=$subRegionId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (!mounted) return;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load branches: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching branches')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  // MC DATA (Dropdown 5 / List Data)
  Future<void> fetchMCData(int branchId, String? token) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Start loading
      _mcData.clear(); // Clear previous data
    });
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
      if (!mounted) return;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load MC data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching MC data')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  // Inisialisasi dropdown yang terkunci
  Future<void> _initializeLockedDropdowns() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Start loading for initialization
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      await authProvider.fetchLockedDropdown();
      if (!mounted) return;

      setState(() {
        _selectedDropdown1 = 'Circle Java';
      });

      // Initialize region dropdown and wait until complete
      await fetchRegions(token); // This will set _isLoading=false internally
      if (!mounted) return;

      // Re-enable loading flag for subsequent fetches if needed
      setState(() {
        _isLoading = true;
      });

      setState(() {
        final regionItem = _regions.firstWhere(
          (r) => r['id'] == authProvider.region,
          orElse: () => _regions.isNotEmpty
              ? _regions.first
              : {'id': null, 'name': 'Pilih Region'},
        );
        _selectedDropdown2 = regionItem['name'];
      });

      // Initialize area dropdown if region exists
      if (authProvider.region != 0 && _selectedDropdown2 != 'Pilih Region') {
        await fetchSubRegions(
            authProvider.region, token); // Sets _isLoading=false
        if (!mounted) return;
        setState(() {
          _isLoading = true;
        }); // Re-enable loading

        setState(() {
          final areaItem = _subRegions.firstWhere(
            (a) => a['id'] == authProvider.area,
            orElse: () => _subRegions.isNotEmpty
                ? _subRegions.first
                : {'id': null, 'name': 'Pilih Area'},
          );
          _selectedDropdown3 = areaItem['name'];
        });

        // Initialize branch dropdown if area exists
        if (authProvider.area != 0 && _selectedDropdown3 != 'Pilih Area') {
          await fetchAreas(authProvider.region, authProvider.area,
              token); // Sets _isLoading=false
          if (!mounted) return;
          setState(() {
            _isLoading = true;
          }); // Re-enable loading

          setState(() {
            final branchItem = _subAreas.firstWhere(
              (b) => b['id'] == authProvider.branch,
              orElse: () => _subAreas.isNotEmpty
                  ? _subAreas.first
                  : {'id': null, 'name': 'Pilih Branch'},
            );
            _selectedDropdown4 = branchItem['name'];
          });

          // Initialize MC dropdown if branch exists
          if (authProvider.branch != 0 &&
              _selectedDropdown4 != 'Pilih Branch') {
            await fetchMCData(
                authProvider.branch, token); // Sets _isLoading=false
          } else {
            if (mounted) {
              setState(() {
                _isLoading = false;
              }); // Ensure loading stops if no MC fetch
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            }); // Ensure loading stops if no branch/MC fetch
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          }); // Ensure loading stops if no area/branch/MC fetch
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error initializing locked filters')),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        }); // Stop loading on error
      }
    }
    // No finally block needed here as individual fetches handle it
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (authProvider.role >= 1 && authProvider.role <= 5) {
        await _initializeLockedDropdowns();
        // Fetch initial MC data if branch is pre-selected after initialization
        if (_selectedDropdown4 != 'Pilih Branch' && authProvider.branch != 0) {
          await fetchMCData(authProvider.branch, token);
        }
      } else {
        await fetchRegions(token); // This handles its own loading state
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define our color scheme - matching homepage style
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
            // App header with gradient background
            Column(
              children: [
                // Header container
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
                                'CARI MAPS',
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

                // Main content area with background image
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
                        // Fixed sections (non-scrollable)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Profile & Filters Section - fixed
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
                                              backgroundImage: AssetImage(
                                                  'assets/LOGO3.png'),
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

                                          // Date info
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
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),

                                      // Filter section with collapsible content
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Filter header with toggle button
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
                                              // Toggle button for collapse/expand (like outlet.dart)
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

                                          // Animated container for filter content (like outlet.dart)
                                          AnimatedCrossFade(
                                            firstChild: const SizedBox(
                                                height: 0,
                                                width: double.infinity),
                                            secondChild: Column(
                                              children: [
                                                const SizedBox(height: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: backgroundColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Column(
                                                    children: [
                                                      // Dropdown row 1 (using _buildFilterDropdown)
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                _buildFilterDropdown(
                                                              'Circle',
                                                              _selectedDropdown1!,
                                                              _isDropdownLocked(
                                                                  1),
                                                              (newValue) {
                                                                // Keep existing logic, just UI change
                                                              },
                                                              <String>[
                                                                'Circle Java'
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                _buildFilterDropdown(
                                                              'Region',
                                                              _selectedDropdown2!,
                                                              _isDropdownLocked(
                                                                  2),
                                                              (newValue) async {
                                                                if (_isLoading) {
                                                                  return;
                                                                }
                                                                setState(() {
                                                                  _selectedDropdown2 =
                                                                      newValue;
                                                                  _selectedDropdown3 =
                                                                      'Pilih Area';
                                                                  _selectedDropdown4 =
                                                                      'Pilih Branch';
                                                                  _subRegions
                                                                      .clear();
                                                                  _subAreas
                                                                      .clear();
                                                                  _mcData
                                                                      .clear();
                                                                });
                                                                if (newValue !=
                                                                    'Pilih Region') {
                                                                  int regionId =
                                                                      _regions.firstWhere((r) =>
                                                                          r['name'] ==
                                                                          newValue)['id'];
                                                                  final authProvider = Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                                  await fetchSubRegions(
                                                                      regionId,
                                                                      authProvider
                                                                          .token);
                                                                }
                                                              },
                                                              _regions
                                                                  .map((region) =>
                                                                      region['name']
                                                                          as String)
                                                                  .toList(),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      // Dropdown row 2 (using _buildFilterDropdown)
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                _buildFilterDropdown(
                                                              'Area',
                                                              _selectedDropdown3!,
                                                              _isDropdownLocked(
                                                                  3),
                                                              (newValue) async {
                                                                if (_isLoading) {
                                                                  return;
                                                                }
                                                                setState(() {
                                                                  _selectedDropdown3 =
                                                                      newValue;
                                                                  _selectedDropdown4 =
                                                                      'Pilih Branch';
                                                                  _subAreas
                                                                      .clear();
                                                                  _mcData
                                                                      .clear();
                                                                });
                                                                if (newValue !=
                                                                    'Pilih Area') {
                                                                  int areaId = _subRegions
                                                                      .firstWhere((sr) =>
                                                                          sr['name'] ==
                                                                          newValue)['id'];
                                                                  int regionId =
                                                                      _regions.firstWhere((r) =>
                                                                          r['name'] ==
                                                                          _selectedDropdown2)['id'];
                                                                  final authProvider = Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                                  await fetchAreas(
                                                                      regionId,
                                                                      areaId,
                                                                      authProvider
                                                                          .token);
                                                                }
                                                              },
                                                              _subRegions
                                                                  .map((subRegion) =>
                                                                      subRegion[
                                                                              'name']
                                                                          as String)
                                                                  .toList(),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                _buildFilterDropdown(
                                                              'Branch',
                                                              _selectedDropdown4!,
                                                              _isDropdownLocked(
                                                                  4),
                                                              (newValue) async {
                                                                if (_isLoading) {
                                                                  return;
                                                                }
                                                                setState(() {
                                                                  _selectedDropdown4 =
                                                                      newValue;
                                                                  _mcData
                                                                      .clear();
                                                                });
                                                                if (newValue !=
                                                                    'Pilih Branch') {
                                                                  int branchId =
                                                                      _subAreas.firstWhere((area) =>
                                                                          area[
                                                                              'name'] ==
                                                                          newValue)['id'];
                                                                  final authProvider = Provider.of<
                                                                          AuthProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);
                                                                  await fetchMCData(
                                                                      branchId,
                                                                      authProvider
                                                                          .token);
                                                                }
                                                              },
                                                              _subAreas
                                                                  .map((area) =>
                                                                      area['name']
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
                                            duration: const Duration(
                                                milliseconds: 300),
                                            reverseDuration: const Duration(
                                                milliseconds: 200),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(
                                  height: 16), // Spacing before list header

                              // MC List Section Header
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
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
                                    const Text(
                                      'Maps',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimaryColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Show count only when not loading
                                    if (!_isLoading)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
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
                            ],
                          ),
                        ),

                        const SizedBox(
                            height: 8), // Reduced spacing before list

                        // MC List - SCROLLABLE SECTION
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _isLoading // Show loader if loading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _mcData
                                        .isNotEmpty // Show list if not loading and has data
                                    ? ListView.builder(
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.only(
                                            bottom:
                                                65), // Increased padding to avoid navigation bar overlap
                                        itemCount: _mcData.length,
                                        itemBuilder: (context, index) {
                                          final mc = _mcData[index];
                                          return Card(
                                            elevation: 1,
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        KecamatanMaps(
                                                      mcId: int.parse(
                                                          mc['id'].toString()),
                                                      brand: mc['name']
                                                          .substring(mc['name']
                                                                  .length -
                                                              3),
                                                      selectedRegion:
                                                          _selectedDropdown2 ??
                                                              'Pilih Region',
                                                      selectedArea:
                                                          _selectedDropdown3 ??
                                                              'Pilih Area',
                                                      selectedBranch:
                                                          _selectedDropdown4 ??
                                                              'Pilih Branch',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: primaryColor
                                                            .withOpacity(0.1),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.map_outlined,
                                                        color: primaryColor,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            mc['name'],
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  textPrimaryColor,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            'ID: ${mc['id']}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  textSecondaryColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Icon(
                                                      Icons.arrow_forward_ios,
                                                      color: primaryColor,
                                                      size: 16,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : _buildEmptyState(
                                        // Use the empty state helper
                                        'No Maps Found',
                                        'Select filters to load data',
                                      ),
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
                        // Prevent navigation if loading
                        if (!_isLoading) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Homepage()),
                          );
                        }
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

  // Helper method to build styled dropdowns
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

  // Helper method to build empty state (copied from outlet.dart)
  Widget _buildEmptyState(String title, String subtitle) {
    const cardColor = Colors.white; // Define locally if needed

    return Container(
      // Wrap in a container for potential styling or margin
      margin: const EdgeInsets.only(bottom: 100), // Match original margin
      decoration: BoxDecoration(
        color: cardColor, // Match card background
        borderRadius: BorderRadius.circular(12), // Match original radius
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
                Icons
                    .map_outlined, // Use original icon or a relevant one like search_off
                size: 48,
                color: Colors.grey.shade400, // Muted color for icon
              ),
              const SizedBox(height: 12), // Space between icon and text
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  // Match original style
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:
                      Colors.grey.shade600, // Adjusted color to match original
                ),
              ),
              const SizedBox(height: 4), // Space between title and subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  // Match original style
                  fontSize: 12,
                  color:
                      Colors.grey.shade500, // Adjusted color to match original
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
