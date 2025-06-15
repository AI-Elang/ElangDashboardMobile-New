import 'package:elang_dashboard_new_ui/detail_site.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class FilteringSite extends StatefulWidget {
  final String kecamatan;
  final String brand;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;

  const FilteringSite({
    super.key,
    required this.kecamatan,
    required this.brand,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
  });

  @override
  State<FilteringSite> createState() => _FSState();
}

class _FSState extends State<FilteringSite> {
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

  final TextEditingController _searchController = TextEditingController();

  final String _selectedDropdown1 = 'Circle Java';
  String? _selectedDropdown2;
  String? _selectedDropdown3;
  String? _selectedDropdown4;
  String _searchText = '';

  List<Map<String, dynamic>> _FSData = [];
  List<Map<String, dynamic>> _filteredFSData = [];

  // Add a state variable to track if filters are collapsed
  bool _isFiltersCollapsed = true;
  bool get _isFiltersExpanded => !_isFiltersCollapsed;

  var baseURL = dotenv.env['baseURL'];

  Future<void> fetchFOData(String? token) async {
    final url =
        '$baseURL/api/v1/sites?kecamatan=${widget.kecamatan}&brand=${widget.brand}';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> FSDataReceived = data['data'];

        setState(() {
          _FSData = FSDataReceived.map((fs) => {
                'id': fs['id'],
                'name': fs['name'],
                'brand': fs['brand'],
                'status': fs['status'],
              }).toList();
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  void _filterData() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
      _filteredFSData = _FSData.where((fs) {
        final id = fs['id'].toString().toLowerCase();
        final name = fs['name'].toString().toLowerCase();
        final status = fs['status'].toString().toLowerCase();

        return id.contains(_searchText) ||
            name.contains(_searchText) ||
            status.contains(_searchText);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    _selectedDropdown2 = widget.selectedRegion;
    _selectedDropdown3 = widget.selectedArea;
    _selectedDropdown4 = widget.selectedBranch;

    fetchFOData(token);
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define color scheme to match the filtering outlet screen
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false, // Keep this
      body: SafeArea(
        child: Stack(
          children: [
            // Main content area
            Column(
              // Main Column for layout
              children: [
                // App header with gradient background (Fixed)
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
                      'DATA SITE',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Expanded area below header with background image
                Expanded(
                  child: Container(
                    // This Container now holds the background image
                    decoration: const BoxDecoration(
                      // Optional: Add background image like pt.dart
                      color:
                          backgroundColor, // Ensure background color is set here too
                      image: DecorationImage(
                        image: AssetImage(
                            'assets/LOGO3.png'), // Keep existing code
                        fit: BoxFit.cover,
                        opacity: 0.08,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      // Column to stack fixed content and scrollable list
                      children: [
                        // Container for fixed content (Profile, Filters, Search, Title)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Profile & Filters Card (...)
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

                                      // Animated container/crossfade for filters (...)
                                      AnimatedCrossFade(
                                        // ...existing AnimatedCrossFade content...
                                        firstChild: const SizedBox(
                                            height: 0, width: double.infinity),
                                        secondChild: Column(
                                          children: [
                                            const SizedBox(height: 8),
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
                                                  // Filter rows (...)
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                          child: _buildFilterItem(
                                                              "Circle",
                                                              _selectedDropdown1)),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                          child: _buildFilterItem(
                                                              "Region",
                                                              _selectedDropdown2 ??
                                                                  'N/A')),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                          child: _buildFilterItem(
                                                              "Area",
                                                              _selectedDropdown3 ??
                                                                  'N/A')),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                          child: _buildFilterItem(
                                                              "Branch",
                                                              _selectedDropdown4 ??
                                                                  'N/A')),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                          child: _buildFilterItem(
                                                              "Kecamatan",
                                                              widget
                                                                  .kecamatan)),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                          child:
                                                              _buildFilterItem(
                                                                  "Brand",
                                                                  widget
                                                                      .brand)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        crossFadeState: _isFiltersExpanded
                                            ? CrossFadeState.showSecond
                                            : CrossFadeState.showFirst,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        reverseDuration:
                                            const Duration(milliseconds: 200),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16), // Spacing

                              // Search Bar (...)
                              Container(
                                // ...existing search bar content...
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search sites...',
                                    hintStyle: TextStyle(
                                      color:
                                          textSecondaryColor.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16), // Spacing

                              // Sites List Section Header (...)
                              Padding(
                                // ...existing list header content...
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
                                      "Site Listing",
                                      style: TextStyle(
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
                                        '${_searchText.isEmpty ? _FSData.length : _filteredFSData.length} entries',
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

                        // Scrollable Site List Section (Inside the outer Expanded/Container)
                        Expanded(
                          child: Padding(
                            // Padding for the list itself
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16), // Keep horizontal padding
                            child: _FSData.isEmpty
                                ? _buildEmptyState('No Sites Available',
                                    'No site data found for the current selection')
                                : _searchText.isNotEmpty &&
                                        _filteredFSData.isEmpty
                                    ? _buildEmptyState('No Matching Sites',
                                        'No sites found matching your search criteria')
                                    : ListView.builder(
                                        physics:
                                            const BouncingScrollPhysics(), // Keep scroll physics
                                        padding: const EdgeInsets.only(
                                            top: 16, // Add top padding
                                            bottom: 80), // Keep bottom padding
                                        itemCount: _searchText.isEmpty
                                            ? _FSData.length
                                            : _filteredFSData.length,
                                        itemBuilder: (context, index) {
                                          final fs = _searchText.isEmpty
                                              ? _FSData[index]
                                              : _filteredFSData[index];
                                          return _buildSiteCard(
                                              fs,
                                              index % 2 == 0
                                                  ? primaryColor
                                                  : accentColor);
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomNavItem(Icons.home, 'Home', true, primaryColor),
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
  Widget _buildFilterItem(String label, String value) {
    // Define colors locally or pass them if needed
    const textLockedColor = Color(0xFF8D8D92); // Medium gray for locked text
    const labelColor = Color(0xFF8D8D92); // Medium gray for label

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Background for filter item
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: labelColor, // Gray label color
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2), // Spacing between label and value
          Text(
            value,
            style: const TextStyle(
              fontSize: 12, // Font size for value
              color: textLockedColor, // Gray text color for value
              fontWeight: FontWeight.w500,
            ),
            softWrap: true, // Allow text to wrap
            // Removed overflow: TextOverflow.ellipsis to allow full text display
          ),
        ],
      ),
    );
  }

  // Helper method to build site card (Keep existing structure, ensure styling is consistent)
  Widget _buildSiteCard(Map<String, dynamic> fs, Color accentColor) {
    final bool isDownSite = fs['status'] == 'NOT READY';
    // Define colors locally or use theme
    const textPrimaryColor = Color(0xFF2D3142);
    const textSecondaryColor = Color(0xFF8D8D92);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6), // Keep margin
      elevation: 1, // Consistent elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Consistent radius
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailSite(
                siteId: fs['id'],
                brand: fs['brand'],
              ),
            ),
          );
        },
        child: Container(
          // Keep container for gradient on down sites
          decoration: isDownSite
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade300,
                      Colors.deepOrange.shade400
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                )
              : null, // No decoration for normal sites
          child: Padding(
            padding: const EdgeInsets.all(16), // Keep padding
            child: Row(
              children: [
                // Site icon (Keep existing style)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDownSite
                        ? Colors.white.withOpacity(0.2)
                        : accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDownSite ? Icons.error_outline : Icons.cell_tower,
                    color: isDownSite ? Colors.white : accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Site info (Keep existing layout, ensure styling matches theme)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fs['id'].toString(),
                        style: TextStyle(
                          fontSize: 14, // Consistent font size
                          fontWeight: FontWeight.w600, // Consistent weight
                          color: isDownSite
                              ? Colors.white
                              : textPrimaryColor, // Use theme color
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fs['name'],
                        style: TextStyle(
                          fontSize: 12, // Consistent font size
                          color: isDownSite
                              ? Colors.white.withOpacity(0.8)
                              : textSecondaryColor, // Use theme color
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4), // Adjusted spacing
                      Container(
                        // Status badge (Keep existing style)
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDownSite
                              ? Colors.white.withOpacity(0.2)
                              : accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          fs['status'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDownSite ? Colors.white : accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon (Keep existing style)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDownSite
                      ? Colors.white.withOpacity(0.8)
                      : Colors.grey.shade400, // Adjusted color
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build empty state (Styled like pt.dart)
  Widget _buildEmptyState(String title, String subtitle) {
    // Define colors locally or use theme
    const textPrimaryColor = Color(0xFF2D3142);
    const textSecondaryColor = Color(0xFF8D8D92);

    return Container(
      // Wrap in a container for potential styling or margin
      margin: const EdgeInsets.symmetric(vertical: 24), // Add vertical margin
      decoration: BoxDecoration(
        color: Colors.white, // Match card background
        borderRadius: BorderRadius.circular(16), // Match card radius
        border:
            Border.all(color: Colors.grey.shade200, width: 1), // Subtle border
      ),
      child: Center(
        child: Padding(
          // Add padding inside the empty state
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 40), // Adjust padding
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take minimum space
            children: [
              Icon(
                title.contains('Search')
                    ? Icons.search_off_rounded
                    : Icons
                        .location_city_outlined, // Choose icon based on title
                size: 48, // Match pt.dart size
                color: Colors.grey.shade400, // Match pt.dart color
              ),
              const SizedBox(height: 16), // Match pt.dart spacing
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16, // Match pt.dart style
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6), // Match pt.dart spacing
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12, // Match pt.dart style
                  color: textSecondaryColor,
                ),
              ),
            ],
          ),
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
}
