import 'package:elang_dashboard_new_ui/detail_outlet_valid.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DetailSite extends StatefulWidget {
  final String siteId;
  final String brand;

  const DetailSite({
    super.key,
    required this.siteId,
    required this.brand,
  });

  @override
  State<DetailSite> createState() => _DetailSitelateState();
}

class _DetailSitelateState extends State<DetailSite> {
  Map<String, dynamic>? _siteDetails;
  Map<String, dynamic>? _gaDetails;
  Map<String, dynamic>? _revDetails;
  Map<String, dynamic>? _rguDetails;
  Map<String, dynamic>? _vlrDetails;

  String _formatNumber(int? number) {
    if (number == null) return 'Loading...';
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  var baseURL = dotenv.env['baseURL'];

  Future<void> _fetchDataSortSiteDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/sites/${widget.siteId}/detail?brand=${widget.brand}',
    );

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _siteDetails = data['data'];
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchDataSiteGADetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/sites/${widget.siteId}/detail/ga?brand=${widget.brand}',
    );

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _gaDetails = data['data'];
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchDataSiteRevDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/sites/${widget.siteId}/detail/revenue?brand=${widget.brand}',
    );

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _revDetails = data['data'];
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchDataSiteRGUDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/sites/${widget.siteId}/detail/rgu?brand=${widget.brand}',
    );

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _rguDetails = data['data'];
        });
      } else {
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (error) {
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _fetchDataSiteVLRDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/sites/${widget.siteId}/detail/vlr?brand=${widget.brand}',
    );

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _vlrDetails = data['data'];
        });
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    _fetchDataSortSiteDetail(token);
    _fetchDataSiteGADetail(token);
    _fetchDataSiteRevDetail(token);
    _fetchDataSiteRGUDetail(token);
    _fetchDataSiteVLRDetail(token);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;

    // Define color scheme to match DetailOutlet
    const primaryColor = Color(0xFF6A62B7); // Soft purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray

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
                          'DETAIL SITE',
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Site ID & Brand Name
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget
                                                    .siteId, // siteId from widget
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: textPrimaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _siteDetails?['brand']
                                                        ?.toString() ??
                                                    widget
                                                        .brand, // brand from API or widget
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: textPrimaryColor,
                                                  fontWeight: FontWeight.bold,
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
                            ),

                            const SizedBox(height: 16),

                            // Location Card with Map
                            Card(
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
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF42A5F5)
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.location_on,
                                            color: Color(0xFF42A5F5),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Location',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Map container
                                    Container(
                                      height: 180,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _siteDetails?['lat'] != null &&
                                                _siteDetails?['long'] != null
                                            ? GoogleMap(
                                                initialCameraPosition:
                                                    CameraPosition(
                                                  target: LatLng(
                                                    double.tryParse(
                                                            _siteDetails!['lat']
                                                                .toString()) ??
                                                        0.0,
                                                    double.tryParse(
                                                            _siteDetails![
                                                                    'long']
                                                                .toString()) ??
                                                        0.0,
                                                  ),
                                                  zoom: 15,
                                                ),
                                                markers: {
                                                  Marker(
                                                    markerId: const MarkerId(
                                                        'site_location'),
                                                    position: LatLng(
                                                      double.tryParse(
                                                              _siteDetails![
                                                                      'lat']
                                                                  .toString()) ??
                                                          0.0,
                                                      double.tryParse(
                                                              _siteDetails![
                                                                      'long']
                                                                  .toString()) ??
                                                          0.0,
                                                    ),
                                                    icon: BitmapDescriptor
                                                        .defaultMarkerWithHue(
                                                      BitmapDescriptor.hueRed,
                                                    ),
                                                  ),
                                                },
                                                myLocationEnabled: false,
                                                zoomControlsEnabled: true,
                                                mapType: MapType.normal,
                                              )
                                            : const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: primaryColor,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Site Detail Section
                            _buildInfoSection(
                              title: 'Site Detail',
                              icon: Icons.business,
                              color: const Color(0xFF66BB6A),
                              data: [
                                {
                                  'label': 'Site ID',
                                  'value': widget.siteId,
                                },
                                {
                                  'label': 'Site Name',
                                  'value':
                                      _siteDetails?['site_name']?.toString() ??
                                          'Loading...',
                                },
                                {
                                  'label': 'PT Name',
                                  'value':
                                      _siteDetails?['pt_name']?.toString() ??
                                          'Loading...',
                                },
                                {
                                  'label': 'Outlet Valid',
                                  'value': _siteDetails?['outlet_valid']
                                          ?.toString() ??
                                      'Loading...',
                                  'isLink': true,
                                  'onTap': () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailOutletValid(
                                          siteId: widget.siteId,
                                          brand: widget.brand,
                                        ),
                                      ),
                                    );
                                  },
                                },
                                {
                                  'label': 'Category',
                                  'value':
                                      _siteDetails?['category']?.toString() ??
                                          'Loading...',
                                },
                                {
                                  'label': 'Brand',
                                  'value': _siteDetails?['brand']?.toString() ??
                                      'Loading...',
                                },
                                {
                                  'label': 'Last Update',
                                  'value':
                                      _siteDetails?['asof_dt']?.toString() ??
                                          'Loading...',
                                },
                              ],
                            ),

                            const SizedBox(height: 16),

                            // GA Section
                            _buildInfoSection(
                              title: 'Site GA',
                              icon: Icons.analytics,
                              color: const Color(0xFFAB47BC),
                              data: [
                                {
                                  'label': 'GA LMTD',
                                  'value': _formatNumber(int.tryParse(
                                      _gaDetails?['ga_lmtd']?.toString() ??
                                          '')),
                                },
                                {
                                  'label': 'GA MTD',
                                  'value': _formatNumber(int.tryParse(
                                      _gaDetails?['ga_mtd']?.toString() ?? '')),
                                },
                                {
                                  'label': 'GROWTH',
                                  'value':
                                      '${(double.tryParse(_gaDetails?['growth']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(2)}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      _gaDetails?['growth']?.toString() ?? '0',
                                },
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Revenue Section
                            _buildInfoSection(
                              title: 'Site Revenue',
                              icon: Icons.monetization_on,
                              color: const Color(0xFF42A5F5),
                              data: [
                                {
                                  'label': 'REV LMTD',
                                  'value': _formatNumber(int.tryParse(
                                      _revDetails?['rev_lmtd']?.toString() ??
                                          '')),
                                },
                                {
                                  'label': 'REV MTD',
                                  'value': _formatNumber(int.tryParse(
                                      _revDetails?['rev_mtd']?.toString() ??
                                          '')),
                                },
                                {
                                  'label': 'GROWTH',
                                  'value':
                                      '${(double.tryParse(_revDetails?['growth']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(2)}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      _revDetails?['growth']?.toString() ?? '0',
                                },
                              ],
                            ),

                            const SizedBox(height: 16),

                            // RGU Section
                            _buildInfoSection(
                              title: 'Site RGU 90',
                              icon: Icons.people_alt,
                              color: const Color(0xFFFFA726),
                              data: [
                                {
                                  'label': 'RGU 90 LMTD',
                                  'value': _formatNumber(int.tryParse(
                                      _rguDetails?['rgu90_lmtd']?.toString() ??
                                          '')),
                                },
                                {
                                  'label': 'RGU 90 MTD',
                                  'value': _formatNumber(int.tryParse(
                                      _rguDetails?['rgu90_mtd']?.toString() ??
                                          '')),
                                },
                                {
                                  'label': 'GROWTH',
                                  'value':
                                      '${(double.tryParse(_rguDetails?['growth']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(2)}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      _rguDetails?['growth']?.toString() ?? '0',
                                },
                              ],
                            ),

                            const SizedBox(height: 16),

                            // VLR Section
                            _buildInfoSection(
                              title: 'Site VLR',
                              icon: Icons.signal_cellular_alt,
                              color: const Color(0xFFEF5350),
                              data: [
                                {
                                  'label': 'VLR LMTD',
                                  'value': _formatNumber(int.tryParse(
                                      _vlrDetails?['vlr_lmtd']?.toString() ??
                                          '')),
                                },
                                {
                                  'label': 'VLR MTD',
                                  'value': _formatNumber(int.tryParse(
                                      _vlrDetails?['vlr_mtd']?.toString() ??
                                          '')),
                                },
                                {
                                  'label': 'GROWTH',
                                  'value':
                                      '${(double.tryParse(_vlrDetails?['growth']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(2)}%',
                                  'isGrowth': true,
                                  'growthValue':
                                      _vlrDetails?['growth']?.toString() ?? '0',
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

  // Helper method to build data sections with consistent styling
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
                      bool isLink = item['isLink'] == true;
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

                      if (isLink) {
                        valueColor = const Color(0xFF42A5F5); // Blue for links
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
                            child: isLink
                                ? GestureDetector(
                                    onTap: item['onTap'],
                                    child: Text(
                                      item['value'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: valueColor,
                                        decoration: TextDecoration.underline,
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
