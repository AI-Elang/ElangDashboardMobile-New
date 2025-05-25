import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/dashboard_card_mitra.dart';
import 'package:elang_dashboard_new_ui/checkin_mitra.dart';
import 'package:elang_dashboard_new_ui/widgets/reusable_data_table_section.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:convert';

class DetailMitra extends StatefulWidget {
  final String partnerId;
  final String category;
  final String mc;

  const DetailMitra({
    super.key,
    required this.partnerId,
    required this.category,
    required this.mc,
  });

  @override
  State<DetailMitra> createState() => _DetSitelateState();
}

class _DetSitelateState extends State<DetailMitra>
    with TickerProviderStateMixin {
  Map<String, dynamic> mitraDetailData = {};
  Map<String, dynamic> sellinVoucherData = {};
  Map<String, dynamic> sellinMoboData = {};
  Map<String, dynamic> sellinSPData = {};

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _partnerLocation;

  List<Map<String, dynamic>> dashboardData = []; // State for dashboard data
  List<Map<String, dynamic>> mitraProfileData =
      []; // New state for list of profiles

  String _formatNumberDynamic(dynamic number) {
    // Changed to dynamic to be more generic
    if (number == null) return 'N/A'; // Handle null better for general use
    if (number is String) {
      // Attempt to parse if it's a string representation of a number
      final parsedNumber = int.tryParse(number);
      if (parsedNumber != null) {
        final formatter = NumberFormat('#,###');
        return formatter.format(parsedNumber);
      }
      return number; // Return as is if not a parsable number string
    }
    if (number is int || number is double) {
      final formatter = NumberFormat('#,###');
      return formatter.format(number);
    }
    return number.toString(); // Fallback for other types
  }

  var baseURL = dotenv.env['baseURL'];

  Future<void> _fetchDataMitraDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/mitra/detail?partner_id=${widget.partnerId}&category=${widget.category}&mc=${widget.mc}',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          // Store the whole data map
          mitraDetailData = data as Map<String, dynamic>;

          // Handle map update
          final latString = mitraDetailData['lat']?.toString();
          final longString = mitraDetailData['long']?.toString();

          if (latString != null && longString != null) {
            final double? lat = double.tryParse(latString);
            final double? long = double.tryParse(longString);

            if (lat != null && long != null) {
              _partnerLocation = LatLng(lat, long);
              _markers.clear();
              _markers.add(
                Marker(
                  markerId: const MarkerId('partnerLocation'),
                  position: _partnerLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(
                    title: mitraDetailData['partner_name']?.toString() ??
                        'Partner Location',
                    snippet: 'Lat: $lat, Long: $long',
                  ),
                ),
              );

              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_partnerLocation!, 15),
                );
              }
            }
          }
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchDataMitraSellinVoucherDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/mitra/detail/sellin-voucher?partner_id=${widget.partnerId}&category=${widget.category}&mc=${widget.mc}',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          sellinVoucherData = data as Map<String, dynamic>;
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchDataMitraSellinMoboDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/mitra/detail/sellin-mobo?partner_id=${widget.partnerId}&category=${widget.category}&mc=${widget.mc}',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          sellinMoboData = data as Map<String, dynamic>;
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchDataMitraSellinSPDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/mitra/detail/sellin-sp?partner_id=${widget.partnerId}&category=${widget.category}&mc=${widget.mc}',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          sellinSPData = data as Map<String, dynamic>;
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchDataMitraDashboard(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/mitra/detail/dashboard?partner_id=${widget.partnerId}&category=${widget.category}&mc=${widget.mc}',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        // Ensure data is a List<dynamic> and cast items to Map<String, dynamic>
        if (data is List) {
          setState(() {
            dashboardData = List<Map<String, dynamic>>.from(
                data.map((item) => item as Map<String, dynamic>));
          });
          // Optional: Print data to verify
          // print('Dashboard Data: $dashboardData');
        } else {
          throw Exception('Invalid data format received from dashboard API');
        }
      } else {
        // Use ScaffoldMessenger for SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to load dashboard data: ${response.statusCode}')),
          );
        }
      }
    } catch (error) {
      // Use ScaffoldMessenger for SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching dashboard data: $error')),
        );
      }
    }
  }

  Future<void> _fetchDataMitraProfile(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/mitra/detail/profile?partner_id=${widget.partnerId}&category=${widget.category}&mc=${widget.mc}',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] is List) {
          final profiles = responseData['data'] as List;
          setState(() {
            mitraProfileData = List<Map<String, dynamic>>.from(
                profiles.map((item) => item as Map<String, dynamic>));
          });
        } else {
          setState(() {
            mitraProfileData = [];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Profile data is not in expected list format.')),
            );
          }
        }
      } else {
        setState(() {
          mitraProfileData = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load program data: ${response.body}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      setState(() {
        mitraProfileData = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Error fetching program data',
          ),
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    _fetchDataMitraDetail(token).then((_) {
      // Ensure map updates after initial data fetch if controller is ready
      if (_partnerLocation != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_partnerLocation!, 15),
        );
      }
    });
    _fetchDataMitraSellinVoucherDetail(token);
    _fetchDataMitraSellinMoboDetail(token);
    _fetchDataMitraSellinSPDetail(token);
    _fetchDataMitraDashboard(token);
    _fetchDataMitraProfile(token);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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

    bool isMitraProfileLoading =
        mitraDetailData.isEmpty; // Basic loading check, can be refined

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
                          'DETAIL MITRA',
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
                            // Mitra Info Card
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
                                    // Mitra Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Partner Name',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            mitraDetailData['partner_name']
                                                    ?.toString() ??
                                                'Loading...',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: textPrimaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'MC',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            textSecondaryColor,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      mitraDetailData['mc']
                                                              ?.toString() ??
                                                          'Loading...',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: textPrimaryColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Brand',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            textSecondaryColor,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      mitraDetailData['brand']
                                                              ?.toString() ??
                                                          'Loading...',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: textPrimaryColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Location Information Section
                            _buildLocationSection(),

                            const SizedBox(height: 16),

                            // --- INPUT CHECKIN BUTTON ---
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: SizedBox(
                                width:
                                    double.infinity, // Make button full width
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Use widget.partnerId as it\'s the definitive ID for this screen.
                                    // Use this.partnerName as it\'s the fetched name from the state.
                                    if (mitraDetailData['partner_name'] !=
                                        null) {
                                      // Check if the fetched partnerName is available.
                                      // widget.partnerId is guaranteed by the constructor.
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CheckinMitra(
                                            partnerId: widget
                                                .partnerId, // Use the ID passed to this DetailMitra widget
                                            partnerName: mitraDetailData[
                                                    'partner_name']!
                                                .toString(), // Use the fetched name from state
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Partner name is still loading or unavailable. Please wait.')), // Clarified message
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10), // Reduced padding
                                    textStyle: const TextStyle(
                                      fontSize: 14, // Reduced font size
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      // Optional: to match card style
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Input Checkin',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),

                            // --- DASHBOARD SECTION MOVED HERE ---
                            if (dashboardData.isNotEmpty)
                              _buildDashboardSection()
                            else if (dashboardData
                                .isEmpty) // Changed condition to explicitly check for empty
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),

                            const SizedBox(height: 16),

                            // --- MITRA PROFILE SECTION ---
                            IntrinsicHeight(
                              // Wrap ReusableDataTableSection with IntrinsicHeight
                              child: ReusableDataTableSection(
                                title: 'Mitra Profile',
                                icon: Icons.person_pin_outlined,
                                sectionColor: primaryColor,
                                textPrimaryColor: textPrimaryColor,
                                cardColor: cardColor,
                                data: mitraProfileData,
                                fixedColumn: const {
                                  'key': 'KPI_NAME',
                                  'header': 'KPI NAME',
                                  'width': 120.0
                                },
                                scrollableColumns: const [
                                  {'key': 'target', 'header': 'TARGET'},
                                  {'key': 'poin', 'header': 'POINT'},
                                  {'key': 'mtd', 'header': 'MTD'},
                                  {'key': 'achv', 'header': 'ACHV'},
                                ],
                                isLoading:
                                    isMitraProfileLoading, // Pass a loading state
                                emptyStateTitle: 'No Profile Data',
                                emptyStateSubtitle:
                                    'Mitra profile information is not available.',
                                numberFormatter:
                                    _formatNumberDynamic, // Pass the formatter
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Mitra Detail Section
                            _buildInfoSection(
                              title: 'Mitra Detail',
                              icon: Icons.business,
                              color: const Color(0xFF42A5F5),
                              data: [
                                {
                                  'label': 'Category',
                                  'value':
                                      mitraDetailData['category']?.toString() ??
                                          'Loading...'
                                },
                                {
                                  'label': 'Outlet PJP',
                                  'value': _formatNumberDynamic(
                                      mitraDetailData['outlet_pjp']),
                                },
                                {
                                  'label': '#Site',
                                  'value': _formatNumberDynamic(
                                      mitraDetailData['site_count']),
                                },
                                {
                                  'label': 'Last Update',
                                  'value':
                                      mitraDetailData['mtd_dt']?.toString() ??
                                          'Loading...'
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
                                  'value': _formatNumberDynamic(
                                      sellinVoucherData['vo_net_lmtd'])
                                },
                                {
                                  'label': 'Vou Net MTD',
                                  'value': _formatNumberDynamic(
                                      sellinVoucherData['vo_net_mtd'])
                                },
                                {
                                  'label': 'Growth Vou Net',
                                  'value': sellinVoucherData['g_vo_net'] != null
                                      ? '${sellinVoucherData['g_vo_net']?.toString()}%'
                                      : 'Loading...',
                                  'isGrowth': true,
                                  'growthValue':
                                      sellinVoucherData['g_vo_net']?.toString()
                                },
                                {
                                  'label': 'Vou Hits LMTD',
                                  'value': _formatNumberDynamic(
                                      sellinVoucherData['vo_hits_lmtd'])
                                },
                                {
                                  'label': 'Vou Hits MTD',
                                  'value': _formatNumberDynamic(
                                      sellinVoucherData['vo_hits_mtd'])
                                },
                                {
                                  'label': 'Growth Vou Hits',
                                  'value': sellinVoucherData['g_vo_hits'] !=
                                          null
                                      ? '${sellinVoucherData['g_vo_hits']?.toString()}%'
                                      : 'Loading...',
                                  'isGrowth': true,
                                  'growthValue':
                                      sellinVoucherData['g_vo_hits']?.toString()
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
                                  'label': 'Mobo LMTD',
                                  'value': _formatNumberDynamic(
                                      sellinMoboData['sellin_mobo_lmtd'])
                                },
                                {
                                  'label': 'Mobo MTD',
                                  'value': _formatNumberDynamic(
                                      sellinMoboData['sellin_mobo_mtd'])
                                },
                                {
                                  'label': 'Growth Mobo',
                                  'value': sellinMoboData['g_mobo'] != null
                                      ? '${sellinMoboData['g_mobo']?.toString()}%'
                                      : 'Loading...',
                                  'isGrowth': true,
                                  'growthValue':
                                      sellinMoboData['g_mobo']?.toString()
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
                                  'value': _formatNumberDynamic(
                                      sellinSPData['sp_net_lmtd'])
                                },
                                {
                                  'label': 'SP Net MTD',
                                  'value': _formatNumberDynamic(
                                      sellinSPData['sp_net_mtd'])
                                },
                                {
                                  'label': 'Growth SP Net',
                                  'value': sellinSPData['g_sp_net'] != null
                                      ? '${sellinSPData['g_sp_net']?.toString()}%'
                                      : 'Loading...',
                                  'isGrowth': true,
                                  'growthValue':
                                      sellinSPData['g_sp_net']?.toString()
                                },
                                {
                                  'label': 'SP Hits LMTD',
                                  'value': _formatNumberDynamic(
                                      sellinSPData['sp_hits_lmtd'])
                                },
                                {
                                  'label': 'SP Hits MTD',
                                  'value': _formatNumberDynamic(
                                      sellinSPData['sp_hits_mtd'])
                                },
                                {
                                  'label': 'Growth SP Hits',
                                  'value': sellinSPData['g_sp_hits'] != null
                                      ? '${sellinSPData['g_sp_hits']?.toString()}%'
                                      : 'Loading...',
                                  'isGrowth': true,
                                  'growthValue':
                                      sellinSPData['g_sp_hits']?.toString()
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

  Widget _buildLocationSection() {
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const cardColor = Colors.white;
    const locationIconColor = Color(0xFFD32F2F); // A shade of red

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: locationIconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: locationIconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Location Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 250, // Adjust height as needed
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _partnerLocation == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Loading map...'),
                          ],
                        ),
                      )
                    : GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: _partnerLocation!,
                          zoom: 15,
                        ),
                        markers: _markers,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          // Ensure camera moves to location if map created after location is set
                          if (_partnerLocation != null) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(_partnerLocation!, 15),
                            );
                          }
                        },
                        gestureRecognizers: const {}, // Add if needed for specific gestures
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build the dashboard row
  Widget _buildDashboardSection() {
    // Find KPI and COMPLIANCE data, handle cases where they might be missing
    final kpiData = dashboardData.firstWhere(
        (item) => item['name'] == 'KPI' && item['is_active'] == true,
        orElse: () => <String, dynamic>{}); // Return empty map if not found
    final complianceData = dashboardData.firstWhere(
        (item) => item['name'] == 'COMPLIANCE' && item['is_active'] == true,
        orElse: () => <String, dynamic>{}); // Return empty map if not found

    // Create card widgets if data is available
    final Widget? kpiCardWidget = kpiData.isNotEmpty
        ? DashboardCard(
            key: ValueKey(
                'kpi-${kpiData['id']}'), // Add key for state preservation
            title: 'SCORE KPI',
            value: (kpiData['value'] as num?)?.toDouble() ?? 0.0,
            lastUpdate: kpiData['last_update'] as String? ?? 'N/A',
            subparameters:
                List<Map<String, dynamic>>.from(kpiData['subparameters'] ?? []),
            color: Colors.pink, // Example color for KPI
            vsync: this, // Pass TickerProvider
          )
        : null;

    final Widget? complianceCardWidget = complianceData.isNotEmpty
        ? DashboardCard(
            key: ValueKey('compliance-${complianceData['id']}'), // Add key
            title: 'SCORE COMPLIANCE',
            value: (complianceData['value'] as num?)?.toDouble() ?? 0.0,
            lastUpdate: complianceData['last_update'] as String? ?? 'N/A',
            subparameters: List<Map<String, dynamic>>.from(
                complianceData['subparameters'] ?? []),
            color: Colors.deepPurple, // Example color for COMPLIANCE
            vsync: this, // Pass TickerProvider
          )
        : null;

    // Only build the column if at least one section has data
    if (kpiCardWidget == null && complianceCardWidget == null) {
      return const SizedBox.shrink(); // Return an empty widget if no data
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 8.0), // Add padding around the column
      child: Column(
        children: [
          // Conditionally build KPI Card
          if (kpiCardWidget != null) kpiCardWidget,

          // Add space between cards only if both are present
          if (kpiCardWidget != null && complianceCardWidget != null)
            const SizedBox(height: 10.0),

          // Conditionally build COMPLIANCE Card
          if (complianceCardWidget != null) complianceCardWidget,
        ],
      ),
    );
  }
}
