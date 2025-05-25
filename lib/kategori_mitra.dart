import 'package:elang_dashboard_new_ui/filtering_mitra.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class KategoriMitra extends StatefulWidget {
  final int mcId;
  final String mcName;
  final String brand;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;

  const KategoriMitra({
    super.key,
    required this.mcId,
    required this.mcName,
    required this.brand,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
  });

  @override
  State<KategoriMitra> createState() => _KategoriMitraState();
}

class _KategoriMitraState extends State<KategoriMitra> {
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

  final String _selectedDropdown1 = 'Circle Java';
  final bool _isLoadingTable =
      false; // Keep this, might be used by UI logic later

  String? _selectedDropdown2;
  String? _selectedDropdown3;
  String? _selectedDropdown4;

  // Add this helper function _KategoriMitraState class
  String cleanMcName(String mcName) {
    return mcName.replaceAll(' IM3', '').replaceAll(' 3ID', '');
  }

  bool _isFiltersCollapsed = true; // Add state for collapsible filters

  List<Map<String, dynamic>> _ptData = []; // Store DSE data

  var baseURL = dotenv.env['baseURL'];

  // AMBIL DSE DATA
  Future<void> fetchPTData(String? token) async {
    final url =
        '$baseURL/api/v1/mitra/${widget.mcId}/categories?brand=${widget.brand}';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ptDataReceived = data['data'];

        setState(() {
          _ptData = ptDataReceived
              .map((pt) => {
                    'category': pt['category'],
                  })
              .toList();
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    _selectedDropdown2 = widget.selectedRegion;
    _selectedDropdown3 = widget.selectedArea;
    _selectedDropdown4 = widget.selectedBranch;

    fetchPTData(token);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define color scheme to match filtering_mitra.dart
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
            // Main content area
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
                  child: const Center(
                    child: Text(
                      'MITRA CATEGORY',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Main content area (non-scrollable part) with background image
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
                    child: Column(
                      children: [
                        // Fixed non-scrollable content
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Profile & Filters Card
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

                                      // Filters section with collapsible content
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
                                                "Selected Filters", // Changed label
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
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Column(
                                                    children: [
                                                      // First row of filters
                                                      Row(
                                                        children: [
                                                          // Circle filter (Read-only)
                                                          Expanded(
                                                            child:
                                                                _buildFilterItem(
                                                              "Circle",
                                                              _selectedDropdown1,
                                                              true, // Always locked
                                                              (value) {}, // No action
                                                              [
                                                                _selectedDropdown1
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          // Region filter (Read-only)
                                                          Expanded(
                                                            child:
                                                                _buildFilterItem(
                                                              "Region",
                                                              _selectedDropdown2 ??
                                                                  'N/A',
                                                              true, // Always locked
                                                              (value) {}, // No action
                                                              [
                                                                _selectedDropdown2 ??
                                                                    'N/A'
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      // Second row of filters
                                                      Row(
                                                        children: [
                                                          // Area filter (Read-only)
                                                          Expanded(
                                                            child:
                                                                _buildFilterItem(
                                                              "Area",
                                                              _selectedDropdown3 ??
                                                                  'N/A',
                                                              true, // Always locked
                                                              (value) {}, // No action
                                                              [
                                                                _selectedDropdown3 ??
                                                                    'N/A'
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          // Branch filter (Read-only)
                                                          Expanded(
                                                            child:
                                                                _buildFilterItem(
                                                              "Branch",
                                                              _selectedDropdown4 ??
                                                                  'N/A',
                                                              true, // Always locked
                                                              (value) {}, // No action
                                                              [
                                                                _selectedDropdown4 ??
                                                                    'N/A'
                                                              ],
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

                              const SizedBox(height: 16),

                              // Categories Title
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  "Category List",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor.withOpacity(0.8),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),

                        // Only the ListView is scrollable now
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _ptData.isEmpty
                                ? Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.category_outlined,
                                          size: 48,
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No Categories Available',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: textSecondaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(
                                        bottom:
                                            80), // Add padding to avoid bottom navbar overlap
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _ptData.length,
                                    itemBuilder: (context, index) {
                                      final pt = _ptData[index];
                                      return _buildCategoryCard(
                                        pt,
                                        index % 2 == 0
                                            ? primaryColor
                                            : accentColor,
                                      );
                                    },
                                  ),
                          ),
                        ),
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                            "Home",
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

  // Helper method to build filter items
  Widget _buildFilterItem(String label, String value, bool isLocked,
      Function(String) onChanged, List<String> items) {
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

  Widget _buildCategoryCard(Map<String, dynamic> pt, Color accentColor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilteringMitra(
                brand: widget.brand,
                category: pt['category'],
                mcName: cleanMcName(widget.mcName),
                selectedRegion: widget.selectedRegion,
                selectedArea: widget.selectedArea,
                selectedBranch: widget.selectedBranch,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Category info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pt['category'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF8D8D92),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
