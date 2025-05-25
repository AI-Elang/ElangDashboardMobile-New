import 'package:elang_dashboard_new_ui/dse_tracking_maps.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DseTrackingList extends StatefulWidget {
  final int mcId;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;

  const DseTrackingList({
    super.key,
    required this.mcId,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
  });

  @override
  State<DseTrackingList> createState() => _DseTrackingListState();
}

class DseTrackingListData {
  final String idDse;
  final String name;
  final String idUnit;
  bool trackingStatus;
  final bool isTrackedToday;

  DseTrackingListData({
    required this.idDse,
    required this.name,
    required this.idUnit,
    required this.trackingStatus,
    required this.isTrackedToday,
  });

  factory DseTrackingListData.fromJson(Map<String, dynamic> json) {
    bool trackingStatus = false;
    if (json['tracking_status'] is String) {
      trackingStatus = json['tracking_status'].toString().toUpperCase() == 'ON';
    } else if (json['tracking_status'] is bool) {
      trackingStatus = json['tracking_status'];
    }

    return DseTrackingListData(
      idDse: json['id_dse'].toString(),
      name: json['name'].toString(),
      idUnit: json['id_unit'].toString(),
      trackingStatus: trackingStatus,
      isTrackedToday: json['is_tracked_today'] ?? false,
    );
  }
}

class _DseTrackingListState extends State<DseTrackingList> {
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

  List<DseTrackingListData> _dseData = [];

  bool _isLoading = true;
  bool _isAllActive = false;

  DateTime selectedDate = DateTime.now();

  var baseURL = dotenv.env['baseURL'];

  Future<void> _fetchDseData() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseURL/api/v1/dse/tracking-status/${widget.mcId}/list?date=${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
        headers: {
          'Authorization':
              'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _dseData = (data['data'] as List)
              .map((item) => DseTrackingListData.fromJson(item))
              .toList();

          _isAllActive = _dseData.every((dse) => dse.trackingStatus);
          _isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              // Define pleasant colors that match the app theme
              const primaryColor = Color(0xFF6A62B7);
              const backgroundColor = Color(0xFFF8F9FA);
              const textColor = Color(0xFF2D3142);

              return Dialog(
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status indicator with error icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red[700],
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title with more emphasis
                      Text(
                        'Error ${errorData['meta']['status_code']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description with more detail
                      Text(
                        errorData['meta']['error'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action button with better styling
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to fetch data: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTrackingStatus(
      String mcId, String dseId, bool newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$baseURL/api/v1/dse/tracking-status/$mcId/dse/$dseId'),
        headers: {
          'Authorization':
              'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tracking_status': newStatus ? 'active' : 'inactive',
        }),
      );

      if (response.statusCode == 200) {
        // Refresh data instead of updating single item
        await _fetchDseData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status berhasil diperbarui'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  errorData['meta']['error'] ?? 'Gagal memperbarui status'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updateAllTrackingStatus(bool status, int idMc) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await http.put(
        Uri.parse('$baseURL/api/v1/dse/tracking-status/$idMc/update-all'),
        headers: {
          'Authorization':
              'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tracking_status': status ? 'active' : 'inactive',
        }),
      );

      // Hide loading indicator
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        // Refresh data instead of parsing response
        await _fetchDseData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  status ? 'All status activated' : 'All status deactivated'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  errorData['meta']['error'] ?? 'Failed to update all status'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Select date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _fetchDseData();
    }
  }

  // Add a state variable to track if filters are collapsed
  bool _isFiltersCollapsed = true;

  @override
  void initState() {
    super.initState();
    _selectedDropdown2 = widget.selectedRegion;
    _selectedDropdown3 = widget.selectedArea;
    _selectedDropdown4 = widget.selectedBranch;
    _fetchDseData();
  }

  // Helper methods for styled table (inspired by reusable_data_table_section.dart)
  DataColumn _buildStyledColumn(String title, Color headerTextColor,
      {bool isHeaderLeft = false, double? width}) {
    Widget label = Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: headerTextColor,
      ),
      overflow: TextOverflow.ellipsis,
    );

    return DataColumn(
      label: Container(
        width: width, // Optional width for specific columns
        alignment: isHeaderLeft ? Alignment.centerLeft : Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: label,
      ),
    );
  }

