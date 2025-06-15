import 'package:elang_dashboard_new_ui/foto_mitra_history.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class MitraHistory extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String selectedMonth;
  final String selectedYear;

  const MitraHistory({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.selectedMonth,
    required this.selectedYear,
  });

  @override
  State<MitraHistory> createState() => _MitraHistoryState();
}

class _MitraHistoryState extends State<MitraHistory> {
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

  Future<void> fetchReportDailyData(String? token) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      dataReportDaily = []; // Clear previous data
    });

    try {
      // API call now only uses month and year, specific day/date is removed
      final url = Uri.parse(
        '$baseURL/api/v1/mitra/detail/check-in?partner_id=${widget.partnerId}&month=${widget.selectedMonth}&year=${widget.selectedYear}',
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

    // Define color scheme
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    // Define new columns for the scrollable part of the table
    List<DataColumn> scrollableColumns = [
      DataColumn(
        label: Container(
          alignment: Alignment.centerLeft,
          child: const Text(
            'LATITUDE',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          alignment: Alignment.centerLeft,
          child: const Text(
            'LONGITUDE',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          alignment: Alignment.centerLeft,
          child: const Text(
            'DATE',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor, // Applied background color
      body: SafeArea(
        child: Stack(
          children: [
            // Background Header Section
            Column(
              children: [
                // Header container with gradient (inspired by detail_dse_ai_comparison.dart)
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
                      child: Text(
                        'MITRA HISTORY',
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
                    width: double.infinity, // Ensure it takes full width
                    decoration: const BoxDecoration(
                      color: backgroundColor, // Use defined background color
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO3.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08, // Adjusted opacity
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8), // Consistent padding
                        child: Column(
                          children: [
                            // Partner info card (inspired by detail_dse_ai_comparison.dart)
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
                                            "Partner ID: ${widget.partnerId}",
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: textSecondaryColor,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            "Name: ${widget.partnerName}",
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: textPrimaryColor,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Optionally, add date/month/year info here if needed, styled like in comparison
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

                            // Section Header for Data Table (inspired by detail_dse_ai_comparison.dart)
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
                                    'CHECK-IN DETAILS',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimaryColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!isLoading) // Show count only when not loading
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

                            // Data Table
                            Container(
                              constraints: BoxConstraints(
                                  minHeight: 100,
                                  maxHeight: mediaQueryHeight *
                                      0.62), // Adjusted height
                              // margin: const EdgeInsets.symmetric(horizontal: 10), // Removed margin, using padding from parent
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),

                              // Data Table Content
                              child: isLoading
                                  ? const Center(
                                      child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 40),
                                      child: CircularProgressIndicator(
                                        color: primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ))
                                  : SingleChildScrollView(
                                      child: dataReportDaily.isNotEmpty
                                          ? Column(
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Fixed Column: USERNAME
                                                    DataTable(
                                                      horizontalMargin: 12,
                                                      columnSpacing: 8,
                                                      headingRowHeight: 40,
                                                      dataRowMinHeight: 35,
                                                      dataRowMaxHeight: 45,
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
                                                        // borderRadius: BorderRadius.circular(16) // Cannot apply here directly
                                                      ),
                                                      columns: const [
                                                        DataColumn(
                                                          label: Text(
                                                            'USERNAME',
                                                            style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    primaryColor),
                                                          ),
                                                        ),
                                                      ],
                                                      rows: dataReportDaily
                                                          .asMap()
                                                          .entries
                                                          .map(
                                                        (entry) {
                                                          int idx = entry.key;
                                                          Map<String, dynamic>
                                                              drd = entry.value;
                                                          return DataRow(
                                                            color:
                                                                WidgetStateProperty
                                                                    .resolveWith<
                                                                        Color>(
                                                              (states) {
                                                                return idx %
                                                                            2 ==
                                                                        0
                                                                    ? Colors
                                                                        .white
                                                                    : const Color(
                                                                        0xFFFAFAFF); // Alternating row color
                                                              },
                                                            ),
                                                            cells: [
                                                              DataCell(
                                                                InkWell(
                                                                  onTap: () {
                                                                    if (drd['image'] !=
                                                                            null &&
                                                                        drd['image']
                                                                            .toString()
                                                                            .isNotEmpty) {
                                                                      Navigator
                                                                          .push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              FotoMitraHistory(
                                                                            checkInId:
                                                                                drd['id'],
                                                                          ),
                                                                        ),
                                                                      );
                                                                    } else {
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                              const SnackBar(content: Text('No image available for this user.')));
                                                                    }
                                                                  },
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            4),
                                                                    child: Text(
                                                                      drd['username'] ??
                                                                          'N/A',
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            10,
                                                                        color: Colors
                                                                            .blue, // Keep link color
                                                                        decoration:
                                                                            TextDecoration.underline,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ).toList(),
                                                    ),

                                                    // Scrollable parameters columns
                                                    Expanded(
                                                      child:
                                                          SingleChildScrollView(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        child: DataTable(
                                                          horizontalMargin: 40,
                                                          columnSpacing: 16,
                                                          headingRowHeight: 40,
                                                          dataRowMinHeight: 35,
                                                          dataRowMaxHeight: 45,
                                                          headingRowColor:
                                                              WidgetStateProperty
                                                                  .all(
                                                            const Color(
                                                                0xFFF0F2FF), // Light purple header
                                                          ),
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
                                                          columns:
                                                              scrollableColumns, // Use new columns
                                                          rows: dataReportDaily
                                                              .asMap()
                                                              .entries
                                                              .map(
                                                            (entry) {
                                                              int idx =
                                                                  entry.key;
                                                              Map<String,
                                                                      dynamic>
                                                                  drd =
                                                                  entry.value;
                                                              return DataRow(
                                                                color: WidgetStateProperty
                                                                    .resolveWith<
                                                                        Color>(
                                                                  (states) {
                                                                    return idx %
                                                                                2 ==
                                                                            0
                                                                        ? Colors
                                                                            .white
                                                                        : const Color(
                                                                            0xFFFAFAFF);
                                                                  },
                                                                ),
                                                                cells: [
                                                                  DataCell(
                                                                    Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          vertical:
                                                                              4),
                                                                      child:
                                                                          Text(
                                                                        drd['latitude']?.toString() ??
                                                                            'N/A',
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            color:
                                                                                Colors.grey.shade800,
                                                                            fontWeight: FontWeight.w500),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          vertical:
                                                                              4),
                                                                      child:
                                                                          Text(
                                                                        drd['longitude']?.toString() ??
                                                                            'N/A',
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            color:
                                                                                Colors.grey.shade800,
                                                                            fontWeight: FontWeight.w500),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          vertical:
                                                                              4),
                                                                      child:
                                                                          Text(
                                                                        drd['date']?.toString() ??
                                                                            'N/A',
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            color:
                                                                                Colors.grey.shade800,
                                                                            fontWeight: FontWeight.w500),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          ).toList(),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                          : _buildEmptyState('No Data Found',
                                              'No check-in data available for the selected criteria.'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 72), // Space for bottom nav bar
              ],
            ),

            // Bottom navigation bar (inspired by detail_dse_ai_comparison.dart)
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
                            color: primaryColor, // Use primaryColor
                            size: 22,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Home',
                            style: TextStyle(
                              color: primaryColor, // Use primaryColor
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

  // Helper method to build empty state (inspired by detail_dse_ai_comparison.dart)
  Widget _buildEmptyState(String title, String subtitle) {
    const textPrimaryColor = Color(0xFF2D3142);
    const textSecondaryColor = Color(0xFF8D8D92);
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Margin handled by parent
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Match card/table radius
        // border: Border.all(color: Colors.grey.shade200, width: 1), // Optional border
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded, // More relevant icon
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
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
    );
  }
}
