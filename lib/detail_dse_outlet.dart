import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DetailDseOutlet extends StatefulWidget {
  final String dseId;
  final String status;
  final String title;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;

  const DetailDseOutlet({
    super.key,
    required this.dseId,
    required this.status,
    required this.title,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
  });

  @override
  State<DetailDseOutlet> createState() => _DetailDseOutletState();
}

class _DetailDseOutletState extends State<DetailDseOutlet> {
  List<Map<String, dynamic>> outletList = [];

  final formatter = NumberFormat('#,###', 'id_ID');
  String errorMessage = '';
  bool isLoading = true;

  String formatNumber(dynamic value) {
    if (value == null) return '0';
    int? number = int.tryParse(value.toString());
    if (number == null) return '0';
    return formatter.format(number).replaceAll(',', '.');
  }

  var baseURL = dotenv.env['baseURL'];

  Future<void> fetchOutletData(String? token) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final url = Uri.parse(
        '$baseURL/api/v1/dse/pjp-dse-daily/${widget.dseId}/outlet?status=${widget.status}',
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
            outletList = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    final token = Provider.of<AuthProvider>(context, listen: false).token;

    fetchOutletData(token);
  }

  // Helper methods for styled table (inspired by reusable_data_table_section.dart)
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
    Color? textColor,
    FontWeight? fontWeight,
    List<Shadow>? shadows,
  }) {
    Widget cellContent = Text(
      text,
      style: TextStyle(
        fontSize: 11, // Matched with ReusableDataTableSection
        color: textColor ?? Colors.grey.shade800,
        fontWeight: fontWeight ?? FontWeight.w500,
        shadows: shadows,
      ),
      overflow: TextOverflow.ellipsis,
    );

    return DataCell(
      Container(
        alignment: isLeftAligned ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4.0),
        child: cellContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;

    // Define our color scheme - matching MC style
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
                      child: Text(
                        'SUMMARY DSE OUTLET',
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
                      color: backgroundColor,
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    // Removed SingleChildScrollView from here
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title section
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
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
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'DSE ID: ${widget.dseId}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: textSecondaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Status: ${widget.status}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: widget.status == 'vc'
                                                ? Colors.green.shade700
                                                : widget.status == 'nc'
                                                    ? Colors.red.shade700
                                                    : Colors.orange.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isLoading
                                          ? '...'
                                          : '${outletList.length} outlets',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Data section - Make this card Expanded
                          Expanded(
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: cardColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: accentColor,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Outlet Details',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimaryColor,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isLoading)
                                          const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      primaryColor),
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Table section - Make this container Expanded
                                    Expanded(
                                      child: Builder(builder: (context) {
                                        if (isLoading) {
                                          return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(32.0),
                                              child: Text(
                                                'Loading data...',
                                                style: TextStyle(
                                                  color: textSecondaryColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          );
                                        } else if (errorMessage.isNotEmpty) {
                                          return Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(32.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.error_outline,
                                                    size: 48,
                                                    color: Colors.red.shade300,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'Error loading data',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else if (outletList.isEmpty) {
                                          return Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(32.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.search_off_rounded,
                                                    size: 48,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'No Outlet Data Found',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'There are no outlets available for this DSE',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade200),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              // Replaced Column with SingleChildScrollView for vertical scroll of table rows
                                              child: SingleChildScrollView(
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Outlet names column - Fixed Left
                                                    SizedBox(
                                                      // Added SizedBox to constrain width
                                                      width:
                                                          100, // Adjust width as needed
                                                      child: DataTable(
                                                        horizontalMargin:
                                                            8, // Adjusted
                                                        columnSpacing:
                                                            4, // Adjusted
                                                        headingRowHeight:
                                                            36, // Adjusted
                                                        dataRowHeight:
                                                            32, // Adjusted
                                                        headingRowColor:
                                                            WidgetStateProperty
                                                                .all(
                                                          primaryColor.withOpacity(
                                                              0.1), // Adjusted
                                                        ),
                                                        // Removed border from individual DataTables, parent Container has it
                                                        columns: [
                                                          _buildStyledColumn(
                                                            // Using helper
                                                            'OUTLET NAME',
                                                            headerTableTextColor,
                                                            isHeaderLeft: true,
                                                          ),
                                                        ],
                                                        rows: outletList
                                                            .map((outlet) {
                                                          final index =
                                                              outletList
                                                                  .indexOf(
                                                                      outlet);
                                                          return DataRow(
                                                            color: WidgetStateProperty
                                                                .resolveWith<
                                                                    Color>((Set<
                                                                        WidgetState>
                                                                    states) {
                                                              return index %
                                                                          2 ==
                                                                      0
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFFFAFAFF);
                                                            }),
                                                            cells: [
                                                              _buildStyledDataCell(
                                                                // Using helper
                                                                outlet['nama_outlet'] ??
                                                                    '',
                                                                isLeftAligned:
                                                                    true,
                                                                textColor:
                                                                    textPrimaryColor,
                                                              ),
                                                            ],
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),

                                                    // Scrollable data columns
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
                                                                      300), // Adjust minWidth
                                                          child: DataTable(
                                                            horizontalMargin:
                                                                8, // Adjusted
                                                            columnSpacing:
                                                                10, // Adjusted
                                                            headingRowHeight:
                                                                36, // Adjusted
                                                            dataRowHeight:
                                                                32, // Adjusted
                                                            headingRowColor:
                                                                WidgetStateProperty
                                                                    .all(
                                                              primaryColor
                                                                  .withOpacity(
                                                                      0.1), // Adjusted
                                                            ),
                                                            // Removed border
                                                            columns: [
                                                              _buildStyledColumn(
                                                                  'RGU',
                                                                  headerTableTextColor),
                                                              _buildStyledColumn(
                                                                  'SEC SALDO',
                                                                  headerTableTextColor),
                                                              _buildStyledColumn(
                                                                  'SP HIT',
                                                                  headerTableTextColor),
                                                              _buildStyledColumn(
                                                                  'VOU NET',
                                                                  headerTableTextColor),
                                                              _buildStyledColumn(
                                                                  'REBUY',
                                                                  headerTableTextColor),
                                                              _buildStyledColumn(
                                                                  'QURO',
                                                                  headerTableTextColor),
                                                              _buildStyledColumn(
                                                                  'QSSO',
                                                                  headerTableTextColor),
                                                            ],
                                                            rows: outletList
                                                                .map((outlet) {
                                                              final index =
                                                                  outletList
                                                                      .indexOf(
                                                                          outlet);
                                                              return DataRow(
                                                                color: WidgetStateProperty
                                                                    .resolveWith<
                                                                        Color>((Set<
                                                                            WidgetState>
                                                                        states) {
                                                                  return index %
                                                                              2 ==
                                                                          0
                                                                      ? Colors
                                                                          .white
                                                                      : const Color(
                                                                          0xFFFAFAFF);
                                                                }),
                                                                cells: [
                                                                  _buildStyledDataCell(
                                                                      outlet['rgu_ga'] ??
                                                                          '0'),
                                                                  _buildStyledDataCell(
                                                                    formatNumber(
                                                                        outlet[
                                                                            'sec_saldo_net']),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    shadows: [
                                                                      Shadow(
                                                                        color: primaryColor
                                                                            .withOpacity(0.3),
                                                                        offset: const Offset(
                                                                            0,
                                                                            1),
                                                                        blurRadius:
                                                                            1,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  _buildStyledDataCell(
                                                                    formatNumber(
                                                                        outlet[
                                                                            'supply_sp_hits']),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    shadows: [
                                                                      Shadow(
                                                                        color: Colors
                                                                            .amber
                                                                            .withOpacity(0.3),
                                                                        offset: const Offset(
                                                                            0,
                                                                            1),
                                                                        blurRadius:
                                                                            1,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  _buildStyledDataCell(
                                                                      outlet['supply_vo_net'] ??
                                                                          '0'),
                                                                  _buildStyledDataCell(
                                                                    formatNumber(
                                                                        outlet[
                                                                            'supply_rebuy_net']),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    shadows: [
                                                                      Shadow(
                                                                        color: accentColor
                                                                            .withOpacity(0.3),
                                                                        offset: const Offset(
                                                                            0,
                                                                            1),
                                                                        blurRadius:
                                                                            1,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  _buildStyledDataCell(
                                                                      formatNumber(
                                                                          outlet[
                                                                              'quro'])),
                                                                  _buildStyledDataCell(
                                                                      formatNumber(
                                                                          outlet[
                                                                              'qsso'])),
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
                                          );
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Add space for bottom navigation
                          const SizedBox(
                              height:
                                  55), // This might need adjustment if page isn't scrolling
                        ],
                      ),
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
}