  DataCell _buildStyledDataCell(
    Widget child, {
    bool isLeftAligned = false,
    AlignmentGeometry? alignment,
  }) {
    return DataCell(
      Container(
        alignment: alignment ??
            (isLeftAligned ? Alignment.centerLeft : Alignment.center),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4.0),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define our color scheme - matching the design from dse_report.dart
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray
    final headerTableTextColor = primaryColor.withOpacity(0.8);

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
                                'DSE TRACKING LIST',
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
                        image: AssetImage('assets/LOGO.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // User profile and info section
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

                                  const SizedBox(height: 12),

                                  // Date picker and action button row
                                  Row(
                                    children: [
                                      // Date picker
                                      Expanded(
                                        flex: 3,
                                        child: InkWell(
                                          onTap: () => _selectDate(context),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: backgroundColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_rounded,
                                                  color: Colors.grey.shade600,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    DateFormat('dd MMM yyyy')
                                                        .format(selectedDate),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: textPrimaryColor,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Action button
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _updateAllTrackingStatus(
                                                !_isAllActive, widget.mcId);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isAllActive
                                                ? Colors.redAccent.shade100
                                                : Colors.greenAccent.shade400,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 14),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _isAllActive
                                                    ? Icons.toggle_off
                                                    : Icons.toggle_on,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _isAllActive
                                                    ? 'ALL OFF'
                                                    : 'ALL ON',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
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

                        // DSE List Section Header
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
                                  '${_dseData.length} DSEs',
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

                        const SizedBox(height: 12),

                        // Data table
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _dseData.isNotEmpty
                                    ? Card(
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        color: cardColor,
                                        margin: EdgeInsets
                                            .zero, // Ensure card takes full space in Padding
                                        child: Padding(
                                          // Padding inside the card
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            // Column for potential titles/actions above table
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Optional: Add a title for the table here if needed
                                              // Text('DSE Tracking Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimaryColor)),
                                              // const SizedBox(height: 12),
                                              Expanded(
                                                // Make the table container expand
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
                                                      // Vertical scroll for rows
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // Fixed Column (DSE ID)
                                                          SizedBox(
                                                            width:
                                                                150.0, // Adjust width as needed
                                                            child: DataTable(
                                                              horizontalMargin:
                                                                  8,
                                                              columnSpacing: 4,
                                                              headingRowHeight:
                                                                  36,
                                                              dataRowHeight:
                                                                  48, // Increased for Switch
                                                              headingRowColor:
                                                                  WidgetStateProperty.all(
                                                                      primaryColor
                                                                          .withOpacity(
                                                                              0.1)),
                                                              columns: [
                                                                _buildStyledColumn(
                                                                    "DSE ID",
                                                                    headerTableTextColor,
                                                                    isHeaderLeft:
                                                                        true),
                                                              ],
                                                              rows: _dseData
                                                                  .map((item) {
                                                                final index =
                                                                    _dseData
                                                                        .indexOf(
                                                                            item);
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
                                                                      (item.isTrackedToday &&
                                                                              item.trackingStatus)
                                                                          ? InkWell(
                                                                              onTap: () {
                                                                                Navigator.pushReplacement(
                                                                                  context,
                                                                                  MaterialPageRoute(
                                                                                    builder: (context) => DseTrackingMaps(
                                                                                      selectedRegion: _selectedDropdown2 ?? 'Pilih Region',
                                                                                      selectedArea: _selectedDropdown3 ?? 'Pilih Area',
                                                                                      selectedBranch: _selectedDropdown4 ?? 'Pilih Branch',
                                                                                      dseId: item.idDse,
                                                                                      mcId: widget.mcId,
                                                                                      date: DateFormat('yyyy-MM-dd').format(selectedDate),
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              },
                                                                              child: Text(
                                                                                item.idDse,
                                                                                style: const TextStyle(
                                                                                  fontSize: 11,
                                                                                  color: Colors.blue,
                                                                                  decoration: TextDecoration.underline,
                                                                                  fontWeight: FontWeight.w500,
                                                                                ),
                                                                                overflow: TextOverflow.ellipsis,
                                                                              ),
                                                                            )
                                                                          : Text(
                                                                              item.idDse,
                                                                              style: const TextStyle(
                                                                                fontSize: 11,
                                                                                fontWeight: FontWeight.w500,
                                                                                color: textPrimaryColor,
                                                                              ),
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                      isLeftAligned:
                                                                          true,
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
                                                                            200), // Adjust minWidth
                                                                child:
                                                                    DataTable(
                                                                  horizontalMargin:
                                                                      8,
                                                                  columnSpacing:
                                                                      10,
                                                                  headingRowHeight:
                                                                      36,
                                                                  dataRowHeight:
                                                                      48, // Increased for Switch
                                                                  headingRowColor:
                                                                      WidgetStateProperty.all(
                                                                          primaryColor
                                                                              .withOpacity(0.1)),
                                                                  columns: [
                                                                    _buildStyledColumn(
                                                                        "STATUS",
                                                                        headerTableTextColor,
                                                                        width:
                                                                            80), // Adjusted width
                                                                    _buildStyledColumn(
                                                                        "ACTION",
                                                                        headerTableTextColor,
                                                                        width:
                                                                            70), // Adjusted width
                                                                  ],
                                                                  rows: _dseData
                                                                      .map(
                                                                          (item) {
                                                                    final index =
                                                                        _dseData
                                                                            .indexOf(item);
                                                                    return DataRow(
                                                                      color: WidgetStateProperty
                                                                          .resolveWith<
                                                                              Color>(
                                                                        (states) => index % 2 ==
                                                                                0
                                                                            ? Colors.white
                                                                            : const Color(0xFFFAFAFF),
                                                                      ),
                                                                      cells: [
                                                                        _buildStyledDataCell(
                                                                          Container(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 8, vertical: 5), // Adjusted padding
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: item.trackingStatus ? Colors.greenAccent.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                                                                              borderRadius: BorderRadius.circular(16), // Adjusted radius
                                                                            ),
                                                                            child:
                                                                                Text(
                                                                              item.trackingStatus ? 'ACTIVE' : 'INACTIVE',
                                                                              style: TextStyle(
                                                                                fontSize: 10, // Adjusted font size
                                                                                fontWeight: FontWeight.w600,
                                                                                color: item.trackingStatus ? Colors.green.shade700 : Colors.red.shade700,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          alignment:
                                                                              Alignment.center,
                                                                        ),
                                                                        _buildStyledDataCell(
                                                                          Transform
                                                                              .scale(
                                                                            // Scale down the switch if needed
                                                                            scale:
                                                                                0.8,
                                                                            child:
                                                                                Switch.adaptive(
                                                                              value: item.trackingStatus,
                                                                              activeColor: Colors.green,
                                                                              inactiveThumbColor: Colors.grey.shade400,
                                                                              inactiveTrackColor: Colors.grey.shade300,
                                                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                              onChanged: (bool value) async {
                                                                                showDialog(
                                                                                  context: context,
                                                                                  barrierDismissible: false,
                                                                                  builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
                                                                                );
                                                                                await _updateTrackingStatus(item.idUnit, item.idDse, value);
                                                                                if (mounted) Navigator.pop(context);
                                                                              },
                                                                            ),
                                                                          ),
                                                                          alignment:
                                                                              Alignment.center,
                                                                        ),
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
                                    : _buildEmptyState(),
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
            overflow: TextOverflow.ellipsis, // Prevent long text overflow
          ),
        ],
      ),
    );
  }

  // Helper method to build empty state
  Widget _buildEmptyState() {
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
            const Text(
              'No DSE Data Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try changing the date filter',
              style: TextStyle(
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
