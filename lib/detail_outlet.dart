import 'package:elang_dashboard_new_ui/detail_site.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/checkin_outlet.dart';
import 'package:elang_dashboard_new_ui/outlet_history.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DetailOutlet extends StatefulWidget {
  final String qrCode;

  const DetailOutlet({super.key, required this.qrCode});

  @override
  State<DetailOutlet> createState() => _DetOutlateState();
}

class _DetOutlateState extends State<DetailOutlet> {
  Map<String, dynamic> outletAPIData = {};
  bool isLoading = true;

  // Helper methods for safe data access and type conversion
  dynamic _getData(String key, {dynamic defaultValue}) {
    List<String> parts = key.split('.');
    dynamic current = outletAPIData;
    for (String part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else if (current is List &&
          part.startsWith('[') &&
          part.endsWith(']')) {
        try {
          int index = int.parse(part.substring(1, part.length - 1));
          if (index < current.length) {
            current = current[index];
          } else {
            return defaultValue;
          }
        } catch (e) {
          return defaultValue;
        }
      } else {
        return defaultValue;
      }
    }
    return current ?? defaultValue;
  }

  String _asString(dynamic value, [String defaultValue = '']) {
    return value?.toString() ?? defaultValue;
  }

  int _asInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Handle strings like "200.0" before parsing to int
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) return doubleValue.toInt();
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  double _asDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  String _formatNumber(dynamic number) {
    if (number == null && isLoading) return 'Loading...';
    if (number == null) return '0'; // Default to '0' if null and not loading

    // Try to parse as double first to handle cases like "200.0" or 200.0
    double? numericValue;
    if (number is String) {
      numericValue = double.tryParse(number);
    } else if (number is num) {
      numericValue = number.toDouble();
    }

    if (numericValue == null) {
      return number.toString(); // Fallback if not parsable as number
    }

    final formatter = NumberFormat('#,###');
    // Format as int if it's a whole number, otherwise keep decimal for display if needed
    // For this specific _formatNumber, it seems to always format as integer.
    return formatter.format(numericValue.round());
  }

  var baseURL = dotenv.env['baseURL'];

  Future<void> _fetchDataOutletDetail(String? token) async {
    final qrcode = widget.qrCode;
    final url = Uri.parse(
      '$baseURL/api/v1/outlet/detail/$qrcode',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            outletAPIData['outlet_detail'] =
                data['data'] as Map<String, dynamic>? ?? {};
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to load outlet details: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error fetching outlet details'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _fetchDataGADetail(String? token) async {
    final url = Uri.parse('$baseURL/api/v1/outlet/detail/${widget.qrCode}/ga');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            outletAPIData['ga'] = data['data'] as Map<String, dynamic>? ?? {};
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to load GA data: ${response.statusCode}')));
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error fetching GA data')));
      }
    }
  }

  Future<void> _fetchDataSECDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/outlet/detail/${widget.qrCode}/sec',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            outletAPIData['sec'] = data['data'] as Map<String, dynamic>? ?? {};
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Failed to load SEC data: ${response.statusCode}')));
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error fetching SEC data')));
      }
    }
  }

  Future<void> _fetchDataSUPPYDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/outlet/detail/${widget.qrCode}/supply',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            outletAPIData['supply'] =
                data['data'] as Map<String, dynamic>? ?? {};
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Failed to load Supply data: ${response.statusCode}')));
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error fetching Supply data')));
      }
    }
  }

  Future<void> _fetchDataDEMANDDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/outlet/detail/${widget.qrCode}/demand',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            outletAPIData['demand'] =
                data['data'] as Map<String, dynamic>? ?? {};
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Failed to load Demand data: ${response.statusCode}')));
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error fetching Demand data')));
      }
    }
  }

  Future<void> _fetchDataPROGRAMDetail(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/outlet/detail/${widget.qrCode}/program',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            if (data['data'] is List && (data['data'] as List).isNotEmpty) {
              // Assuming we take the first program, as in the original code
              outletAPIData['program'] =
                  (data['data'] as List).first as Map<String, dynamic>? ?? {};
            } else {
              outletAPIData['program'] = {'kpi_name': 'Tidak ada data program'};
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            outletAPIData['program'] = {'kpi_name': 'Gagal memuat program'};
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to load program data: ${response.statusCode}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          outletAPIData['program'] = {'kpi_name': 'Error memuat program'};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error fetching program data'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      outletAPIData = {}; // Clear previous data on new fetch
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    // Fetch all data concurrently
    await Future.wait([
      _fetchDataOutletDetail(token),
      _fetchDataGADetail(token),
      _fetchDataSECDetail(token),
      _fetchDataSUPPYDetail(token),
      _fetchDataDEMANDDetail(token),
      _fetchDataPROGRAMDetail(token),
    ]);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method to build data sections with consistent styling (adapted from detail_site.dart)
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> data,
    bool isCustomTable = false, // Flag for custom table like PROGRAM
    Widget? customTableWidget, // Widget for custom table
  }) {
    const textPrimaryColor = Color(0xFF2D3142); // From detail_site.dart

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
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
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Conditional rendering for tables
            isCustomTable && customTableWidget != null
                ? customTableWidget // Render the custom table widget if provided
                : Container(
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
                          // Table header (optional, can be added if needed)
                          // TableRow( ... ),

                          // Data rows
                          ...data.map((item) {
                            bool isLink = item['isLink'] == true;
                            Color valueColor = textPrimaryColor;
                            Widget valueWidget;

                            if (item['value'] is Widget) {
                              valueWidget = item['value'];
                            } else {
                              valueWidget = Text(
                                item['value']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isLink ? Colors.blue : valueColor,
                                  decoration: isLink
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                ),
                                textAlign: TextAlign.right,
                              );
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
                                      color: textPrimaryColor,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: isLink && item['onTap'] != null
                                        ? GestureDetector(
                                            onTap: item['onTap'],
                                            child: valueWidget,
                                          )
                                        : valueWidget,
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

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;

    // Define color scheme to match DetailSite
    const primaryColor = Color(0xFF6A62B7); // Soft purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray

    // Retrieve data using helper methods
    String outletNameDisplay = _asString(_getData('outlet_detail.outlet_name'),
        isLoading ? 'Loading...' : 'N/A');
    String currentLatitude = _asString(_getData('outlet_detail.latitude'));
    String currentLongitude = _asString(_getData('outlet_detail.longitude'));
    String siteIdDisplay = _asString(
        _getData('outlet_detail.site_id'), isLoading ? 'Loading...' : 'N/A');
    String brandDisplay = _asString(
        _getData('outlet_detail.brand'), isLoading ? 'Loading...' : 'N/A');
    String partnerNameDisplay =
        _asString(_getData('outlet_detail.partner_name'), '-');

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header with gradient (similar to detail_site.dart)
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
                          'DETAIL OUTLET',
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
                            // Outlet Info Card (QR Code & Name)
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.qr_code,
                                            color: textPrimaryColor, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.qrCode.toString(),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: textPrimaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                outletNameDisplay,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimaryColor,
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
                                    Container(
                                      height: 200, // Keep height
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
                                        child: currentLatitude.isNotEmpty &&
                                                currentLongitude.isNotEmpty
                                            ? GoogleMap(
                                                initialCameraPosition:
                                                    CameraPosition(
                                                  target: LatLng(
                                                    _asDouble(
                                                        currentLatitude, 0.0),
                                                    _asDouble(
                                                        currentLongitude, 0.0),
                                                  ),
                                                  zoom: 15,
                                                ),
                                                markers: {
                                                  Marker(
                                                    markerId: const MarkerId(
                                                        'outlet_location'),
                                                    position: LatLng(
                                                      _asDouble(
                                                          currentLatitude, 0.0),
                                                      _asDouble(
                                                          currentLongitude,
                                                          0.0),
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
                            const SizedBox(height: 8),

                            // --- INPUT CHECKIN AND HISTORY CHECKIN BUTTONS ---
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.input,
                                          color: Colors.white, size: 18),
                                      label: const Text(
                                        'Input Checkin',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () {
                                        if (partnerNameDisplay != '-') {
                                          // Check against the default value if not loaded
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CheckinOutlet(
                                                outletId: widget.qrCode,
                                                outletName: outletNameDisplay,
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Partner name is still loading or unavailable. Please wait.')),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        textStyle: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 10), // Spacing between buttons
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.history,
                                          color: Colors.white, size: 18),
                                      label: const Text(
                                        'History Checkin',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () {
                                        if (widget.qrCode.isNotEmpty &&
                                            outletNameDisplay !=
                                                (isLoading
                                                    ? 'Loading...'
                                                    : 'N/A')) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OutletHistory(
                                                outletId: widget.qrCode,
                                                outletName: outletNameDisplay,
                                                selectedMonth: DateTime.now()
                                                    .month
                                                    .toString(),
                                                selectedYear: DateTime.now()
                                                    .year
                                                    .toString(),
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Outlet ID and name is still loading or unavailable. Please wait.')),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors
                                            .teal, // Different color for distinction
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        textStyle: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Outlet Detail Section
                            _buildInfoSection(
                              title: 'Outlet Detail',
                              icon: Icons.store,
                              color: const Color(0xFF66BB6A), // Example color
                              data: [
                                {
                                  'label': 'QR Code',
                                  'value': widget.qrCode,
                                },
                                {
                                  'label': 'Site ID',
                                  'value': siteIdDisplay,
                                  'isLink': siteIdDisplay !=
                                          (isLoading ? 'Loading...' : 'N/A') &&
                                      siteIdDisplay.isNotEmpty,
                                  'onTap': siteIdDisplay !=
                                              (isLoading
                                                  ? 'Loading...'
                                                  : 'N/A') &&
                                          siteIdDisplay.isNotEmpty
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DetailSite(
                                                siteId: siteIdDisplay,
                                                brand: brandDisplay,
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                },
                                {
                                  'label': 'Outlet Name',
                                  'value': outletNameDisplay,
                                },
                                {
                                  'label': 'Partner Name',
                                  'value': partnerNameDisplay,
                                },
                                {
                                  'label': 'Category',
                                  'value': _asString(
                                      _getData('outlet_detail.category'), '-'),
                                },
                                {
                                  'label': 'Brand',
                                  'value': brandDisplay,
                                },
                                {
                                  'label': 'Last Update',
                                  'value': _asString(
                                      _getData('outlet_detail.mtd_dt'),
                                      isLoading ? 'Loading...' : 'N/A'),
                                },
                                {
                                  'label': 'Status',
                                  'value': _asString(
                                      _getData('outlet_detail.status'),
                                      isLoading ? 'Loading...' : 'N/A'),
                                },
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Outlet PROGRAM Section (Custom Table)
                            _buildInfoSection(
                              title: 'Outlet PROGRAM',
                              icon: Icons.star, // Example icon
                              color: const Color(0xFFFFA726), // Example color
                              isCustomTable: true,
                              customTableWidget: Container(
                                constraints: BoxConstraints(
                                  // Keep constraints if needed, or adjust
                                  minHeight: 100,
                                  maxHeight: mediaQueryHeight * 0.25,
                                ),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  // Use border instead of shadow if preferred
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                  // boxShadow: const [
                                  //   BoxShadow(
                                  //     color: Colors.black12,
                                  //     blurRadius: 2,
                                  //     spreadRadius: 2,
                                  //   ),
                                  // ],
                                ),
                                child: SingleChildScrollView(
                                  // Keep existing structure inside
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // First column - KPI NAME (Keep existing DataTable)
                                          DataTable(
                                            // ... existing DataTable properties ...
                                            horizontalMargin: 12,
                                            columnSpacing: 8,
                                            headingRowHeight: 30,
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                    Colors.grey.shade200),
                                            columns: const [
                                              DataColumn(
                                                label: Text(
                                                  'KPI NAME',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            rows: [
                                              DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      _asString(
                                                          _getData(
                                                              'program.kpi_name'),
                                                          isLoading
                                                              ? 'Loading...'
                                                              : 'Tidak ada data'),
                                                      style: const TextStyle(
                                                          fontSize: 10),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          // Scrollable parameters columns (Keep existing DataTable)
                                          Expanded(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: DataTable(
                                                // ... existing DataTable properties ...
                                                horizontalMargin: 45,
                                                columnSpacing: 8,
                                                headingRowHeight: 30,
                                                headingRowColor:
                                                    WidgetStateProperty.all(
                                                        Colors.grey.shade200),
                                                columns: const [
                                                  DataColumn(
                                                    label: Text('TARGET',
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                  DataColumn(
                                                    label: Text('MTD',
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                  DataColumn(
                                                    label: Text('ACHV',
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                  DataColumn(
                                                    label: Text('POINT',
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                ],
                                                rows: [
                                                  DataRow(
                                                    cells: [
                                                      DataCell(
                                                        Container(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                            _getData('program.kpi_name') !=
                                                                        null &&
                                                                    _asString(_getData(
                                                                            'program.kpi_name')) !=
                                                                        'Tidak ada data program' &&
                                                                    _asString(_getData(
                                                                            'program.kpi_name')) !=
                                                                        'Gagal memuat program' &&
                                                                    _asString(_getData(
                                                                            'program.kpi_name')) !=
                                                                        'Error memuat program'
                                                                ? _formatNumber(
                                                                    _getData(
                                                                        'program.target'))
                                                                : isLoading
                                                                    ? '...'
                                                                    : 'N/A',
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        10),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Container(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                            _getData('program.mtd') !=
                                                                        null &&
                                                                    _asInt(_getData(
                                                                            'program.mtd')) >
                                                                        0
                                                                ? _formatNumber(
                                                                    _getData(
                                                                        'program.mtd'))
                                                                : _getData('program.kpi_name') != null &&
                                                                        _asString(_getData('program.kpi_name')) !=
                                                                            'Tidak ada data program' &&
                                                                        _asString(_getData('program.kpi_name')) !=
                                                                            'Gagal memuat program' &&
                                                                        _asString(_getData('program.kpi_name')) !=
                                                                            'Error memuat program'
                                                                    ? _formatNumber(
                                                                        _getData(
                                                                            'program.mtd')) // Show 0 if applicable
                                                                    : isLoading
                                                                        ? '...'
                                                                        : 'N/A',
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        10),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Container(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                            _getData('program.kpi_name') !=
                                                                        null &&
                                                                    _asString(_getData(
                                                                            'program.kpi_name')) !=
                                                                        'Tidak ada data program' &&
                                                                    _asString(_getData(
                                                                            'program.kpi_name')) !=
                                                                        'Gagal memuat program' &&
                                                                    _asString(_getData(
                                                                            'program.kpi_name')) !=
                                                                        'Error memuat program'
                                                                ? '${_asInt(_getData('program.achievement'))}%'
                                                                : isLoading
                                                                    ? '...'
                                                                    : 'N/A',
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        10),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Container(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                            _getData('program.kpi_name') !=
                                                                        null &&
                                                                    _asString(_getData(
                                                                            'program.kpi_name')) !=
                                                                        'Tidak ada data program' &&
                                                                    _asString(_getData(
                                                                            'program.kpi_name')) !=
                                                                        'Gagal memuat program' &&
                                                                    _asString(_getData(
                                                                            'program.kpi_name')) !=
                                                                        'Error memuat program'
                                                                ? _asString(
                                                                    _getData(
                                                                        'program.poin'))
                                                                : isLoading
                                                                    ? '...'
                                                                    : 'N/A',
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        10),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
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
                              data: const [], // Data is handled by custom widget
                            ),
                            const SizedBox(height: 16),

                            // Outlet GA Section
                            _buildInfoSection(
                              title: 'GA (GROWTH ACTUAL)',
                              icon: Icons.trending_up,
                              color: const Color(0xFFAB47BC), // Purple
                              data: [
                                {
                                  'label': 'GA LMTD',
                                  'value':
                                      _formatNumber(_getData('ga.ga_lmtd')),
                                },
                                {
                                  'label': 'GA MTD',
                                  'value': _formatNumber(_getData('ga.ga_mtd')),
                                },
                                {
                                  'label': 'GA Growth',
                                  'value':
                                      '${_asDouble(_getData('ga.ga_growth'), 0.0).toStringAsFixed(1)}%',
                                },
                                {
                                  'label': 'Q SSO LMTD',
                                  'value':
                                      _formatNumber(_getData('ga.q_sso_lmtd')),
                                },
                                {
                                  'label': 'Q SSO MTD',
                                  'value':
                                      _formatNumber(_getData('ga.q_sso_mtd')),
                                },
                                {
                                  'label': 'Q SSO Growth',
                                  'value':
                                      '${_asDouble(_getData('ga.q_sso_growth'), 0.0).toStringAsFixed(1)}%',
                                },
                                {
                                  'label': 'Q URO LMTD',
                                  'value':
                                      _formatNumber(_getData('ga.q_uro_lmtd')),
                                },
                                {
                                  'label': 'Q URO MTD',
                                  'value':
                                      _formatNumber(_getData('ga.q_uro_mtd')),
                                },
                                {
                                  'label': 'Q URO Growth',
                                  'value':
                                      '${_asDouble(_getData('ga.q_uro_growth'), 0.0).toStringAsFixed(1)}%',
                                },
                              ],
                            ),
                            const SizedBox(height: 16),

                            // SEC (SECONDARY) Section
                            _buildInfoSection(
                              title: 'SEC (SECONDARY)',
                              icon: Icons.phonelink_ring,
                              color: const Color(0xFF26A69A), // Teal
                              data: [
                                {
                                  'label': 'SP Hits LMTD',
                                  'value': _formatNumber(
                                      _getData('sec.sec_sp_hits_lmtd')),
                                },
                                {
                                  'label': 'SP Hits MTD',
                                  'value': _formatNumber(
                                      _getData('sec.sec_sp_hits_mtd')),
                                },
                                {
                                  'label': 'SP Hits Growth',
                                  'value':
                                      '${_asDouble(_getData('sec.sec_sp_hits_growth'), 0.0).toStringAsFixed(1)}%',
                                },
                                {
                                  'label': 'Voucher Hits LMTD',
                                  'value': _formatNumber(
                                      _getData('sec.sec_vou_hits_lmtd')),
                                },
                                {
                                  'label': 'Voucher Hits MTD',
                                  'value': _formatNumber(
                                      _getData('sec.sec_vou_hits_mtd')),
                                },
                                {
                                  'label': 'Voucher Hits Growth',
                                  'value':
                                      '${_asDouble(_getData('sec.sec_vou_hits_growth'), 0.0).toStringAsFixed(1)}%',
                                },
                              ],
                            ),
                            const SizedBox(height: 16),

                            // SUPPLY Section
                            _buildInfoSection(
                              title: 'SUPPLY',
                              icon: Icons.inventory_2,
                              color: const Color(0xFF5C6BC0), // Indigo
                              data: [
                                {
                                  'label': 'SP LMTD',
                                  'value': _formatNumber(
                                      _getData('supply.supply_sp_lmtd')),
                                },
                                {
                                  'label': 'SP MTD',
                                  'value': _formatNumber(
                                      _getData('supply.supply_sp_mtd')),
                                },
                                {
                                  'label': 'SP Growth',
                                  'value':
                                      '${_asDouble(_getData('supply.supply_sp_growth'), 0.0).toStringAsFixed(1)}%',
                                },
                                {
                                  'label': 'Voucher LMTD',
                                  'value': _formatNumber(
                                      _getData('supply.supply_vo_lmtd')),
                                },
                                {
                                  'label': 'Voucher MTD',
                                  'value': _formatNumber(
                                      _getData('supply.supply_vo_mtd')),
                                },
                                {
                                  'label': 'Voucher Growth',
                                  'value':
                                      '${_asDouble(_getData('supply.supply_vo_growth'), 0.0).toStringAsFixed(1)}%',
                                },
                              ],
                            ),
                            const SizedBox(height: 16),

                            // DEMAND (TERTIARY) Section
                            _buildInfoSection(
                              title: 'DEMAND (TERTIARY)',
                              icon: Icons.groups,
                              color: const Color(0xFFEF5350), // Red
                              data: [
                                {
                                  'label': 'SP LMTD',
                                  'value': _formatNumber(
                                      _getData('demand.tert_sp_lmtd')),
                                },
                                {
                                  'label': 'SP MTD',
                                  'value': _formatNumber(
                                      _getData('demand.tert_sp_mtd')),
                                },
                                {
                                  'label': 'SP Growth',
                                  'value':
                                      '${_asDouble(_getData('demand.tert_sp_growth'), 0.0).toStringAsFixed(1)}%',
                                },
                                {
                                  'label': 'Voucher LMTD',
                                  'value': _formatNumber(
                                      _getData('demand.tert_vo_lmtd')),
                                },
                                {
                                  'label': 'Voucher MTD',
                                  'value': _formatNumber(
                                      _getData('demand.tert_vo_mtd')),
                                },
                                {
                                  'label': 'Voucher Growth',
                                  'value':
                                      '${_asDouble(_getData('demand.tert_vo_growth'), 0.0).toStringAsFixed(1)}%',
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

            // Bottom navigation bar (Styled like detail_site.dart)
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
                            color: primaryColor, // Use primary color
                            size: 22,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Home',
                            style: TextStyle(
                              color: primaryColor, // Use primary color
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add other icons here if needed, following the same pattern
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
