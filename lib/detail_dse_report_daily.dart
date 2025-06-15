import 'package:elang_dashboard_new_ui/detail_dse_ai.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DetailDseReportDaily extends StatefulWidget {
  final String dseId;

  const DetailDseReportDaily({
    super.key,
    required this.dseId,
  });

  @override
  State<DetailDseReportDaily> createState() => _DetailDseReportDailyState();
}

class _DetailDseReportDailyState extends State<DetailDseReportDaily> {
  final formatter = NumberFormat('#,###', 'id_ID');

  String errorMessage = '';
  String formatNumber(dynamic value) {
    if (value == null) return '0';
    int? number = int.tryParse(value.toString());
    if (number == null) return '0';
    return formatter.format(number).replaceAll(',', '.');
  }

  DateTime selectedDate = DateTime.now();

  bool isLoading = true;

  List<Map<String, dynamic>> dataReportDaily = [];

  var baseURL = dotenv.env['baseURL'];

  Future<void> fetchReportDailyData(String? token) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final url = Uri.parse(
        '$baseURL/api/v1/dse-ai/${widget.dseId}/daily?date=$formattedDate',
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
        }
      } else {
        setState(() {
          isLoading = false;
          SnackBar(
              content: Text('Failed to load data: ${response.statusCode}'));
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        const SnackBar(content: Text('Error fetching data'));
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchReportDailyData(token);
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

    String brand = '';
    if (dataReportDaily.isNotEmpty) {
      String mcName = dataReportDaily[0]['mc_name'] ?? 'N/A';
      List<String> parts = mcName.split(' ');
      brand = parts.isNotEmpty ? parts.last : 'N/A';
    }

    // Define color scheme to match DSE report style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    List<DataColumn> columns = [
      _buildStyledColumn('CHECKIN'),
      _buildStyledColumn('CHECKOUT'),
      _buildStyledColumn('DURATION'),
      _buildStyledColumn('TARGET PJP'),
      _buildStyledColumn('ACTUAL PJP'),
      _buildStyledColumn('PERCENTAGE'),
      _buildStyledColumn('SELLIN SP'),
      _buildStyledColumn('SELLIN VOU'),
      _buildStyledColumn('SELLIN SALMO'),
    ];

    if (brand == 'IM3') {
      columns.addAll([
        _buildStyledColumn('PERDANA IM3'),
        _buildStyledColumn('VOUCHER IM3'),
      ]);
    } else if (brand == '3ID') {
      columns.addAll([
        _buildStyledColumn('PERDANA TRI'),
        _buildStyledColumn('VOUCHER TRI'),
      ]);
    }

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
                                'SUMMARY DSE AI DAILY',
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
                        image: AssetImage('assets/LOGO3.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            // User profile and filters card
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: cardColor,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // DSE Info
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // DSE Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'DSE ID: ${widget.dseId}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: textSecondaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                "${dataReportDaily.isNotEmpty ? dataReportDaily[0]['mc_name'] : 'N/A'}",
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
                                                dataReportDaily.isNotEmpty
                                                    ? dataReportDaily[0]
                                                            ['mtd_dt'] ??
                                                        'N/A'
                                                    : 'N/A',
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

                                    const SizedBox(height: 16),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),

                                    // Date filter section
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Date Filter",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        // Date picker
                                        InkWell(
                                          onTap: () => _selectDate(context),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 14),
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
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  DateFormat('dd MMMM yyyy')
                                                      .format(selectedDate),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: textPrimaryColor,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.grey.shade600,
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

                            const SizedBox(height: 16),

                            // Report List Section Header
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
                                    'DAILY ACTIVITY',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimaryColor,
                                    ),
                                  ),
                                  const Spacer(),
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

                            // Data table
                            isLoading
                                ? const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 40),
                                      child: CircularProgressIndicator(
                                        color: primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : dataReportDaily.isNotEmpty
                                    ? Container(
                                        constraints: BoxConstraints(
                                          minHeight: 100,
                                          maxHeight: mediaQueryHeight * 0.580,
                                        ),
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
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              // Table Layout
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // ID Column - Fixed Left
                                                  DataTable(
                                                    horizontalMargin: 12,
                                                    columnSpacing: 8,
                                                    headingRowHeight: 40,
                                                    headingRowColor:
                                                        WidgetStateProperty.all(
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
                                                    columns: const [
                                                      DataColumn(
                                                        label: Text(
                                                          'DSE ID',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                    rows: dataReportDaily
                                                        .map((drd) => DataRow(
                                                              color: WidgetStateProperty
                                                                  .resolveWith<
                                                                          Color>(
                                                                      (states) {
                                                                final index =
                                                                    dataReportDaily
                                                                        .indexOf(
                                                                            drd);
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
                                                                    onTap: () {
                                                                      Navigator
                                                                          .push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              DetailDseAi(
                                                                            date:
                                                                                DateFormat('yyyy-MM-dd').format(selectedDate),
                                                                            dseId:
                                                                                drd['id'],
                                                                            title:
                                                                                drd['id'],
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
                                                                        drd['id'] ??
                                                                            '',
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
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ))
                                                        .toList(),
                                                  ),

                                                  // Scrollable parameters columns
                                                  Expanded(
                                                    child:
                                                        SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: DataTable(
                                                        horizontalMargin: 12,
                                                        columnSpacing: 16,
                                                        headingRowHeight: 40,
                                                        dataRowHeight: 48,
                                                        headingRowColor:
                                                            WidgetStateProperty
                                                                .all(
                                                          const Color(
                                                              0xFFF0F2FF),
                                                        ),
                                                        border: TableBorder(
                                                          top: BorderSide(
                                                              color: Colors.grey
                                                                  .shade200),
                                                          bottom: BorderSide(
                                                              color: Colors.grey
                                                                  .shade200),
                                                        ),
                                                        columns: columns,
                                                        rows: dataReportDaily
                                                            .map(
                                                                (drd) =>
                                                                    DataRow(
                                                                      color: WidgetStateProperty.resolveWith<
                                                                              Color>(
                                                                          (states) {
                                                                        final index =
                                                                            dataReportDaily.indexOf(drd);
                                                                        return index % 2 ==
                                                                                0
                                                                            ? Colors.white
                                                                            : const Color(0xFFFAFAFF);
                                                                      }),
                                                                      cells: [
                                                                        _buildStyledDataCell(drd['checkin'] ??
                                                                            '-'),
                                                                        _buildStyledDataCell(drd['checkout'] ??
                                                                            '-'),
                                                                        _buildStyledDataCell(drd['duration'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(drd['target_pjp'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(drd['actual_pjp'] ??
                                                                            '0'),
                                                                        _buildStyledDataCell(drd['percentage'] ??
                                                                            '0'),
                                                                        _buildHighlightedDataCell(
                                                                            drd['sp'] ??
                                                                                '0',
                                                                            accentColor),
                                                                        _buildHighlightedDataCell(
                                                                            drd['vou'] ??
                                                                                '0',
                                                                            Colors.amber),
                                                                        _buildHighlightedDataCell(
                                                                            drd['salmo'] ??
                                                                                '0',
                                                                            Colors.green),
                                                                        if (brand ==
                                                                            'IM3') ...[
                                                                          _buildStyledDataCell(drd['perdana_im3'] ??
                                                                              '0'),
                                                                          _buildStyledDataCell(drd['voucher_im3'] ??
                                                                              '0'),
                                                                        ] else if (brand ==
                                                                            '3ID') ...[
                                                                          _buildStyledDataCell(drd['perdana_tri'] ??
                                                                              '0'),
                                                                          _buildStyledDataCell(drd['voucher_tri'] ??
                                                                              '0'),
                                                                        ],
                                                                      ],
                                                                    ))
                                                            .toList(),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : _buildEmptyState('No Data Available',
                                        'Try changing date filter'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 72),
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

  // Helper methods for styled table
  DataColumn _buildStyledColumn(String title) {
    return DataColumn(
      label: Container(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A62B7),
          ),
        ),
      ),
    );
  }

  DataCell _buildStyledDataCell(String text) {
    return DataCell(
      Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  DataCell _buildHighlightedDataCell(String text, Color color) {
    return DataCell(
      Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w600,
            // Add a subtle color highlight to important metrics
            shadows: [
              Shadow(
                color: color.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build empty state
  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 40),
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
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
