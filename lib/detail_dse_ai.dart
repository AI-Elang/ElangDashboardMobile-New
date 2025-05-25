import 'package:elang_dashboard_new_ui/detail_foto_ai.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/detail_foto_list_complain.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DetailDseAi extends StatefulWidget {
  final String dseId;
  final String date;
  final String title;

  const DetailDseAi({
    super.key,
    required this.dseId,
    required this.date,
    required this.title,
  });

  @override
  State<DetailDseAi> createState() => _DetailDseAiState();
}

class _DetailDseAiState extends State<DetailDseAi> {
  List<Map<String, dynamic>> outletAiList = [];
  List<Map<String, dynamic>> listOutletComplain = [];

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
        '$baseURL/api/v1/dse-ai/outlet/${widget.dseId}/?date=${widget.date}',
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
            outletAiList = List<Map<String, dynamic>>.from(data['data']);
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

  Future<void> fetchListOutletComplain(String? token) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final url = Uri.parse(
        '$baseURL/api/v1/dse-ai/complaints/${widget.dseId}/?date=${widget.date}',
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
            listOutletComplain = List<Map<String, dynamic>>.from(data['data']);
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    fetchOutletData(token);
    fetchListOutletComplain(token);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;

    // Define color scheme to match DSE report style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

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
                                'SUMMARY DSE AI',
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
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              strokeWidth: 2,
                            ),
                          )
                        : SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                        color:
                                                            textSecondaryColor,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      widget.title,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: primaryColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      widget.date,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            textSecondaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'OUTLET ACTIVITIES',
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
                                            color:
                                                primaryColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${outletAiList.length} outlets',
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
                                  outletAiList.isNotEmpty
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
                                                color: Colors.grey
                                                    .withOpacity(0.1),
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
                                                      columns: const [
                                                        DataColumn(
                                                          label: Text(
                                                            'OUTLET ID',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  primaryColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                      rows: outletAiList
                                                          .map(
                                                              (outletAi) =>
                                                                  DataRow(
                                                                    color: WidgetStateProperty.resolveWith<
                                                                            Color>(
                                                                        (states) {
                                                                      final index =
                                                                          outletAiList
                                                                              .indexOf(outletAi);
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
                                                                            Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                builder: (context) => DetailFotoAi(
                                                                                  date: widget.date,
                                                                                  outletId: outletAi['outlet_id'],
                                                                                  title: outletAi['outlet_name'],
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(vertical: 4),
                                                                            child:
                                                                                Text(
                                                                              outletAi['outlet_id'] ?? '',
                                                                              style: const TextStyle(
                                                                                fontSize: 12,
                                                                                color: Colors.blue,
                                                                                decoration: TextDecoration.underline,
                                                                                fontWeight: FontWeight.w500,
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
                                                                color: Colors
                                                                    .grey
                                                                    .shade200),
                                                            bottom: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade200),
                                                          ),
                                                          columns: const [
                                                            DataColumn(
                                                              label: Text(
                                                                'OUTLET NAME',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'CHECKIN',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'CHECKOUT',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'DURATION',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'VOU IM3 AI',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'VOU 3ID AI',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'PERDANA IM3 AI',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'PERDANA 3ID AI',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'VOU IM3 DSE',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'VOU 3ID DSE',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'PERDANA IM3 DSE',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'PERDANA 3ID DSE',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'ATTRACT',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'PURCHASE',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'EDUCATE',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'FACE',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'SELLIN SP',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'SELLIN VOU',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'SELLIN SALMO',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                          rows: outletAiList
                                                              .map(
                                                                  (outletAi) =>
                                                                      DataRow(
                                                                        color: WidgetStateProperty.resolveWith<Color>(
                                                                            (states) {
                                                                          final index =
                                                                              outletAiList.indexOf(outletAi);
                                                                          return index % 2 == 0
                                                                              ? Colors.white
                                                                              : const Color(0xFFFAFAFF);
                                                                        }),
                                                                        cells: [
                                                                          DataCell(
                                                                            Container(
                                                                              alignment: Alignment.centerLeft,
                                                                              child: Text(
                                                                                outletAi['outlet_name'] ?? '',
                                                                                style: TextStyle(
                                                                                  fontSize: 12,
                                                                                  color: Colors.grey.shade800,
                                                                                  fontWeight: FontWeight.w500,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          _buildStyledDataCell(outletAi['checkin'] ??
                                                                              '-'),
                                                                          _buildStyledDataCell(outletAi['checkout'] ??
                                                                              '-'),
                                                                          _buildStyledDataCell(outletAi['duration'] ??
                                                                              '0'),
                                                                          _buildStyledDataCell(outletAi['voucher_im3'] ??
                                                                              '0'),
                                                                          _buildStyledDataCell(outletAi['voucher_tri'] ??
                                                                              '0'),
                                                                          _buildStyledDataCell(outletAi['perdana_im3'] ??
                                                                              '0'),
                                                                          _buildStyledDataCell(outletAi['perdana_tri'] ??
                                                                              '0'),
                                                                          _buildStyledDataCell(outletAi['voucher_im3_dse'] ??
                                                                              '0'),
                                                                          _buildStyledDataCell(outletAi['voucher_tri_dse'] ??
                                                                              '0'),
                                                                          _buildStyledDataCell(outletAi['perdana_im3_dse'] ??
                                                                              '0'),
                                                                          _buildStyledDataCell(outletAi['perdana_tri_dse'] ??
                                                                              '0'),
                                                                          _buildHighlightedDataCell(
                                                                              outletAi['attract'] ?? '0',
                                                                              accentColor),
                                                                          _buildHighlightedDataCell(
                                                                              outletAi['purchase'] ?? '0',
                                                                              Colors.amber),
                                                                          _buildHighlightedDataCell(
                                                                              outletAi['educate'] ?? '0',
                                                                              Colors.green),
                                                                          _buildHighlightedDataCell(
                                                                              outletAi['face'] ?? '0',
                                                                              primaryColor),
                                                                          _buildHighlightedDataCell(
                                                                              outletAi['sellin_sp'] ?? '0',
                                                                              accentColor),
                                                                          _buildHighlightedDataCell(
                                                                              outletAi['sellin_voucher'] ?? '0',
                                                                              Colors.amber),
                                                                          _buildHighlightedDataCell(
                                                                              outletAi['sellin_salmo'] ?? '0',
                                                                              Colors.green),
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
                                          'Try a different date or DSE ID'),

                                  const SizedBox(
                                      height: 24), // Increased spacing

                                  // Outlet Complain Section Header
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color:
                                                accentColor, // Use accent color for distinction
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'OUTLET COMPLAINTS',
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
                                            color: accentColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${listOutletComplain.length} complaints',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: accentColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Outlet Complain Table - Styled like the first table
                                  listOutletComplain.isNotEmpty
                                      ? Container(
                                          constraints: BoxConstraints(
                                            minHeight: 100,
                                            // Adjust max height based on available space, considering other elements
                                            maxHeight: mediaQueryHeight *
                                                0.4, // Example adjustment
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16),
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
                                            // Ensures content scrolls if it overflows container height
                                            child: Column(
                                              children: [
                                                // Table Layout for Complaints
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Fixed ID Column for Complaints
                                                    DataTable(
                                                      horizontalMargin: 12,
                                                      columnSpacing: 8,
                                                      headingRowHeight:
                                                          40, // Consistent height
                                                      dataRowHeight:
                                                          48, // Consistent height
                                                      headingRowColor:
                                                          WidgetStateProperty
                                                              .all(
                                                        const Color(
                                                            0xFFFFF0F5), // Lighter pink shade for header
                                                      ),
                                                      border: TableBorder(
                                                        // Consistent border
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
                                                            'OUTLET ID',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  accentColor, // Use accent color
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                      rows: listOutletComplain
                                                          .map(
                                                            (complain) =>
                                                                DataRow(
                                                              color: WidgetStateProperty
                                                                  .resolveWith<
                                                                          Color>(
                                                                      // Alternating row colors
                                                                      (states) {
                                                                final index =
                                                                    listOutletComplain
                                                                        .indexOf(
                                                                            complain);
                                                                return index %
                                                                            2 ==
                                                                        0
                                                                    ? Colors
                                                                        .white
                                                                    : const Color(
                                                                        0xFFFFF8FB); // Very light pink
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
                                                                              DetailFotoListComplain(
                                                                            date:
                                                                                widget.date,
                                                                            outletId:
                                                                                complain['outlet_id'],
                                                                            title:
                                                                                complain['outlet_name'],
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
                                                                        complain['outlet_id'] ??
                                                                            '',
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          color:
                                                                              Colors.blue, // Keep link style
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
                                                            ),
                                                          )
                                                          .toList(),
                                                    ),

                                                    // Scrollable parameters columns for Complaints
                                                    Expanded(
                                                      child:
                                                          SingleChildScrollView(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        child: DataTable(
                                                          horizontalMargin: 12,
                                                          columnSpacing:
                                                              16, // Consistent spacing
                                                          headingRowHeight:
                                                              40, // Consistent height
                                                          dataRowHeight:
                                                              48, // Consistent height
                                                          headingRowColor:
                                                              WidgetStateProperty
                                                                  .all(
                                                            const Color(
                                                                0xFFFFF0F5), // Lighter pink shade
                                                          ),
                                                          border: TableBorder(
                                                            // Consistent border
                                                            top: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade200),
                                                            bottom: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade200),
                                                          ),
                                                          columns: const [
                                                            DataColumn(
                                                              label: Text(
                                                                'OUTLET NAME',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        accentColor),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'USERNAME',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        accentColor),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'CATEGORY',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        accentColor),
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'COMPLAIN DATE',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        accentColor),
                                                              ),
                                                            ),
                                                          ],
                                                          rows:
                                                              listOutletComplain
                                                                  .map(
                                                                    (complain) =>
                                                                        DataRow(
                                                                      color: WidgetStateProperty.resolveWith<
                                                                              Color>(
                                                                          // Alternating row colors
                                                                          (states) {
                                                                        final index =
                                                                            listOutletComplain.indexOf(complain);
                                                                        return index % 2 ==
                                                                                0
                                                                            ? Colors.white
                                                                            : const Color(0xFFFFF8FB); // Very light pink
                                                                      }),
                                                                      cells: [
                                                                        // Use _buildStyledDataCell for consistency
                                                                        _buildStyledDataCell(complain['outlet_name'] ??
                                                                            '-'),
                                                                        _buildStyledDataCell(complain['username'] ??
                                                                            '-'),
                                                                        _buildStyledDataCell(complain['category'] ??
                                                                            '-'),
                                                                        _buildStyledDataCell(complain['complaint_date'] ??
                                                                            '-'),
                                                                      ],
                                                                    ),
                                                                  )
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
                                      : _buildEmptyState('No Complaints Found',
                                          'No complaints recorded for this date'),
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
