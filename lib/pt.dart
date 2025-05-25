import 'package:elang_dashboard_new_ui/filtering_outlet.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class PT extends StatefulWidget {
  final int mcId;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;

  const PT({
    super.key,
    required this.mcId,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
  });

  @override
  State<PT> createState() => _PTState();
}

class _PTState extends State<PT> {
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

  final String _selectedDropdown1 = 'Circle Java';
  String? _selectedDropdown2;
  String? _selectedDropdown3;
  String? _selectedDropdown4;
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

  List<Map<String, dynamic>> _ptData = [];

  final bool _isLoadingTable =
      false; // Keep this, might be used by UI logic later
  bool _isFiltersCollapsed = true; // Add state for collapsible filters

  var baseURL = dotenv.env['baseURL'];

  // AMBIL DSE DATA
  Future<void> fetchPTData(String? token) async {
    final url = '$baseURL/api/v1/outlet/dropdown-pt?mc=${widget.mcId}';
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
                    'id': pt['id'],
                    'id_secondary': pt['id_secondary'],
                    'name': pt['name'],
                    'brand': pt['brand'],
                    'outlet_count': pt['outlet_count'] ?? '0',
                    'PestaIM3': pt['PestaIM3'] ?? '0',
                    'FuntasTRI': pt['FuntasTRI'] ?? '0',
                  })
              .toList();
        });
      } else {
        SnackBar(content: Text('Failed to load MCs: ${response.statusCode}'));
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
    // final mediaQueryWidth = MediaQuery.of(context).size.width; // No longer directly used for table width
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define color scheme - matching outlet.dart style
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
                // Header container with gradient (like outlet.dart)
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
                        'PARTNERS', // Title remains PARTNERS
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
                        // User profile and filters section (Card like outlet.dart)
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
                                  // User info row (like outlet.dart)
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
                                                      // Circle filter (Read-only)
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Circle",
                                                          _selectedDropdown1,
                                                          true, // Always locked
                                                          (value) {}, // No action
                                                          [_selectedDropdown1],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      // Region filter (Read-only)
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
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
                                                            _buildFilterDropdown(
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
                                                      const SizedBox(width: 8),
                                                      // Branch filter (Read-only)
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
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

                        // Outlet List Section Header (like outlet.dart)
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
                                  '${_ptData.length} entries', // Show entry count
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
                                : _ptData.isNotEmpty
                                    ? Container(
                                        // Container for table styling (acts as the card background)
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
                                        child: Padding(
                                          // Padding inside the "card"
                                          padding: const EdgeInsets.all(16.0),
                                          child: Container(
                                            // Container for border around the table
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey.shade200),
                                            ),
                                            child: ClipRRect(
                                              // Clip for the inner table border radius
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              child: SingleChildScrollView(
                                                // Vertical scroll for rows
                                                // Removed the intermediate Column wrapper
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // ID Column - Fixed Left
                                                    SizedBox(
                                                      // Use SizedBox for fixed width
                                                      width:
                                                          210, // Adjusted fixed width
                                                      child: DataTable(
                                                        horizontalMargin:
                                                            8, // Matched
                                                        columnSpacing:
                                                            4, // Matched
                                                        headingRowHeight:
                                                            36, // Matched
                                                        dataRowHeight:
                                                            32, // Matched (was 65)
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
                                                            isHeaderLeft: true,
                                                          ),
                                                        ],
                                                        rows: _ptData.map((pt) {
                                                          final index = _ptData
                                                              .indexOf(pt);
                                                          return DataRow(
                                                            color:
                                                                WidgetStateProperty
                                                                    .resolveWith<
                                                                        Color>(
                                                              (states) => index %
                                                                          2 ==
                                                                      0
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFFFAFAFF),
                                                            ),
                                                            cells: [
                                                              _buildStyledDataCell(
                                                                // Use updated helper
                                                                pt['name']
                                                                    .toString(),
                                                                isLeftAligned:
                                                                    true,
                                                                isTappable:
                                                                    _getTableHeaderText() ==
                                                                        'MC ID',
                                                                onTap:
                                                                    _getTableHeaderText() ==
                                                                            'MC ID'
                                                                        ? () {
                                                                            Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                builder: (context) => FilteringOutlet(
                                                                                  idSec: pt['id_secondary'],
                                                                                  selectedRegion: widget.selectedRegion,
                                                                                  selectedArea: widget.selectedArea,
                                                                                  selectedBranch: widget.selectedBranch,
                                                                                  selectedNameFO: pt['name'],
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }
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
                                                                      200), // Adjust minWidth
                                                          child: DataTable(
                                                            horizontalMargin:
                                                                8, // Matched
                                                            columnSpacing:
                                                                10, // Matched
                                                            headingRowHeight:
                                                                36, // Matched
                                                            dataRowHeight:
                                                                32, // Matched (was 65)
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
                                                            rows: _ptData
                                                                .map((pt) {
                                                              final index =
                                                                  _ptData
                                                                      .indexOf(
                                                                          pt);
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
                                                                      _formatNumber(
                                                                          pt['outlet_count'] ??
                                                                              '0')),
                                                                  _buildStyledDataCell(
                                                                      _formatNumber(
                                                                          pt['PestaIM3'] ??
                                                                              '0')),
                                                                  _buildStyledDataCell(
                                                                      _formatNumber(
                                                                          pt['FUNtasTRI'] ??
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
                                      )
                                    : _buildEmptyState('No Data Available',
                                        'No partner data found for the selected filters'), // Use helper for empty state
                          ),
                        ),

                        const SizedBox(height: 75), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom navigation bar (styled like outlet.dart)
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
                    // Home Button (styled like outlet.dart)
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

  // Helper method to build filter dropdowns (adapted from outlet.dart style)
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
  }) {
    Widget cellContent = Text(
      text,
      style: TextStyle(
        fontSize: 11, // Matched
        color: isTappable
            ? Colors.blue
            : Colors.grey.shade800, // Link color if tappable
        fontWeight: FontWeight.w500, // Matched
        decoration: isTappable
            ? TextDecoration.underline
            : TextDecoration.none, // Underline if tappable
      ),
      overflow: TextOverflow.ellipsis, // Matched
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

  // Helper method to build empty state (copied from outlet.dart style)
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
