import 'package:elang_dashboard_new_ui/detail_outlet.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DetailOutletValid extends StatefulWidget {
  final String siteId;
  final String brand;

  const DetailOutletValid({
    super.key,
    required this.siteId,
    required this.brand,
  });

  @override
  State<DetailOutletValid> createState() => _DetailOutletValidState();
}

class _DetailOutletValidState extends State<DetailOutletValid> {
  List<Map<String, dynamic>> detailOutletValidData = [];

  bool isLoading = true;

  var baseURL = dotenv.env['baseURL'];

  Future<void> fetchDetailOutletValidData(String? token) async {
    setState(() {
      isLoading = true;
    });
    try {
      final url = Uri.parse(
        '$baseURL/api/v1/sites/${widget.siteId}/detail/outlet?brand=${widget.brand}',
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
            detailOutletValidData =
                List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        } else {
          setState(() {
            detailOutletValidData = [];
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data available')),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching data')),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    fetchDetailOutletValidData(token);
  }

  // Helper method for styled table columns (inspired by reusable_data_table_section.dart)
  DataColumn _buildStyledColumn(String title, Color headerTextColor,
      {bool isHeaderLeft = false}) {
    return DataColumn(
      label: Container(
        alignment: isHeaderLeft ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: headerTextColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Helper method for styled table cells (inspired by reusable_data_table_section.dart)
  DataCell _buildStyledDataCell(
    String text, {
    bool isLeftAligned = false,
    VoidCallback? onTap,
    bool isTappable = false,
  }) {
    Widget cellContent = Text(
      text,
      style: TextStyle(
        fontSize: 11,
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
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4.0),
        child: cellContent,
      ),
    );
  }

  // Helper method for table empty state
  Widget _buildTableEmptyState(
      String title, String subtitle, Color textPrimaryColor) {
    const textSecondaryColor = Color(0xFF8D8D92);
    return Container(
      padding: const EdgeInsets.all(20.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;

    // Define color scheme similar to DetailSite
    const primaryColor = Color(0xFF6A62B7); // Soft purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    final headerTableTextColor = primaryColor.withOpacity(0.8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header with gradient
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'DETAIL OUTLET VALID',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main content area
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Site Info Card
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: cardColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${widget.siteId} - ${widget.brand}",
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: textPrimaryColor,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Data Table Card
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: cardColor,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20.0), // Add vertical padding
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              16.0), // Add horizontal padding for title
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  primaryColor.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.list_alt, // Example icon
                                              color: primaryColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Data Outlet Valid List - ${detailOutletValidData.length}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Data Table Content - Refactored Structure
                                    isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                                color: primaryColor))
                                        : detailOutletValidData.isNotEmpty
                                            ? Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade200),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  child: SingleChildScrollView(
                                                    // For vertical scroll of table rows if content overflows
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // Fixed Outlet Name Column
                                                        SizedBox(
                                                          width:
                                                              150, // Adjust width as needed
                                                          child: DataTable(
                                                            horizontalMargin: 8,
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
                                                                  'OUTLET NAME',
                                                                  headerTableTextColor,
                                                                  isHeaderLeft:
                                                                      true),
                                                            ],
                                                            rows:
                                                                detailOutletValidData
                                                                    .map(
                                                              (dov) {
                                                                final index =
                                                                    detailOutletValidData
                                                                        .indexOf(
                                                                            dov);
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
                                                                      dov['outlet_name'] ??
                                                                          '',
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
                                                                                DetailOutlet(
                                                                              qrCode: dov['qr_code'],
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            ).toList(),
                                                          ),
                                                        ),

                                                        // Scrollable parameters columns
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
                                                                          80), // Adjust minWidth as needed
                                                              child: DataTable(
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
                                                                      'QR CODE',
                                                                      headerTableTextColor),
                                                                  _buildStyledColumn(
                                                                      'BRAND',
                                                                      headerTableTextColor),
                                                                  _buildStyledColumn(
                                                                      'GA MTD',
                                                                      headerTableTextColor),
                                                                  _buildStyledColumn(
                                                                      'SEC SALDO MTD',
                                                                      headerTableTextColor),
                                                                  _buildStyledColumn(
                                                                      'SUPPLY SP MTD',
                                                                      headerTableTextColor),
                                                                  _buildStyledColumn(
                                                                      'SUPPLY VO MTD',
                                                                      headerTableTextColor),
                                                                ],
                                                                rows:
                                                                    detailOutletValidData
                                                                        .map(
                                                                  (dov) {
                                                                    final index =
                                                                        detailOutletValidData
                                                                            .indexOf(dov);
                                                                    return DataRow(
                                                                      color: WidgetStateProperty.resolveWith<
                                                                          Color>((states) => index % 2 ==
                                                                              0
                                                                          ? Colors
                                                                              .white
                                                                          : const Color(
                                                                              0xFFFAFAFF)),
                                                                      cells: [
                                                                        _buildStyledDataCell(dov['qr_code'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(dov['brand'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(dov['ga_mtd'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(dov['sec_saldo_mtd'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(dov['supply_sp_mtd'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(dov['supply_vo_mtd'] ??
                                                                            '0'),
                                                                      ],
                                                                    );
                                                                  },
                                                                ).toList(),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : _buildTableEmptyState(
                                                'No Data Found',
                                                'There is no outlet valid data to display for this site and brand.',
                                                textPrimaryColor,
                                              ),
                                  ],
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

            // Bottom navigation bar (Styled like detail_site.dart)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60, // Consistent height
                decoration: BoxDecoration(
                  color: cardColor, // Use cardColor for background
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20), // Rounded corners
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15), // Subtle shadow
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      // Use InkWell for tap effect
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
                            color: primaryColor, // Use primary color for icon
                            size: 22,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Home',
                            style: TextStyle(
                              color: primaryColor, // Use primary color for text
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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

            // Loading Indicator Overlay
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
