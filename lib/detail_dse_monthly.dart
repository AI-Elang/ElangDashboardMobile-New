import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DetailDseMonthly extends StatefulWidget {
  final String dseId;
  final String branchName;

  const DetailDseMonthly({
    super.key,
    required this.dseId,
    required this.branchName,
  });

  @override
  State<DetailDseMonthly> createState() => _DetailDseMonthlyState();
}

class _DetailDseMonthlyState extends State<DetailDseMonthly> {
  Map<String, dynamic>? pjpOutletData;
  Map<String, dynamic>? sellinVoucherData;
  Map<String, dynamic>? sellinMoboData;
  Map<String, dynamic>? sellinSPData;

  var baseURL = dotenv.env['baseURL'];

  Future<void> _fetchData(String? token) async {
    final dseId = widget.dseId;
    final url = Uri.parse(
      '$baseURL/api/v1/dse/pjp-outlet/$dseId',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          setState(() {
            pjpOutletData = data['data'][0];
          });
        } else {
          // Handle case where data is empty or not in expected format
          setState(() {
            pjpOutletData = {}; // Or some other default error state
          });
        }
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchSellinVoucherData(String? token) async {
    final dseId = widget.dseId;
    final url = Uri.parse(
      '$baseURL/api/v1/dse/pjp-sellin-voucher/$dseId',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          setState(() {
            sellinVoucherData = data['data'][0];
          });
        } else {
          setState(() {
            sellinVoucherData = {};
          });
        }
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchSellinMoboData(String? token) async {
    final dseId = widget.dseId;
    final url = Uri.parse(
      '$baseURL/api/v1/dse/pjp-sellin-mobo/$dseId',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          setState(() {
            sellinMoboData = data['data'][0];
          });
        } else {
          setState(() {
            sellinMoboData = {};
          });
        }
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchSellinSPData(String? token) async {
    final dseId = widget.dseId;
    final url = Uri.parse(
      '$baseURL/api/v1/dse/pjp-sellin-sp/$dseId',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          setState(() {
            sellinSPData = data['data'][0];
          });
        } else {
          setState(() {
            sellinSPData = {};
          });
        }
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    _fetchData(token);
    _fetchSellinVoucherData(token);
    _fetchSellinMoboData(token);
    _fetchSellinSPData(token);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;

    // Define color scheme to match homepage
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
                // Header with gradient like in homepage
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
                          'DSE MONTHLY REPORT',
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
                            _buildInfoSection(
                              title: 'Outlet PJP',
                              icon: Icons.store,
                              color: const Color(0xFF42A5F5),
                              data: [
                                {
                                  'label': 'Jumlah Data',
                                  'value': pjpOutletData?['outlet_pjp']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'Last Update',
                                  'value':
                                      pjpOutletData?['mtd_dt']?.toString() ??
                                          'Loading...',
                                },
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Sellin Voucher Section
                            _buildInfoSection(
                              title: 'Sellin Voucher',
                              icon: Icons.receipt,
                              color: const Color(0xFFAB47BC),
                              data: [
                                {
                                  'label': 'Vou Net LMTD',
                                  'value': sellinVoucherData?['vo_net_lmtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'Vou Net MTD',
                                  'value': sellinVoucherData?['vo_net_mtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'Growth Vou Net',
                                  'value':
                                      sellinVoucherData?['g_vo_net'] != null
                                          ? '${sellinVoucherData?['g_vo_net']}%'
                                          : 'Loading...',
                                },
                                {
                                  'label': 'Vou Hits LMTD',
                                  'value': sellinVoucherData?['vo_hits_lmtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'Vou Hits MTD',
                                  'value': sellinVoucherData?['vo_hits_mtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'Growth Vou Hits',
                                  'value': sellinVoucherData?['g_vo_hits'] !=
                                          null
                                      ? '${sellinVoucherData?['g_vo_hits']}%'
                                      : 'Loading...',
                                  'isGrowth': true,
                                  'growthValue': sellinVoucherData?['g_vo_hits']
                                      ?.toString()
                                },
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Sellin Mobo Section
                            _buildInfoSection(
                              title: 'Sellin Mobo',
                              icon: Icons.smartphone,
                              color: const Color(0xFF66BB6A),
                              data: [
                                {
                                  'label': 'Demand LMTD',
                                  'value': sellinMoboData?['sellin_mobo_lmtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'Demand MTD',
                                  'value': sellinMoboData?['sellin_mobo_mtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'Growth Demand',
                                  'value': sellinMoboData?['g_mobo'] != null
                                      ? '${sellinMoboData?['g_mobo']}%'
                                      : 'Loading...',
                                  'isGrowth': true,
                                  'growthValue':
                                      sellinMoboData?['g_mobo']?.toString()
                                },
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Sellin SP Section
                            _buildInfoSection(
                              title: 'Sellin SP',
                              icon: Icons.sim_card,
                              color: const Color(0xFFFFA726),
                              data: [
                                {
                                  'label': 'SP Net LMTD',
                                  'value': sellinSPData?['sp_net_lmtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'SP Net MTD',
                                  'value':
                                      sellinSPData?['sp_net_mtd']?.toString() ??
                                          'Loading...',
                                },
                                {
                                  'label': 'Growth SP Net',
                                  'value': sellinSPData?['g_sp_net'] != null
                                      ? '${sellinSPData?['g_sp_net']}%'
                                      : 'Loading...',
                                  'isGrowth': true,
                                  'growthValue':
                                      sellinSPData?['g_sp_net']?.toString()
                                },
                                {
                                  'label': 'SP Hits LMTD',
                                  'value': sellinSPData?['sp_hits_lmtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'SP Hits MTD',
                                  'value': sellinSPData?['sp_hits_mtd']
                                          ?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'Growth SP Hits',
                                  'value': sellinSPData?['g_sp_hits'] != null
                                      ? '${sellinSPData?['g_sp_hits']}%'
                                      : 'Loading...',
                                  'isGrowth': true,
                                  'growthValue':
                                      sellinSPData?['g_sp_hits']?.toString()
                                },
                              ],
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

  // Method to build consistent section cards for different data types
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> data,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    // Table header
                    TableRow(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Metric',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: color.withOpacity(0.8),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Value',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: color.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),

                    // Data rows
                    ...data.map((item) {
                      bool isGrowth = item['isGrowth'] == true;
                      String growthValue =
                          item['growthValue']?.toString() ?? '0';
                      Color valueColor = const Color(0xFF2D3142);

                      // Set color for growth values
                      if (isGrowth) {
                        try {
                          double growth = double.parse(growthValue);
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
                      }

                      return TableRow(
                        decoration: BoxDecoration(
                          color: data.indexOf(item).isEven
                              ? Colors.white
                              : const Color(0xFFFAFAFA),
                        ),
                        children: [
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
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
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
