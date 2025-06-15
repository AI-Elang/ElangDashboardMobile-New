import 'package:elang_dashboard_new_ui/foto_outlet_history.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:elang_dashboard_new_ui/widgets/reusable_data_table_section.dart';

import 'dart:convert';

class OutletHistory extends StatefulWidget {
  final String outletId;
  final String outletName;
  final String selectedMonth;
  final String selectedYear;

  const OutletHistory({
    super.key,
    required this.outletId,
    required this.outletName,
    required this.selectedMonth,
    required this.selectedYear,
  });

  @override
  State<OutletHistory> createState() => _OutletHistoryState();
}

class _OutletHistoryState extends State<OutletHistory> {
  final formatter = NumberFormat('#,###', 'id_ID');

  String errorMessage = '';
  String formatNumber(dynamic value) {
    if (value == null) return '0';
    int? number = int.tryParse(value.toString());
    if (number == null) return '0';
    return formatter.format(number).replaceAll(',', '.');
  }

  bool isLoading = true;

  List<Map<String, dynamic>> dataReportDaily =
      []; // This will now store check-in data

  var baseURL = dotenv.env['baseURL'];

  // Define color scheme (from mitra_history.dart)
  static const primaryColor = Color(0xFF6A62B7); // Softer purple
  static const accentColor = Color(0xFFEE92C2); // Soft pink
  static const backgroundColor = Color(0xFFF8F9FA); // Off-white background
  static const cardColor = Colors.white;
  static const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
  static const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

  Future<void> fetchReportDailyData(String? token) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      dataReportDaily = []; // Clear previous data
    });

    try {
      // API call now only uses month and year, specific day/date is removed
      final url = Uri.parse(
        '$baseURL/api/v1/outlet/detail/check-in?outlet_id=${widget.outletId}&month=${widget.selectedMonth}&year=${widget.selectedYear}',
      );

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            dataReportDaily = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        } else {
          // Handle cases where 'data' might be null or not a list, e.g., empty response
          setState(() {
            isLoading = false;
            // Optionally set an error message or leave dataReportDaily empty
          });
        }
      } else {
        setState(() {
          isLoading = false;
          // Use ScaffoldMessenger to show SnackBar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to load data: ${response.statusCode}')));
          }
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        // Use ScaffoldMessenger to show SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error fetching data')));
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    fetchReportDailyData(token);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor, // Applied background color
      body: SafeArea(
        child: Stack(
          children: [
            // Background Header Section
            Column(
              children: [
                Container(
                  height: mediaQueryHeight * 0.06, // Adjusted height
                  width:
                      double.infinity, // Use mediaQueryWidth or double.infinity
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
                    padding: EdgeInsets.symmetric(
                        horizontal: 16), // Consistent padding
                    child: Center(
                      // Center the text
                      child: Text(
                        'OUTLET HISTORY',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors
                              .white, // Text color white for better contrast
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5, // Added letter spacing
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  // Use Expanded for the main content area
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: backgroundColor, // Use defined background color
                      // Removed BorderRadius here as it's part of the overall page background
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO3.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08, // Adjusted opacity
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8), // Consistent padding
                      child: Column(
                        children: [
                          // Outlet info card
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "OUTLET ID: ${widget.outletId}",
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: textSecondaryColor,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          "Name: ${widget.outletName}",
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: textPrimaryColor,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${widget.selectedMonth} / ${widget.selectedYear}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: textSecondaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Section Header for Data Table - This is now part of ReusableDataTableSection
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                const Spacer(),
                                if (!isLoading)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${dataReportDaily.length} entries',
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

                          // Data Table replaced with ReusableDataTableSection
                          ReusableDataTableSection(
                            title: 'CHECK-IN DETAILS',
                            icon: Icons.list_alt_rounded, // Example Icon
                            sectionColor: primaryColor,
                            textPrimaryColor: textPrimaryColor,
                            cardColor:
                                cardColor, // Keep original cardColor for now, or set to Colors.transparent if desired after fixing layout
                            data: dataReportDaily.map((item) {
                              // The 'username_display' key is used for display.
                              // The original 'username' and 'id' keys are still in 'item'
                              // and will be accessible in the onFixedCellTap callback.
                              return {
                                ...item,
                                'username_display': item['username'] ?? 'N/A',
                              };
                            }).toList(),
                            fixedColumn: const {
                              'key':
                                  'username_display', // This key is used for display
                              'header': 'USERNAME',
                              'width': 100.0, // Adjusted width
                            },
                            scrollableColumns: const [
                              {'key': 'latitude', 'header': 'LATITUDE'},
                              {'key': 'longitude', 'header': 'LONGITUDE'},
                              {'key': 'date', 'header': 'DATE'},
                            ],
                            isLoading: isLoading,
                            emptyStateTitle: 'No Data Found',
                            emptyStateSubtitle:
                                'No check-in data available for the selected criteria.',
                            emptyStateIcon: Icons.search_off_rounded,
                            numberFormatter: (value) =>
                                value?.toString() ?? 'N/A',
                            onFixedCellTap: (itemData) {
                              // Added callback
                              final checkInId = itemData['id'];
                              if (checkInId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FotoOutletHistory(
                                      checkInId: checkInId is int
                                          ? checkInId
                                          : int.parse(checkInId.toString()),
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Check-in ID not available for this entry.')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60, // Adjusted height
                decoration: BoxDecoration(
                  color: cardColor, // Use cardColor for consistency
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
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
                    InkWell(
                      // Changed IconButton to InkWell for custom layout
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Homepage()),
                        );
                      },
                      child: const Column(
                        // Use Column for Icon and Text
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home,
                            color: primaryColor, // Use primaryColor
                            size: 22, // Adjusted size
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Home',
                            style: TextStyle(
                              color: primaryColor, // Use primaryColor
                              fontSize: 11, // Adjusted font size
                              fontWeight: FontWeight.w600, // Added font weight
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

  // _buildEmptyState method removed as ReusableDataTableSection handles its own empty state
}
