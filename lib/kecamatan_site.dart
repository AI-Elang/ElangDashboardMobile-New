import 'package:elang_dashboard_new_ui/filtering_site.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class KecamatanSite extends StatefulWidget {
  final int mcId;
  final String brand;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;

  const KecamatanSite({
    super.key,
    required this.mcId,
    required this.brand,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
  });

  @override
  State<KecamatanSite> createState() => _KecamatanSiteState();
}

class _KecamatanSiteState extends State<KecamatanSite> {
  // Add state to track filter expansion (changed name for clarity)

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

  List<Map<String, dynamic>> _ptData = [];
  List<Map<String, dynamic>> _filteredPTData = [];

  bool _isFiltersCollapsed = true; // Start collapsed

  var baseURL = dotenv.env['baseURL'];

  Future<void> fetchPTData(String? token) async {
    final url = '$baseURL/api/v1/sites/pt/${widget.mcId}?brand=${widget.brand}';

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
                    'kecamatan': pt['kecamatan'],
                    'pt_name': pt['pt_name'],
                    'status': pt['status'],
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

  void _filterData() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
      _filteredPTData = _ptData.where((pt) {
        final partnerName = pt['pt_name'].toString().toLowerCase();
        final kecamatan = pt['kecamatan'].toString().toLowerCase();
        final status = pt['status'].toString().toLowerCase();
        return partnerName.contains(_searchText) ||
            kecamatan.contains(_searchText) ||
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
    fetchPTData(token);
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

    // Define color scheme - matching pt.dart style
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
              children: [
                // Header container with gradient (like pt.dart)
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
                        'KECAMATAN SITE', // Title
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

                // Main content area (scrollable part handled below)
                Expanded(
                  child: Container(
                    // Add background image like pt.dart if desired
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
                        // User profile and filters section (Card like pt.dart)
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
                                  // User info row (like pt.dart)
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

                                  // Filters section with collapsible functionality (like pt.dart)
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
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                children: [
                                                  // First row of filters
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: _buildFilterItem(
                                                            // Use original item builder
                                                            "Circle",
                                                            _selectedDropdown1),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: _buildFilterItem(
                                                            // Use original item builder
                                                            "Region",
                                                            _selectedDropdown2 ??
                                                                'N/A'),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Second row of filters
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: _buildFilterItem(
                                                            // Use original item builder
                                                            "Area",
                                                            _selectedDropdown3 ??
                                                                'N/A'),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: _buildFilterItem(
                                                            // Use original item builder
                                                            "Branch",
                                                            _selectedDropdown4 ??
                                                                'N/A'),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Third row for Brand
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: _buildFilterItem(
                                                            // Use original item builder
                                                            "Brand",
                                                            widget.brand),
                                                      ),
                                                      // Add spacer if only one item in the row
                                                      const Expanded(
                                                          child: SizedBox()),
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

                        const SizedBox(height: 8), // Reduced spacing

                        // Search Bar (Keep existing style for now, adjust if needed)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
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
                                  color: textSecondaryColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sites List Section Header (like pt.dart)
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
                              const Text(
                                "Kecamatan Sites List", // Static header text
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
                                  // Show entry count based on filter state
                                  '${_searchText.isEmpty ? _ptData.length : _filteredPTData.length} entries',
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

                        const SizedBox(height: 16), // Spacing before list

                        // List View Section (wrapped like pt.dart table area)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: (_searchText.isEmpty && _ptData.isEmpty) ||
                                    (_searchText.isNotEmpty &&
                                        _filteredPTData.isEmpty)
                                ? _buildEmptyState(
                                    'No Sites Available',
                                    _searchText.isEmpty
                                        ? 'No site data found for the selected filters'
                                        : 'No sites match your search criteria')
                                : ListView.builder(
                                    padding: const EdgeInsets.only(
                                        bottom:
                                            10), // Reduced padding, bottom nav handles rest
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _searchText.isEmpty
                                        ? _ptData.length
                                        : _filteredPTData.length,
                                    itemBuilder: (context, index) {
                                      final pt = _searchText.isEmpty
                                          ? _ptData[index]
                                          : _filteredPTData[index];
                                      // Use alternating colors for card accents
                                      final cardAccentColor = index % 2 == 0
                                          ? primaryColor
                                          : accentColor;
                                      return _buildSiteCard(
                                          pt, cardAccentColor);
                                    },
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

            // Bottom navigation bar (styled like pt.dart)
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
                    // Home Button (styled like pt.dart)
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

  // Helper method to build filter items (Modified for grayed-out style)
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

  // Helper method to build site card (kept from original)
  Widget _buildSiteCard(Map<String, dynamic> pt, Color accentColor) {
    // ... existing _buildSiteCard implementation ...
    // No changes needed here based on the request
    final bool isLRK = pt['status'] == 'LRK';
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

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
              builder: (context) => FilteringSite(
                brand: widget.brand,
                kecamatan: pt['kecamatan'],
                selectedRegion: widget.selectedRegion,
                selectedArea: widget.selectedArea,
                selectedBranch: widget.selectedBranch,
              ),
            ),
          );
        },
        child: Container(
          decoration: isLRK
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                )
              : null, // No special background for non-LRK
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Site icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLRK
                        ? Colors.white.withOpacity(0.2)
                        : accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: isLRK ? Colors.white : accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Site info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pt['kecamatan'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isLRK ? Colors.white : textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pt['pt_name'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isLRK
                              ? Colors.white.withOpacity(0.8)
                              : textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4), // Increased spacing
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLRK
                              ? Colors.white.withOpacity(0.2)
                              : accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pt['status'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isLRK ? Colors.white : accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isLRK
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build empty state (copied from pt.dart style)
  Widget _buildEmptyState(String title, String subtitle) {
    const textPrimaryColor = Color(0xFF2D3142);
    const textSecondaryColor = Color(0xFF8D8D92);

    return Container(
      // Wrap in a container for potential styling or margin
      margin: const EdgeInsets.symmetric(
          horizontal: 0, vertical: 8), // Adjusted margin
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
