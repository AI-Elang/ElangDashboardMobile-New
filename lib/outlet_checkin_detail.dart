import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/outlet_checkin_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OutletCheckinDetail extends StatefulWidget {
  final String userId;
  final String username;
  final String selectedMonth;
  final String selectedYear;

  const OutletCheckinDetail({
    super.key,
    required this.userId,
    required this.username,
    required this.selectedMonth,
    required this.selectedYear,
  });

  @override
  State<OutletCheckinDetail> createState() => _OutletCheckinDetailState();
}

class _OutletCheckinDetailState extends State<OutletCheckinDetail> {
  List<Map<String, dynamic>> _checkinDetailData = [];
  bool _isLoading = true;
  var baseURL = dotenv.env['baseURL'];

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

  Future<void> fetchOutletCheckinDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    // Convert month from 01-12 format to 1-12 format for API
    final monthValue = int.parse(widget.selectedMonth).toString();
    final yearValue = widget.selectedYear;

    final url =
        '$baseURL/api/v1/outlet/checkins/${widget.userId}/details?month=$monthValue&year=$yearValue';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> checkinDetailDataReceived = data['data'];

        setState(() {
          _checkinDetailData = checkinDetailDataReceived
              .map((item) => {
                    'id': item['id'],
                    'outlet_id': item['outlet_id'],
                    'outlet_name': item['outlet_name'],
                    'date': item['date'],
                  })
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to load data: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching data')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOutletCheckinDetails();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final mediaQueryWidth = MediaQuery.of(context).size.width;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define modern color scheme
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
                      'OUTLET CHECKIN DETAIL',
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
                              // User Profile Card
                              Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: cardColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
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
                                              // Display role based on role code
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
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Data Title
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  "Check-in Details",
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

                        // Data table area
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          primaryColor),
                                    ),
                                  )
                                : _checkinDetailData.isEmpty
                                    ? _buildEmptyState('No Details Found',
                                        'There are no check-in details for this user for the selected period.')
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
                                                  '${_checkinDetailData.length} records',
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
                                                // Ensures the DataTable container itself is scrollable if content overflows
                                                child: _checkinDetailData
                                                        .isNotEmpty
                                                    ? SingleChildScrollView(
                                                        scrollDirection: Axis
                                                            .horizontal, // Allows horizontal scrolling for the table
                                                        child: ConstrainedBox(
                                                          // Ensures DataTable takes at least the width of its parent
                                                          constraints: BoxConstraints(
                                                              minWidth:
                                                                  mediaQueryWidth -
                                                                      32), // 32 for horizontal padding of parent
                                                          child: DataTable(
                                                            horizontalMargin:
                                                                12,
                                                            columnSpacing:
                                                                16, // Adjusted for better spacing
                                                            headingRowHeight:
                                                                40,
                                                            dataRowMinHeight:
                                                                40, // Adjusted for consistency
                                                            dataRowMaxHeight:
                                                                45,
                                                            headingRowColor:
                                                                WidgetStateProperty.all(
                                                                    const Color(
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
                                                              // horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.5), // Optional: for vertical lines
                                                            ),
                                                            columns: [
                                                              DataColumn(
                                                                label: SizedBox(
                                                                  // Wrapping in SizedBox to control width
                                                                  width: mediaQueryWidth *
                                                                      0.25, // Responsive width
                                                                  child:
                                                                      const Text(
                                                                    'OUTLET ID',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        color:
                                                                            primaryColor),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataColumn(
                                                                label: SizedBox(
                                                                  width: mediaQueryWidth *
                                                                      0.35, // Responsive width
                                                                  child:
                                                                      const Text(
                                                                    'OUTLET NAME',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        color:
                                                                            primaryColor),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataColumn(
                                                                label: SizedBox(
                                                                  width: mediaQueryWidth *
                                                                      0.2, // Responsive width
                                                                  child:
                                                                      const Text(
                                                                    'DATE',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        color:
                                                                            primaryColor),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                            rows:
                                                                _checkinDetailData
                                                                    .asMap()
                                                                    .entries
                                                                    .map(
                                                                        (entry) {
                                                              int idx =
                                                                  entry.key;
                                                              Map<String,
                                                                      dynamic>
                                                                  item =
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
                                                                }),
                                                                cells: [
                                                                  DataCell(
                                                                    SizedBox(
                                                                      // Ensure cell content respects column width
                                                                      width: mediaQueryWidth *
                                                                          0.25,
                                                                      child:
                                                                          InkWell(
                                                                        onTap:
                                                                            () {
                                                                          Navigator
                                                                              .push(
                                                                            context,
                                                                            MaterialPageRoute(
                                                                              builder: (context) => OutletCheckinImage(
                                                                                checkinId: item['id'].toString(),
                                                                                username: widget.username,
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                        child:
                                                                            Text(
                                                                          item['outlet_id']
                                                                              .toString(),
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            color:
                                                                                Colors.blue,
                                                                            decoration:
                                                                                TextDecoration.underline,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    SizedBox(
                                                                      width: mediaQueryWidth *
                                                                          0.35,
                                                                      child:
                                                                          Text(
                                                                        item['outlet_name']
                                                                            .toString(),
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            color:
                                                                                textPrimaryColor,
                                                                            fontWeight:
                                                                                FontWeight.w500),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        maxLines:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    SizedBox(
                                                                      width:
                                                                          mediaQueryWidth *
                                                                              0.2,
                                                                      child:
                                                                          Text(
                                                                        item['date']
                                                                            .toString(),
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            color:
                                                                                textPrimaryColor,
                                                                            fontWeight:
                                                                                FontWeight.w500),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            }).toList(),
                                                          ),
                                                        ),
                                                      )
                                                    : _buildEmptyState(
                                                        'No Details Found',
                                                        'There are no check-in details for this user for the selected period.'), // Should not be reached if outer check is correct
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                              height:
                                                  80), // Space for bottom nav bar
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
                  mainAxisAlignment: MainAxisAlignment
                      .spaceAround, // Use spaceAround for better spacing if multiple items
                  children: [
                    InkWell(
                      onTap: () {
                        // Navigate back to OutletCheckin page first
                        int count = 0;
                        Navigator.popUntil(context, (route) {
                          return count++ == 2 ||
                              route.settings.name == Navigator.defaultRouteName;
                        });
                        // If not already on home, push replacement
                        if (ModalRoute.of(context)?.settings.name !=
                            Navigator.defaultRouteName) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Homepage()),
                          );
                        }
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

  // Helper method to build empty state
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
