import 'package:elang_dashboard_new_ui/switch_dse.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class MC extends StatefulWidget {
  final int mcId;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;

  const MC({
    super.key,
    required this.mcId,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
  });

  @override
  State<MC> createState() => _MCState();
}

class _MCState extends State<MC> {
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

  List<Map<String, dynamic>> _dseData = [];
  List<Map<String, dynamic>> _filteredDSEData = [];

  var baseURL = dotenv.env['baseURL'];

  // Add a state variable to track if filters are collapsed
  bool _isFiltersCollapsed = true;

  // AMBIL DSE DATA
  Future<void> fetchDSEData(String? token) async {
    final url = '$baseURL/api/v1/dse/${widget.mcId}';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> dseDataReceived = data['data'];

        setState(() {
          _dseData = dseDataReceived
              .map((dse) => {
                    'id': dse['id'],
                    'name': dse['name'],
                    'mc_id': dse['mc_id'],
                    'mc_name': dse['mc_name'],
                    'pjp': dse['pjp'],
                    'actual_pjp': dse['actual_pjp'],
                    'zero': dse['zero'],
                    'sp': dse['sp'],
                    'vou': dse['vou'],
                    'salmo': dse['salmo'],
                    'mtd_dt': dse['mtd_dt'],
                    'checkin': dse['checkin'],
                    'checkout': dse['checkout'],
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
      _filteredDSEData = _dseData.where((dse) {
        final id = dse['id'].toString().toLowerCase();
        final name = dse['mc_name'].toString().toLowerCase();

        return id.contains(_searchText) || name.contains(_searchText);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedDropdown2 = widget.selectedRegion;
    _selectedDropdown3 = widget.selectedArea;
    _selectedDropdown4 = widget.selectedBranch;
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    fetchDSEData(token);
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

    // Define our color scheme - matching DSE style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray
    final headerTextColor = primaryColor.withOpacity(0.8);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
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
                                'DSE DATA',
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
                                                          Expanded(
                                                            child: _buildFilterItem(
                                                                // Use original item builder
                                                                "Circle",
                                                                _selectedDropdown1),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                _buildFilterItem(
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
                                                            child:
                                                                _buildFilterItem(
                                                                    // Use original item builder
                                                                    "Area",
                                                                    _selectedDropdown3 ??
                                                                        'N/A'),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                _buildFilterItem(
                                                                    // Use original item builder
                                                                    "Branch",
                                                                    _selectedDropdown4 ??
                                                                        'N/A'),
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

                                      // Search Box
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.search,
                                                color: Colors.grey.shade600,
                                                size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: _searchController,
                                                style: const TextStyle(
                                                    fontSize: 14),
                                                decoration:
                                                    const InputDecoration(
                                                  hintText:
                                                      'Search DSE ID or name...',
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  border: InputBorder.none,
                                                  hintStyle: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          textSecondaryColor),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // DSE List Section Header
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
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
                                        '${_searchText.isEmpty ? _dseData.length : _filteredDSEData.length} entries',
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

                        const SizedBox(height: 4),

                        // DSE Data Table - SCROLLABLE SECTION
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _dseData.isNotEmpty
                                ? (_searchText.isEmpty ||
                                        _filteredDSEData.isNotEmpty)
                                    ? Card(
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        color: cardColor,
                                        margin: EdgeInsets.zero,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Last Update: ${_dseData.isNotEmpty ? _dseData[0]['mtd_dt'] : 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: headerTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Expanded(
                                                // Ensures the table container takes available space within the Card
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade200),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0),
                                                    child:
                                                        SingleChildScrollView(
                                                      // For vertical scroll of table rows if they exceed Card height
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // Fixed Column (DSE ID)
                                                          SizedBox(
                                                            width: 145.0,
                                                            child: DataTable(
                                                              horizontalMargin:
                                                                  8,
                                                              columnSpacing: 4,
                                                              headingRowHeight:
                                                                  36,
                                                              dataRowHeight: 32,
                                                              headingRowColor:
                                                                  WidgetStateProperty.all(
                                                                      primaryColor
                                                                          .withOpacity(
                                                                              0.1)),
                                                              columns: [
                                                                _buildStyledColumn(
                                                                  'DSE ID',
                                                                  headerTextColor,
                                                                  isHeaderLeft:
                                                                      true,
                                                                ),
                                                              ],
                                                              rows: (_searchText
                                                                          .isEmpty
                                                                      ? _dseData
                                                                      : _filteredDSEData)
                                                                  .map((dse) {
                                                                final index = (_searchText
                                                                            .isEmpty
                                                                        ? _dseData
                                                                        : _filteredDSEData)
                                                                    .indexOf(
                                                                        dse);
                                                                return DataRow(
                                                                  color: WidgetStateProperty.resolveWith<
                                                                      Color>((states) => index %
                                                                              2 ==
                                                                          0
                                                                      ? Colors
                                                                          .white
                                                                      : const Color(
                                                                          0xFFFAFAFF)),
                                                                  cells: [
                                                                    _buildStyledDataCell(
                                                                      dse['id'],
                                                                      isLeftAligned:
                                                                          true,
                                                                      isTappable:
                                                                          true,
                                                                      onTap:
                                                                          () {
                                                                        Navigator
                                                                            .push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                SwitchDse(
                                                                              selectedRegion: widget.selectedRegion,
                                                                              selectedArea: widget.selectedArea,
                                                                              selectedBranch: widget.selectedBranch,
                                                                              dseId: dse['id'],
                                                                              branchName: dse['mc_name'],
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                );
                                                              }).toList(),
                                                            ),
                                                          ),
                                                          // Scrollable Columns
                                                          Expanded(
                                                            child:
                                                                SingleChildScrollView(
                                                              scrollDirection:
                                                                  Axis.horizontal,
                                                              child:
                                                                  ConstrainedBox(
                                                                constraints:
                                                                    const BoxConstraints(
                                                                        minWidth:
                                                                            300), // Adjusted minWidth
                                                                child:
                                                                    DataTable(
                                                                  horizontalMargin:
                                                                      8,
                                                                  columnSpacing:
                                                                      10,
                                                                  headingRowHeight:
                                                                      36,
                                                                  dataRowHeight:
                                                                      32,
                                                                  headingRowColor:
                                                                      WidgetStateProperty.all(
                                                                          primaryColor
                                                                              .withOpacity(0.1)),
                                                                  columns: [
                                                                    _buildStyledColumn(
                                                                        'C IN',
                                                                        headerTextColor),
                                                                    _buildStyledColumn(
                                                                        'C OUT',
                                                                        headerTextColor),
                                                                    _buildStyledColumn(
                                                                        '#PJP',
                                                                        headerTextColor),
                                                                    _buildStyledColumn(
                                                                        'ACT PJP',
                                                                        headerTextColor),
                                                                    _buildStyledColumn(
                                                                        '0 SELLIN',
                                                                        headerTextColor),
                                                                    _buildStyledColumn(
                                                                        'SP',
                                                                        headerTextColor),
                                                                    _buildStyledColumn(
                                                                        'VOU',
                                                                        headerTextColor),
                                                                    _buildStyledColumn(
                                                                        'SALMO',
                                                                        headerTextColor),
                                                                  ],
                                                                  rows: (_searchText
                                                                              .isEmpty
                                                                          ? _dseData
                                                                          : _filteredDSEData)
                                                                      .map(
                                                                          (dse) {
                                                                    final index = (_searchText.isEmpty
                                                                            ? _dseData
                                                                            : _filteredDSEData)
                                                                        .indexOf(
                                                                            dse);
                                                                    return DataRow(
                                                                      color: WidgetStateProperty.resolveWith<
                                                                          Color>((states) => index % 2 ==
                                                                              0
                                                                          ? Colors
                                                                              .white
                                                                          : const Color(
                                                                              0xFFFAFAFF)),
                                                                      cells: [
                                                                        _buildStyledDataCell(dse['checkin'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(dse['checkout'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(dse['pjp'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(dse['actual_pjp'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(dse['zero'] ??
                                                                            '0'),
                                                                        _buildHighlightedDataCell(
                                                                            dse['sp'] ??
                                                                                '0',
                                                                            accentColor),
                                                                        _buildHighlightedDataCell(
                                                                            dse['vou'] ??
                                                                                '0',
                                                                            Colors.amber),
                                                                        _buildHighlightedDataCell(
                                                                            dse['salmo'] ??
                                                                                '0',
                                                                            Colors.green),
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
                                            ],
                                          ),
                                        ),
                                      )
                                    : _buildEmptyState('No matching results',
                                        'Try different search terms')
                                : _buildEmptyState('No DSE Data Found',
                                    'Data not available for this MC'),
                          ),
                        ),
                        const SizedBox(height: 110),
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
            softWrap: true, // Allow text to wrap to the next line
            // Removed overflow: TextOverflow.ellipsis to allow full text display
          ),
        ],
      ),
    );
  }

  // Helper methods for styled table
  DataColumn _buildStyledColumn(String title, Color headerTextColor,
      {bool isHeaderLeft = false}) {
    return DataColumn(
      label: Container(
        alignment: isHeaderLeft ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11, // Matched with ReusableDataTableSection
            fontWeight: FontWeight.w600,
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
  }) {
    Widget cellContent = Text(
      text,
      style: TextStyle(
        fontSize: 11, // Matched with ReusableDataTableSection
        color: isTappable
            ? Colors.blue
            : Colors.grey.shade800, // Link color if tappable
        fontWeight: FontWeight.w500,
        decoration: isTappable
            ? TextDecoration.underline
            : TextDecoration.none, // Underline if tappable
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
        padding: const EdgeInsets.symmetric(
            vertical: 4, horizontal: 4.0), // Matched with Reusable
        child: cellContent,
      ),
    );
  }

  DataCell _buildHighlightedDataCell(String text, Color color) {
    return DataCell(
      Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(
            vertical: 4, horizontal: 4.0), // Matched with Reusable padding
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11, // Matched with Reusable font size
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: color.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Helper method to build empty state
  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
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
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
