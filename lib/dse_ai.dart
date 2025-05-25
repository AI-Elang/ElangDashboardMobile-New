import 'package:elang_dashboard_new_ui/mc_ai.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DseAi extends StatefulWidget {
  const DseAi({super.key});

  @override
  State<DseAi> createState() => _DseAiState();
}

class _DseAiState extends State<DseAi> {
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
              final String baseTerritory =
                  territory.substring(0, territory.length - 4);
              _mcData = mcDataReceived
                  .where((mc) =>
                      mc['name'].toString().startsWith(baseTerritory) &&
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

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.role == 5) {
        _initializeLockedDropdowns();
      } else if (authProvider.role == 4) {
        _initializeLockedDropdowns();
      } else if (authProvider.role == 3) {
        _initializeLockedDropdowns();
      } else if (authProvider.role == 2) {
        _initializeLockedDropdowns();
      } else if (authProvider.role == 1) {
        _initializeLockedDropdowns();
      } else {
        fetchRegions(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final mediaQueryWidth = MediaQuery.of(context).size.width;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Header Section
            Column(
              children: [
                Container(
                  height: mediaQueryHeight * 0.04,
                  width: mediaQueryWidth * 1.0,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 15, bottom: 8),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        'DSE AI',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: mediaQueryHeight * 0.9,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    image: DecorationImage(
                      image: AssetImage('assets/LOGO.png'),
                      fit: BoxFit.cover,
                      opacity: 0.3,
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 35,
                                  backgroundImage: AssetImage('assets/100.png'),
                                  backgroundColor: Colors.transparent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        territory,
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.grey),
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
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formattedDate(),
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey),
                                    ),

                                    // Dropdown 1
                                    DropdownButton<String>(
                                      value: _selectedDropdown1,
                                      isDense: true,
                                      onChanged: _isDropdownLocked(1)
                                          ? null
                                          : (String? newValue) {
                                              setState(() {
                                                _selectedDropdown1 = newValue;
                                              });
                                            },
                                      items: <String>['Circle Java']
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          alignment:
                                              AlignmentDirectional.centerEnd,
                                          child: Container(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              value,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _isDropdownLocked(1)
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      alignment: Alignment.centerRight,
                                    ),

                                    // Dropdown 2
                                    DropdownButton<String>(
                                      value: _selectedDropdown2,
                                      isDense: true,
                                      onChanged: _isDropdownLocked(2)
                                          ? null
                                          : (String? newValue) {
                                              setState(() {
                                                // Reset everything first
                                                _selectedDropdown3 =
                                                    'Pilih Area';
                                                _selectedDropdown4 =
                                                    'Pilih Branch';
                                                _subRegions.clear();
                                                _subAreas.clear();
                                                _mcData.clear();

                                                // Then set new value and fetch data if needed
                                                _selectedDropdown2 = newValue;
                                                if (newValue !=
                                                    'Pilih Region') {
                                                  int regionId =
                                                      _regions.firstWhere((r) =>
                                                          r['name'] ==
                                                          newValue)['id'];
                                                  final authProvider =
                                                      Provider.of<AuthProvider>(
                                                          context,
                                                          listen: false);
                                                  fetchSubRegions(regionId,
                                                      authProvider.token);
                                                }
                                              });
                                            },
                                      items: _regions
                                          .map<DropdownMenuItem<String>>(
                                              (Map<String, dynamic> region) {
                                        return DropdownMenuItem<String>(
                                          value: region['name'],
                                          alignment:
                                              AlignmentDirectional.centerEnd,
                                          child: Container(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              region['name'],
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _isDropdownLocked(2)
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      alignment: Alignment.centerRight,
                                    ),

                                    // Dropdown 3
                                    DropdownButton<String>(
                                      value: _selectedDropdown3,
                                      isDense: true,
                                      onChanged: _isDropdownLocked(3)
                                          ? null
                                          : (String? newValue) {
                                              setState(() {
                                                _selectedDropdown3 =
                                                    newValue; // Set the new value
                                                if (newValue == 'Pilih Area') {
                                                  // Reset dropdown 4 and clear all related data
                                                  _selectedDropdown4 =
                                                      'Pilih Branch';
                                                  _subAreas.clear();
                                                  _mcData
                                                      .clear(); // Add this line to clear MC data
                                                } else {
                                                  // Handle specific area selection
                                                  _subAreas.clear();
                                                  _selectedDropdown4 =
                                                      'Pilih Branch';
                                                  _mcData
                                                      .clear(); // Also clear MC data when changing area

                                                  int areaId = _subRegions
                                                      .firstWhere((sr) =>
                                                          sr['name'] ==
                                                          newValue)['id'];
                                                  int regionId =
                                                      _regions.firstWhere((r) =>
                                                              r['name'] ==
                                                              _selectedDropdown2)[
                                                          'id'];

                                                  // Then fetch sub-areas (branches)
                                                  final authProvider =
                                                      Provider.of<AuthProvider>(
                                                          context,
                                                          listen: false);
                                                  fetchAreas(regionId, areaId,
                                                      authProvider.token);
                                                }
                                              });
                                            },
                                      items: _subRegions
                                          .map<DropdownMenuItem<String>>(
                                              (Map<String, dynamic> subRegion) {
                                        return DropdownMenuItem<String>(
                                          value: subRegion['name'],
                                          alignment:
                                              AlignmentDirectional.centerEnd,
                                          child: Container(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              subRegion['name'],
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _isDropdownLocked(3)
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      alignment: Alignment.centerRight,
                                    ),

                                    // Dropdown 4
                                    DropdownButton<String>(
                                      value: _selectedDropdown4,
                                      isDense: true,
                                      onChanged: _isDropdownLocked(4)
                                          ? null
                                          : (String? newValue) {
                                              setState(() {
                                                _selectedDropdown4 = newValue;
                                                if (newValue ==
                                                    'Pilih Branch') {
                                                  // Clear MC data when 'Pilih Branch' is selected
                                                  _mcData.clear();

                                                  // Update status based on current Area selection
                                                  if (_selectedDropdown3 !=
                                                      'Pilih Area') {
                                                    // No need to declare areaId as it is not used
                                                  }
                                                } else {
                                                  // Existing code for when specific branch is selected
                                                  int branchId = _subAreas
                                                      .firstWhere((area) =>
                                                          area['name'] ==
                                                          newValue)['id'];
                                                  final authProvider =
                                                      Provider.of<AuthProvider>(
                                                          context,
                                                          listen: false);
                                                  fetchMCData(branchId,
                                                      authProvider.token);
                                                }
                                              });
                                            },
                                      items: _subAreas
                                          .map<DropdownMenuItem<String>>(
                                              (Map<String, dynamic> area) {
                                        return DropdownMenuItem<String>(
                                          value: area['name'],
                                          child: Container(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                area['name'],
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: _isDropdownLocked(4)
                                                      ? Colors.grey
                                                      : Colors.black,
                                                ),
                                                textAlign: TextAlign.right,
                                              )),
                                        );
                                      }).toList(),
                                      alignment: Alignment.centerRight,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: mediaQueryHeight * 0.65,
                              child: _mcData.isNotEmpty
                                  ? ListView.builder(
                                      itemCount: _mcData.length,
                                      itemBuilder: (context, index) {
                                        final mc = _mcData[index];
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 10),
                                          padding: const EdgeInsets.all(10),
                                          width: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 2,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => McAi(
                                                    mcId: int.parse(
                                                        mc['id'].toString()),
                                                    selectedRegion:
                                                        _selectedDropdown2 ??
                                                            'Pilih Region', // Tambahkan ini
                                                    selectedArea:
                                                        _selectedDropdown3 ??
                                                            'Pilih Area', // Tambahkan ini
                                                    selectedBranch:
                                                        _selectedDropdown4 ??
                                                            'Pilih Branch', // Tambahkan ini
                                                  ),
                                                ),
                                              );
                                            },
                                            title: Text(mc['name']),
                                            trailing: const Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.black54),
                                          ),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Text('No Data'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 55,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.home,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Homepage()),
                            );
                          },
                        ),
                      ],
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
}
