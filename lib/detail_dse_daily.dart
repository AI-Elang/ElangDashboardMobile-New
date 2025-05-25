import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/detail_dse_outlet.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DetailDseDaily extends StatefulWidget {
  final String dseId;
  final String branchName;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;

  const DetailDseDaily({
    super.key,
    required this.dseId,
    required this.branchName,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
  });

  @override
  State<DetailDseDaily> createState() => _DetailDseDailyState();
}

class _DetailDseDailyState extends State<DetailDseDaily> {
  String formatWithDots(int number) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(number).replaceAll(',', '.');
  }

  int parseNumberWithDots(String? value) {
    if (value == null) return 0;
    return int.tryParse(value.replaceAll('.', '')) ?? 0;
  }

  List<Map<String, dynamic>> productList = [];
  Map<String, dynamic> dailyData =
      {}; // Add a map to store daily data dynamically

  var baseURL = dotenv.env['baseURL'];

  Future<void> _fetchDataDaily(String? token) async {
    final dseId = widget.dseId;
    final url = Uri.parse('$baseURL/api/v1/dse/pjp-dse-daily/$dseId');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          // Store the entire data map
          dailyData = Map<String, dynamic>.from(data);
        });
      } else {
        const SnackBar(content: Text('Failed to load data'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchDataProduct(String? token) async {
    final dseId = widget.dseId;
    final url = Uri.parse('$baseURL/api/v1/dse/pjp-dse-product/$dseId');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          productList = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        SnackBar(content: Text('Failed to load data ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    _fetchDataDaily(token);
    _fetchDataProduct(token);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;

    // Define color scheme consistent with monthly report
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
            // Main content
            Column(
              children: [
                // Header with gradient like in monthly report
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
                          'DSE DAILY REPORT',
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
                        image: AssetImage('assets/LOGO.png'),
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
                            // DSE Info Card
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
                                    // DSE Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'DSE ID',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            widget.dseId,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: textPrimaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Branch',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            widget.branchName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: textPrimaryColor,
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

                            const SizedBox(height: 16),

                            // Outlet PJP Section
                            _buildDataCard(
                              title: 'Outlet PJP',
                              icon: Icons.store,
                              color: const Color(0xFF42A5F5), // Blue
                              data: [
                                {
                                  'label': 'DTD',
                                  'value': dailyData['outlet_pjp_hari_ini']
                                          ?.toString() ??
                                      'Loading...',
                                  'isOutlet': true,
                                  'status': 'today',
                                },
                                {
                                  'label': 'LTD',
                                  'value': dailyData['outlet_pjp_kemarin']
                                          ?.toString() ??
                                      'Loading...',
                                  'isOutlet': true,
                                  'status': 'yesterday',
                                },
                                {
                                  'label': 'GROWTH',
                                  'value':
                                      '${dailyData['g_outlet']?.toString() ?? 'N/A'}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      dailyData['g_outlet']?.toString(),
                                },
                                {
                                  'label': 'Last Update',
                                  'value': dailyData['mtd_dt']?.toString() ??
                                      'Loading...',
                                },
                              ],
                            ),

                            // RGU GA Section
                            _buildDataCard(
                              title: 'RGU GA',
                              icon: Icons.assessment,
                              color: const Color(0xFFAB47BC), // Purple
                              data: [
                                {
                                  'label': 'DTD',
                                  'value':
                                      dailyData['rgu_ga_dtd']?.toString() ??
                                          'Loading...',
                                },
                                {
                                  'label': 'LTD',
                                  'value':
                                      dailyData['rgu_ga_ltd']?.toString() ??
                                          'Loading...',
                                },
                                {
                                  'label': 'GROWTH',
                                  'value':
                                      '${dailyData['g_rgu_ga']?.toString() ?? 'N/A'}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      dailyData['g_rgu_ga']?.toString(),
                                },
                              ],
                            ),

                            // SALDO NET Section
                            _buildDataCard(
                              title: 'SALDO NET',
                              icon: Icons.account_balance_wallet,
                              color: const Color(0xFF66BB6A), // Green
                              data: [
                                {
                                  'label': 'DTD',
                                  'value': dailyData['sec_saldo_net_dtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'LTD',
                                  'value': dailyData['sec_saldo_net_ltd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'GROWTH',
                                  'value':
                                      '${dailyData['g_sec_saldo_net']?.toString() ?? 'N/A'}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      dailyData['g_sec_saldo_net']?.toString(),
                                },
                              ],
                            ),

                            // SUPPLY SP Section
                            _buildDataCard(
                              title: 'SUPPLY SP',
                              icon: Icons.sim_card,
                              color: const Color(0xFFFFA726), // Orange
                              data: [
                                {
                                  'label': 'DTD NET',
                                  'value': dailyData['supply_sp_net_dtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'LTD NET',
                                  'value': dailyData['supply_sp_net_ltd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'GROWTH NET',
                                  'value':
                                      '${dailyData['g_supply_sp_net']?.toString() ?? 'N/A'}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      dailyData['g_supply_sp_net']?.toString(),
                                },
                                {
                                  'label': 'DTD HIT',
                                  'value': dailyData['supply_sp_hits_dtd']
                                          ?.toString() ??
                                      'Loading...'
                                },
                                {
                                  'label': 'LTD HIT',
                                  'value': dailyData['supply_sp_hits_ltd']
                                          ?.toString() ??
                                      'Loading...'
                                },
                                {
                                  'label': 'GROWTH HIT',
                                  'value':
                                      '${dailyData['g_supply_sp_hits']?.toString() ?? 'N/A'}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      dailyData['g_supply_sp_hits']?.toString(),
                                },
                              ],
                            ),

                            // SUPPLY VOU Section
                            _buildDataCard(
                              title: 'SUPPLY VOU',
                              icon: Icons.receipt,
                              color: const Color(0xFF26A69A), // Teal
                              data: [
                                {
                                  'label': 'DTD NET',
                                  'value': dailyData['supply_vo_net_dtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'LTD NET',
                                  'value': dailyData['supply_vo_net_ltd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'GROWTH NET',
                                  'value':
                                      '${dailyData['g_supply_vo_net']?.toString() ?? 'N/A'}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      dailyData['g_supply_vo_net']?.toString(),
                                },
                                {
                                  'label': 'DTD HIT',
                                  'value': dailyData['supply_vo_hits_dtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'LTD HIT',
                                  'value': dailyData['supply_vo_hits_ltd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'GROWTH HIT',
                                  'value':
                                      '${dailyData['g_supply_vo_hits']?.toString() ?? 'N/A'}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      dailyData['g_supply_vo_hits']?.toString(),
                                },
                              ],
                            ),

                            // REBUY NET Section
                            _buildDataCard(
                              title: 'REBUY NET',
                              icon: Icons.repeat,
                              color: const Color(0xFF5C6BC0), // Indigo
                              data: [
                                {
                                  'label': 'DTD',
                                  'value': dailyData['supply_rebuy_net_dtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'LTD',
                                  'value': dailyData['supply_rebuy_net_ltd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'GROWTH',
                                  'value':
                                      '${dailyData['g_supply_rebuy_net']?.toString() ?? 'N/A'}%',
                                  'isGrowth': true,
                                  'growthValue': dailyData['g_supply_rebuy_net']
                                      ?.toString(),
                                },
                              ],
                            ),

                            // Product Information Section
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Section header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEC407A)
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.shopping_bag,
                                            color: Color(0xFFEC407A),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Product Information',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'Last Update: ${productList.isNotEmpty ? productList[0]['dt_id'] : 'Loading...'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: textSecondaryColor,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Product table with improved styling
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Table(
                                          border: TableBorder.symmetric(
                                            inside: BorderSide(
                                              width: 1,
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          columnWidths: const {
                                            0: FlexColumnWidth(1.5),
                                            1: FlexColumnWidth(1.0),
                                          },
                                          children: [
                                            // Table header
                                            TableRow(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEC407A)
                                                    .withOpacity(0.1),
                                              ),
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(12.0),
                                                  child: Text(
                                                    'Product Name',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Color(0xFFEC407A),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(12.0),
                                                  child: Text(
                                                    'Total Hits',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Color(0xFFEC407A),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Data rows
                                            ...productList
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              int idx = entry.key;
                                              var product = entry.value;
                                              return TableRow(
                                                decoration: BoxDecoration(
                                                  color: idx.isEven
                                                      ? Colors.white
                                                      : const Color(0xFFFAFAFA),
                                                ),
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12.0),
                                                    child: Text(
                                                      product['product_name'] ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: textPrimaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12.0),
                                                    child: Text(
                                                      product['total_hits']
                                                              ?.toString() ??
                                                          '0',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: textPrimaryColor,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 70), // Space for bottom nav
                          ],
                        ),
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

  // Helper method to build data cards with consistent styling
  Widget _buildDataCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> data,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Data table with improved styling
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Table(
                  border: TableBorder.symmetric(
                    inside: BorderSide(
                      width: 1,
                      color: Colors.grey.shade200,
                    ),
                  ),
                  children: [
                    // Data rows
                    ...data.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var item = entry.value;
                      bool isGrowth = item['isGrowth'] == true;
                      bool isOutlet = item['isOutlet'] == true;

                      // Determine color for growth values
                      Color valueColor = const Color(0xFF2D3142);
                      if (isGrowth) {
                        try {
                          String growthStr =
                              item['growthValue']?.toString() ?? '0';
                          double growth = double.parse(growthStr);
                          if (growth > 0) {
                            valueColor =
                                const Color(0xFF66BB6A); // Green for positive
                          } else if (growth < 0) {
                            valueColor =
                                const Color(0xFFEF5350); // Red for negative
                          }
                        } catch (e) {
                          valueColor = const Color(0xFF2D3142);
                        }
                      } else if (isOutlet) {
                        valueColor = const Color(
                            0xFF42A5F5); // Blue for clickable outlets
                      }

                      return TableRow(
                        decoration: BoxDecoration(
                          color: idx.isEven
                              ? Colors.white
                              : const Color(0xFFFAFAFA),
                        ),
                        children: [
                          // Label column
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              item['label'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                          ),
                          // Value column
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: isOutlet
                                ? InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailDseOutlet(
                                            selectedRegion:
                                                widget.selectedRegion,
                                            selectedArea: widget.selectedArea,
                                            selectedBranch:
                                                widget.selectedBranch,
                                            dseId: widget.dseId,
                                            status: item['status'],
                                            title:
                                                '${widget.dseId} - ${item['label']}',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      item['value'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: valueColor,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  )
                                : Text(
                                    item['value'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: valueColor,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                          ),
                        ],
                      );
                    }),
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
