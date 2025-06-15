import 'package:elang_dashboard_new_ui/detail_mitra.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/mitra_history.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class FilteringMitra extends StatefulWidget {
  final String brand;
  final String category;
  final String mcName;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;

  const FilteringMitra({
    super.key,
    required this.brand,
    required this.category,
    required this.mcName,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
  });

  @override
  State<FilteringMitra> createState() => _FMState();
}

class _FMState extends State<FilteringMitra> with WidgetsBindingObserver {
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
  final List<Map<String, String>> _allMonths = [
    {'display': 'Januari', 'value': '01'},
    {'display': 'Februari', 'value': '02'},
    {'display': 'Maret', 'value': '03'},
    {'display': 'April', 'value': '04'},
    {'display': 'Mei', 'value': '05'},
    {'display': 'Juni', 'value': '06'},
    {'display': 'Juli', 'value': '07'},
    {'display': 'Agustus', 'value': '08'},
    {'display': 'September', 'value': '09'},
    {'display': 'Oktober', 'value': '10'},
    {'display': 'November', 'value': '11'},
    {'display': 'Desember', 'value': '12'},
  ];

  bool _isLoadingPartners =
      true; // State variable to track loading of the partner list
  bool _isFiltersCollapsed = true; // Add state for collapsible filters
  bool _isLoading = true;

  List<Map<String, dynamic>> _FMData = [];
  List<Map<String, dynamic>> _filteredFMData = [];
  List<Map<String, String>> _monthOptions = [];
  List<String> _yearOptions = [];

  // State variables for month and year dropdowns
  String? _selectedMonth;
  String? _selectedYear;
  String _searchText = '';
  String? _selectedDropdown2;
  String? _selectedDropdown3;
  String? _selectedDropdown4;

  var baseURL = dotenv.env['baseURL'];

