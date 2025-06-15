import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/outlet_checkin_detail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OutletCheckin extends StatefulWidget {
  const OutletCheckin({
    super.key,
  });

  @override
  State<OutletCheckin> createState() => _OutletCheckinState();
}

class _OutletCheckinState extends State<OutletCheckin> {
  List<Map<String, dynamic>> _checkinData = [];
  bool _isLoading = false; // Change initial loading state
  var baseURL = dotenv.env['baseURL'];

  // Add month and year state variables
  String? _selectedMonth;
  String? _selectedYear;

  List<Map<String, String>> _monthOptions = [];
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
  List<String> _yearOptions = [];

  // Add month options update method
  void _updateMonthOptionsAndSelection() {
    if (_selectedYear == null) {
      if (!mounted) return;
      setState(() {
        _monthOptions = [];
        _selectedMonth = null;
      });
      return;
    }

    final now = DateTime.now();
    final currentActualYear = now.year;
    final currentActualMonthNumber = now.month;

    List<Map<String, String>> newAvailableMonths;
    int yearToCompare = int.parse(_selectedYear!);

    if (yearToCompare < currentActualYear) {
      newAvailableMonths = List.from(_allMonths);
    } else if (yearToCompare == currentActualYear) {
      newAvailableMonths = _allMonths.sublist(0, currentActualMonthNumber);
    } else {
      newAvailableMonths = _allMonths.sublist(0, currentActualMonthNumber);
    }

    String? newSelectedMonth = _selectedMonth;
    if (newSelectedMonth != null &&
        !newAvailableMonths.any((m) => m['value'] == newSelectedMonth)) {
      newSelectedMonth = null;
    }

    if (newSelectedMonth == null && newAvailableMonths.isNotEmpty) {
      String currentActualMonthPadded = now.month.toString().padLeft(2, '0');
      if (newAvailableMonths
          .any((m) => m['value'] == currentActualMonthPadded)) {
        newSelectedMonth = currentActualMonthPadded;
      } else {
        newSelectedMonth = newAvailableMonths.last['value'];
      }
    }

    if (newAvailableMonths.isEmpty) {
      newSelectedMonth = null;
    }

    if (!mounted) return;
    setState(() {
      _monthOptions = newAvailableMonths;
      _selectedMonth = newSelectedMonth;
    });
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

  Future<void> fetchOutletCheckins() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final role = authProvider.role;

    // Check if month and year are selected
    if (_selectedMonth == null || _selectedYear == null) {
      setState(() {
        _isLoading = false;
        _checkinData = [];
      });
      return;
    }

    // Convert month from 01-12 format to 1-12 format for API
    final monthValue = int.parse(_selectedMonth!).toString();
    final yearValue = _selectedYear!;

    final url =
        '$baseURL/api/v1/outlet/checkins?role=$role&month=$monthValue&year=$yearValue';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> checkinDataReceived = data['data'];

        setState(() {
          _checkinData = checkinDataReceived
              .map((item) => {
                    'id': item['id'],
                    'username': item['username'],
                    'checkin_count': item['checkin_count'],
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

    // Initialize year and month
    _selectedYear = '2025';
    _yearOptions = ['2025'];
    _selectedMonth = DateTime.now().month.toString().padLeft(2, '0');
    _updateMonthOptionsAndSelection();

    // Don't fetch data initially, wait for user selection
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
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
                      'OUTLET CHECK-IN',
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

                              const SizedBox(height: 12),

                              // Month and Year Selection
                              Row(
                                children: [
                                  // Year Dropdown
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: cardColor,
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
                                              color: textSecondaryColor
                                                  .withOpacity(0.8),
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
                                                      if (newValue != null) {
                                                        setState(() {
                                                          _selectedYear =
                                                              newValue;
                                                          _updateMonthOptionsAndSelection();
                                                          if (_selectedMonth !=
                                                              null) {
                                                            fetchOutletCheckins();
                                                          }
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
                                                          : textPrimaryColor,
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
                                        color: cardColor,
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
                                              color: textSecondaryColor
                                                  .withOpacity(0.8),
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
                                              onChanged: _isLoading ||
                                                      (_monthOptions.isEmpty ||
                                                          _selectedYear == null)
                                                  ? null
                                                  : (String? newValue) {
                                                      if (newValue != null) {
                                                        setState(() {
                                                          _selectedMonth =
                                                              newValue;
                                                          fetchOutletCheckins();
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
                                                          : textPrimaryColor,
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

                              const SizedBox(height: 16),

                              // Data Title
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  "Outlet Check-ins",
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
                                : _checkinData.isEmpty
                                    ? _buildEmptyState('No Data Available',
                                        'Please select a valid month and year to view outlet check-ins.')
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
                                                  '${_checkinData.length} users',
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
                                                    // Username Column (Fixed)
                                                    DataTable(
                                                      horizontalMargin: 12,
                                                      columnSpacing: 8,
                                                      headingRowHeight: 36,
                                                      dataRowMinHeight: 40,
                                                      dataRowMaxHeight: 40,
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
                                                            'USERNAME',
                                                            TextAlign.left),
                                                      ],
                                                      rows: _checkinData
                                                          .map(
                                                              (item) => DataRow(
                                                                    color: WidgetStateProperty.resolveWith<
                                                                            Color>(
                                                                        (states) {
                                                                      final index =
                                                                          _checkinData
                                                                              .indexOf(item);
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
                                                                        Container(
                                                                          padding: const EdgeInsets
                                                                              .symmetric(
                                                                              vertical: 4),
                                                                          child:
                                                                              Text(
                                                                            item['username'].toString(),
                                                                            style:
                                                                                const TextStyle(
                                                                              fontSize: 12,
                                                                              color: textPrimaryColor,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                2,
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
                                                          horizontalMargin: 130,
                                                          columnSpacing: 16,
                                                          headingRowHeight: 36,
                                                          dataRowMinHeight: 40,
                                                          dataRowMaxHeight: 40,
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
                                                                'OUTLET CHECKIN',
                                                                TextAlign
                                                                    .center),
                                                          ],
                                                          rows: _checkinData
                                                              .map((mc) {
                                                            final checkinCount =
                                                                mc['checkin_count'] ??
                                                                    0;
                                                            final canNavigate =
                                                                checkinCount >
                                                                    0;
                                                            return DataRow(
                                                              color: WidgetStateProperty
                                                                  .resolveWith<
                                                                          Color>(
                                                                      (states) {
                                                                final index =
                                                                    _checkinData
                                                                        .indexOf(
                                                                            mc);
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
                                                                                builder: (context) => OutletCheckinDetail(
                                                                                  userId: mc['id'].toString(),
                                                                                  username: mc['username'].toString(),
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
                                          const SizedBox(height: 80),
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

  // Helper method to build styled table columns
  DataColumn _buildStyledColumn(String title, TextAlign align) {
    const primaryColor = Color(0xFF6A62B7);
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
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