  Future<void> fetchFOData(String? token) async {
    if (!mounted) return; // Check if widget is still mounted at the beginning
    setState(() {
      _isLoading = true;
      _isLoadingPartners =
          true; // Ensure this is set when starting to load partners
    });

    if (_selectedMonth == null || _selectedYear == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingPartners = false; // Stop loading indicator if no month/year
        _FMData = [];
        _filteredFMData = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select month and year.')),
        );
      }
      return;
    }

    final url =
        '$baseURL/api/v1/mitra/partner-name?brand=${widget.brand}&category=${widget.category}&mc=${widget.mcName}&month=${_selectedMonth!}&year=${_selectedYear!}';
    print('Fetching data from URL: $url');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (!mounted) return; // Check again before processing response

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response data: $data');
        final List<dynamic> FMDataReceived = data['data'];

        setState(() {
          _FMData = FMDataReceived.map((fo) => {
                'partner_id': fo['partner_id'],
                'partner_name': fo['partner_name'],
                'checkin_count': fo['checkin_count'],
              }).toList();
          _isLoading = false;
          _isLoadingPartners = false; // Stop loading indicator on success
        });
        _filterData(); // Call _filterData to update filtered list
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingPartners = false; // Stop loading indicator on failure
        });
        // Note: This SnackBar will not be displayed as is.
        // It needs ScaffoldMessenger.of(context).showSnackBar(...)
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingPartners = false; // Stop loading indicator on error
      });
      // Note: This SnackBar will not be displayed as is.
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  void _filterData() {
    if (!mounted) return; // Add mounted check
    setState(() {
      _searchText = _searchController.text.toLowerCase();
      _filteredFMData = _FMData.where((fo) {
        final partnerName = fo['partner_name'].toString().toLowerCase();
        return partnerName.contains(_searchText);
      }).toList();
    });
  }

  void _updateMonthOptionsAndSelection() {
    if (_selectedYear == null) {
      if (!mounted) return; // Add mounted check
      setState(() {
        _monthOptions = [];
        _selectedMonth = null;
      });
      return;
    }

    final now = DateTime.now();
    final currentActualYear = now.year;
    final currentActualMonthNumber = now.month; // 1-12

    List<Map<String, String>> newAvailableMonths;
    int yearToCompare = int.parse(_selectedYear!);

    if (yearToCompare < currentActualYear) {
      newAvailableMonths =
          List.from(_allMonths); // All 12 months for past years
    } else if (yearToCompare == currentActualYear) {
      newAvailableMonths = _allMonths.sublist(0,
          currentActualMonthNumber); // Months up to current month for current year
    } else {
      // yearToCompare > currentActualYear (e.g., 2025)
      // Per requirement: "misalkan sampai dengan bulan 05, tahun 2025" (if current month is May)
      // This means for future years, also limit by the current actual month of the current year.
      newAvailableMonths = _allMonths.sublist(0, currentActualMonthNumber);
    }

    String? newSelectedMonth = _selectedMonth;
    // Check if the current _selectedMonth is valid within the newAvailableMonths
    if (newSelectedMonth != null &&
        !newAvailableMonths.any((m) => m['value'] == newSelectedMonth)) {
      newSelectedMonth = null; // Invalidate if not in new options
    }

    // If current selection is invalid or was null, try to set a default
    if (newSelectedMonth == null && newAvailableMonths.isNotEmpty) {
      String currentActualMonthPadded = now.month.toString().padLeft(2, '0');
      if (newAvailableMonths
          .any((m) => m['value'] == currentActualMonthPadded)) {
        newSelectedMonth = currentActualMonthPadded;
      } else {
        // If current actual month is not in options, pick the last available one.
        newSelectedMonth = newAvailableMonths.last['value'];
      }
    }

    // If after all, newAvailableMonths is empty, newSelectedMonth should be null.
    if (newAvailableMonths.isEmpty) {
      newSelectedMonth = null;
    }

    if (!mounted) return; // Add mounted check
    setState(() {
      _monthOptions = newAvailableMonths;
      _selectedMonth = newSelectedMonth;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    _selectedDropdown2 = widget.selectedRegion;
    _selectedDropdown3 = widget.selectedArea;
    _selectedDropdown4 = widget.selectedBranch;

    // Initialize year and month
    _selectedYear = DateTime.now().year.toString();
    _yearOptions = {DateTime.now().year.toString(), '2025'} // Ensure uniqueness
        .toList();
    _yearOptions.sort();

    // Initialize _selectedMonth based on current month, will be validated by _updateMonthOptionsAndSelection
    _selectedMonth = DateTime.now().month.toString().padLeft(2, '0');

    _updateMonthOptionsAndSelection(); // Populate _monthOptions and adjust _selectedMonth

    if (_selectedMonth != null && _selectedYear != null) {
      fetchFOData(token);
    } else {
      // Handle case where month/year might not be set initially if logic leads to empty options
      if (mounted) {
        // Add mounted check
        setState(() {
          _isLoading = false;
          _isLoadingPartners = false; // Also set partners loading to false
        });
      }
    }
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Unregister observer
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App has come to the foreground, refresh data for the current selection
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (_selectedMonth != null && _selectedYear != null) {
        fetchFOData(token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define color scheme to match pt.dart
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
                      'TERRITORY',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
                        // Main content area (non-scrollable part)
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
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          // Region filter (Read-only)
                                                          Expanded(
                                                            child:
                                                                _buildFilterItem(
                                                              "Region",
                                                              widget
                                                                  .selectedRegion,
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
                                                              widget
                                                                  .selectedArea,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          // Branch filter (Read-only)
                                                          Expanded(
                                                            child:
                                                                _buildFilterItem(
                                                              "Branch",
                                                              widget
                                                                  .selectedBranch,
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

                              const SizedBox(height: 2),

                              // Row for Month and Year Dropdowns
                              Row(
                                children: [
                                  // Year Dropdown
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color:
                                            cardColor, // Use cardColor from build context
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Year",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: textSecondaryColor.withOpacity(
                                                  0.8), // Use textSecondaryColor
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedYear,
                                              isDense: true,
                                              isExpanded: true,
                                              icon: Icon(
                                                Icons.arrow_drop_down,
                                                color: _isLoading
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade700,
                                              ),
                                              onChanged: _isLoading
                                                  ? null
                                                  : (String? newValue) {
                                                      if (newValue != null &&
                                                          newValue !=
                                                              _selectedYear) {
                                                        setState(() {
                                                          _selectedYear =
                                                              newValue;
                                                          _updateMonthOptionsAndSelection();
                                                          final authProvider =
                                                              Provider.of<
                                                                      AuthProvider>(
                                                                  context,
                                                                  listen:
                                                                      false);
                                                          fetchFOData(
                                                              authProvider
                                                                  .token);
                                                        });
                                                      }
                                                    },
                                              items: _yearOptions.map<
                                                      DropdownMenuItem<String>>(
                                                  (String year) {
                                                return DropdownMenuItem<String>(
                                                  value: year,
                                                  child: Text(
                                                    year,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: _isLoading
                                                          ? Colors.grey
                                                          : textPrimaryColor, // Use textPrimaryColor
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              hint: Text("Select Year",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: textSecondaryColor
                                                          .withOpacity(0.7))),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),
                                  // Month Dropdown
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color:
                                            cardColor, // Use cardColor from build context
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Month",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: textSecondaryColor.withOpacity(
                                                  0.8), // Use textSecondaryColor
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedMonth,
                                              isDense: true,
                                              isExpanded: true,
                                              icon: Icon(
                                                Icons.arrow_drop_down,
                                                color: _isLoading ||
                                                        _monthOptions.isEmpty
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade700,
                                              ),
                                              onChanged: (_isLoading ||
                                                      _monthOptions.isEmpty)
                                                  ? null
                                                  : (String? newValue) {
                                                      if (newValue != null &&
                                                          newValue !=
                                                              _selectedMonth) {
                                                        setState(() {
                                                          _selectedMonth =
                                                              newValue;
                                                          final authProvider =
                                                              Provider.of<
                                                                      AuthProvider>(
                                                                  context,
                                                                  listen:
                                                                      false);
                                                          fetchFOData(
                                                              authProvider
                                                                  .token);
                                                        });
                                                      }
                                                    },
                                              items: _monthOptions.map<
                                                      DropdownMenuItem<String>>(
                                                  (Map<String, String> month) {
                                                return DropdownMenuItem<String>(
                                                  value: month['value']!,
                                                  child: Text(
                                                    month['display']!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: _isLoading
                                                          ? Colors.grey
                                                          : textPrimaryColor, // Use textPrimaryColor
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              hint: Text("Select Month",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: textSecondaryColor
                                                          .withOpacity(0.7))),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Search Bar
                              Container(
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
                                    hintText: 'Search partners...',
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

                              const SizedBox(height: 16),

                              // Partners Title
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  "Partners List",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Only the ListView is scrollable now
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            // Conditional rendering based on loading state
                            child: _isLoadingPartners
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          primaryColor),
                                    ),
                                  )
                                : _FMData.isEmpty
                                    ? _buildEmptyState('No Partners Available',
                                        'Please select a valid month and year, or try different filters.')
                                    : Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _searchText.isEmpty
                                                      ? '${_FMData.length} partners'
                                                      : '${_filteredFMData.length} partners found',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: textSecondaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Partner Name Column (Fixed)
                                                    DataTable(
                                                      horizontalMargin: 12,
                                                      columnSpacing: 8,
                                                      headingRowHeight: 40,
                                                      dataRowMinHeight: 48,
                                                      dataRowMaxHeight: 60,
                                                      headingRowColor:
                                                          WidgetStateProperty
                                                              .all(
                                                        const Color(0xFFF0F2FF),
                                                      ),
                                                      border: TableBorder(
                                                        top: BorderSide(
                                                            color: Colors
                                                                .grey.shade200),
                                                        bottom: BorderSide(
                                                            color: Colors
                                                                .grey.shade200),
                                                      ),
                                                      columns: [
                                                        _buildStyledColumn(
                                                            'PARTNER NAME',
                                                            TextAlign.left),
                                                      ],
                                                      rows: (_searchText.isEmpty
                                                              ? _FMData
                                                              : _filteredFMData)
                                                          .map((fm) => DataRow(
                                                                color: WidgetStateProperty
                                                                    .resolveWith<
                                                                            Color>(
                                                                        (states) {
                                                                  final dataList = _searchText
                                                                          .isEmpty
                                                                      ? _FMData
                                                                      : _filteredFMData;
                                                                  final index =
                                                                      dataList
                                                                          .indexOf(
                                                                              fm);
                                                                  return index %
                                                                              2 ==
                                                                          0
                                                                      ? Colors
                                                                          .white
                                                                      : const Color(
                                                                          0xFFFAFAFF);
                                                                }),
                                                                cells: [
                                                                  DataCell(
                                                                    InkWell(
                                                                      onTap:
                                                                          () {
                                                                        Navigator
                                                                            .push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                DetailMitra(
                                                                              partnerId: fm['partner_id'],
                                                                              mc: widget.mcName,
                                                                              category: widget.category,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            vertical:
                                                                                4),
                                                                        child:
                                                                            Text(
                                                                          fm['partner_name']
                                                                              .toString(),
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            color:
                                                                                Colors.blue,
                                                                            decoration:
                                                                                TextDecoration.underline,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          maxLines:
                                                                              2,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ))
                                                          .toList(),
                                                    ),
                                                    // Check-in Count Column (Scrollable)
                                                    Expanded(
                                                      child:
                                                          SingleChildScrollView(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        child: DataTable(
                                                          horizontalMargin: 80,
                                                          columnSpacing: 16,
                                                          headingRowHeight: 40,
                                                          dataRowMinHeight: 48,
                                                          dataRowMaxHeight: 60,
                                                          headingRowColor:
                                                              WidgetStateProperty
                                                                  .all(const Color(
                                                                      0xFFF0F2FF)),
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
                                                                'CHECK-IN',
                                                                TextAlign
                                                                    .center),
                                                          ],
                                                          rows: (_searchText
                                                                      .isEmpty
                                                                  ? _FMData
                                                                  : _filteredFMData)
                                                              .map((fm) {
                                                            final checkinCount =
                                                                fm['checkin_count'] ??
                                                                    0;
                                                            final canNavigate =
                                                                checkinCount >
                                                                    0;
                                                            return DataRow(
                                                              color: WidgetStateProperty
                                                                  .resolveWith<
                                                                          Color>(
                                                                      (states) {
                                                                final dataList =
                                                                    _searchText
                                                                            .isEmpty
                                                                        ? _FMData
                                                                        : _filteredFMData;
                                                                final index =
                                                                    dataList
                                                                        .indexOf(
                                                                            fm);
                                                                return index %
                                                                            2 ==
                                                                        0
                                                                    ? Colors
                                                                        .white
                                                                    : const Color(
                                                                        0xFFFAFAFF);
                                                              }),
                                                              cells: [
                                                                DataCell(
                                                                  InkWell(
                                                                    onTap: canNavigate
                                                                        ? () {
                                                                            Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                builder: (context) => MitraHistory(
                                                                                  partnerId: fm['partner_id'],
                                                                                  partnerName: fm['partner_name'],
                                                                                  selectedMonth: _selectedMonth!,
                                                                                  selectedYear: _selectedYear!,
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }
                                                                        : null,
                                                                    child:
                                                                        Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          vertical:
                                                                              4),
                                                                      child:
                                                                          Text(
                                                                        checkinCount
                                                                            .toString(),
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          color: canNavigate
                                                                              ? Colors.blue
                                                                              : textPrimaryColor,
                                                                          decoration: canNavigate
                                                                              ? TextDecoration.underline
                                                                              : TextDecoration.none,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                              height:
                                                  80), // Padding for bottom nav
                                        ],
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

  // Helper methods for styled table columns and cells (adapted from outlet.dart)
  DataColumn _buildStyledColumn(String title, TextAlign align) {
    const primaryColor = Color(0xFF6A62B7); // Define color locally
    return DataColumn(
      label: Expanded(
        child: Container(
          alignment: align == TextAlign.center
              ? Alignment.center
              : align == TextAlign.right
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11, // Adjusted for potentially smaller headers
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // Helper method to build empty state (adapted from outlet.dart)
  Widget _buildEmptyState(String title, String subtitle) {
    const textPrimaryColor = Color(0xFF2D3142);
    const textSecondaryColor = Color(0xFF8D8D92);
    const cardColor = Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
