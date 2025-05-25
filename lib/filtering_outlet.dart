import 'package:elang_dashboard_new_ui/detail_outlet.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:math';

class FilteringOutlet extends StatefulWidget {
  final int idSec;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;
  final String selectedNameFO;

  const FilteringOutlet({
    super.key,
    required this.idSec,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
    required this.selectedNameFO,
  });

  @override
  State<FilteringOutlet> createState() => _FOState();
}

class _FOState extends State<FilteringOutlet> {
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

  final TextEditingController _searchController = TextEditingController();

  final String _selectedDropdown1 = 'Circle Java';
  String? _selectedDropdown2;
  String? _selectedDropdown3;
  String? _selectedDropdown4;
  String _searchText = '';

  Position? _currentPosition;

  List<Map<String, dynamic>> _FOData = [];
  List<Map<String, dynamic>> _filteredFOData = [];

  final Map<String, Map<String, dynamic>> _outletLocations = {};

  var baseURL = dotenv.env['baseURL'];

  bool _isLoading = true; // Add loading state
  bool _isFiltersCollapsed = true; // Add state for collapsible filters

  Future<void> fetchFOData(String? token) async {
    final filteringOutlet = widget.selectedNameFO;
    final mc = widget.idSec;
    final url = '$baseURL/api/v1/outlet/$filteringOutlet?mc=$mc';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> FODataReceived = data['data'];

        setState(() {
          _FOData = FODataReceived.map((fo) => {
                'qr_code': fo['qr_code'],
                'outlet_name': fo['outlet_name'],
                'partner_name': fo['partner_name'],
                'catagory': fo['catagory'],
                'brand': fo['brand'],
                'program': fo['program'],
              }).toList();
          _isLoading = false; // Set loading to false after data is fetched
        });
      } else {
        setState(() {
          _isLoading = false; // Set loading to false even if there's an error
        });
        SnackBar(content: Text('Failed to load data: ${response.statusCode}'));
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Set loading to false even if there's an error
      });
      const SnackBar(content: Text('Error fetching data'));
    }
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text(
                  'Please enable location services to see distances.'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Permission Denied'),
              content: const Text(
                  'Please enable location permissions in settings to see distances.'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      const SnackBar(content: Text('Error getting location'));
    }
  }

  Future<void> _fetchOutletLocation(String qrCode, String? token) async {
    if (_outletLocations.containsKey(qrCode)) {
      return;
    }

    try {
      final url = Uri.parse('$baseURL/api/v1/outlet/detail/$qrCode');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _outletLocations[qrCode] = {
            'latitude': data['data']['latitude'],
            'longitude': data['data']['longitude'],
          };
        });
      }
    } catch (e) {
      const SnackBar(content: Text('Error fetching outlet location'));
    }
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const int earthRadius = 6371; // Radius of the earth in km
    double latDistance = _toRadians(lat2 - lat1);
    double lonDistance = _toRadians(lon2 - lon1);
    double a = sin(latDistance / 2) * sin(latDistance / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(lonDistance / 2) *
            sin(lonDistance / 2);
    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  void _filterData() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
      _filteredFOData = _FOData.where((fo) {
        final qrCode = fo['qr_code'].toString().toLowerCase();
        final outletName = fo['outlet_name'].toString().toLowerCase();
        final programName = fo['program'].toString().toLowerCase();

        return qrCode.contains(_searchText) ||
            outletName.contains(_searchText) ||
            programName.contains(_searchText);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    _selectedDropdown2 = widget.selectedRegion;
    _selectedDropdown3 = widget.selectedArea;
    _selectedDropdown4 = widget.selectedBranch;

    fetchFOData(token);
    _initializeLocation();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    // final mediaQueryWidth = MediaQuery.of(context).size.width; // Keep if needed elsewhere
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define color scheme - matching outlet.dart style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    return Scaffold(
      backgroundColor: backgroundColor, // Use defined background color
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // App structure
            Column(
              children: [
                // Header container with gradient (like outlet.dart)
                Container(
                  height: mediaQueryHeight * 0.06, // Adjusted height
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
                      child: Text(
                        'DATA OUTLET', // Updated title
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main content area
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: backgroundColor, // Use defined background color
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08, // Adjusted opacity
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // User profile and filters section (Card like outlet.dart)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  // User info row (like outlet.dart)
                                  Row(
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
                                          radius: 30, // Adjusted size
                                          backgroundImage:
                                              AssetImage('assets/100.png'),
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

                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),

                                  // Filters section with collapsible functionality
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Filter header with toggle icon
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Filters",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                          InkWell(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            onTap: () {
                                              setState(() {
                                                _isFiltersCollapsed =
                                                    !_isFiltersCollapsed;
                                              });
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: AnimatedRotation(
                                                turns: _isFiltersCollapsed
                                                    ? 0.25 // Pointing right/down
                                                    : 0, // Pointing down/up
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                child: Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.black
                                                      .withOpacity(0.7),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Animated container for filters content
                                      AnimatedCrossFade(
                                        firstChild: const SizedBox(
                                          height: 0,
                                          width: double.infinity,
                                        ),
                                        secondChild: Column(
                                          children: [
                                            const SizedBox(height: 8),
                                            // Filter cards grid
                                            Container(
                                              decoration: BoxDecoration(
                                                color: backgroundColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                children: [
                                                  // First row of filters
                                                  Row(
                                                    children: [
                                                      // Circle filter
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Circle",
                                                          _selectedDropdown1,
                                                          true, // Locked
                                                          (value) {}, // No action needed
                                                          ['Circle Java'],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      // Region filter
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Region",
                                                          _selectedDropdown2!,
                                                          true, // Locked
                                                          (value) {}, // No action needed
                                                          [
                                                            widget
                                                                .selectedRegion
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Second row of filters
                                                  Row(
                                                    children: [
                                                      // Area filter
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Area",
                                                          _selectedDropdown3!,
                                                          true, // Locked
                                                          (value) {}, // No action needed
                                                          [widget.selectedArea],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      // Branch filter
                                                      Expanded(
                                                        child:
                                                            _buildFilterDropdown(
                                                          "Branch",
                                                          _selectedDropdown4!,
                                                          true, // Locked
                                                          (value) {}, // No action needed
                                                          [
                                                            widget
                                                                .selectedBranch
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
                                        crossFadeState: _isFiltersCollapsed
                                            ? CrossFadeState.showFirst
                                            : CrossFadeState.showSecond,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        reverseDuration:
                                            const Duration(milliseconds: 200),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Search Bar (Styled like outlet.dart filters)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                  fontSize: 13, color: textPrimaryColor),
                              decoration: const InputDecoration(
                                hintText: 'Search Outlet Name, ID, Program...',
                                hintStyle: TextStyle(
                                    fontSize: 13, color: textSecondaryColor),
                                border: InputBorder.none,
                                icon: Icon(Icons.search,
                                    color: textSecondaryColor, size: 20),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8), // Spacing before list header

                        // Outlet List Section Header (like outlet.dart)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                'OUTLET LIST', // Static header text
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
                                  '${_searchText.isEmpty ? _FOData.length : _filteredFOData.length} entries', // Show entry count
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

                        const SizedBox(height: 16), // Spacing before list

                        // Outlet list section
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : (_searchText.isEmpty
                                            ? _FOData
                                            : _filteredFOData)
                                        .isNotEmpty
                                    ? ListView.builder(
                                        padding: EdgeInsets
                                            .zero, // Remove default padding
                                        itemCount: _searchText.isEmpty
                                            ? _FOData.length
                                            : _filteredFOData.length,
                                        itemBuilder: (context, index) {
                                          final fo = _searchText.isEmpty
                                              ? _FOData[index]
                                              : _filteredFOData[index];
                                          return _buildOutletItem(
                                              fo,
                                              cardColor,
                                              textPrimaryColor,
                                              textSecondaryColor);
                                        },
                                      )
                                    : _buildEmptyState(
                                        'No Outlets Found',
                                        _searchText.isEmpty
                                            ? 'No data available for the selected filters.'
                                            : 'No outlets match your search criteria.',
                                        textPrimaryColor,
                                        textSecondaryColor), // Use helper for empty state
                          ),
                        ),

                        const SizedBox(height: 70), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom navigation bar (styled like outlet.dart)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60, // Adjusted height
                decoration: BoxDecoration(
                  color: cardColor, // Use card color
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20), // Rounded corners
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15), // Softer shadow
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Home Button (styled like outlet.dart)
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
                            Icons.home, // Use appropriate icon
                            color: primaryColor, // Use primary color
                            size: 22, // Adjust size
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Home', // Label
                            style: TextStyle(
                              color: primaryColor, // Use primary color
                              fontSize: 11, // Adjust size
                              fontWeight: FontWeight.w600, // Adjust weight
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
          ],
        ),
      ),
    );
  }

  // Helper method to build filter dropdowns (adapted from outlet.dart style)
  Widget _buildFilterDropdown(
    String label,
    String value,
    bool isLocked,
    Function(String) onChanged,
    List<String> items,
  ) {
    // Define colors locally or pass them if needed
    const textPrimaryColor = Color(0xFF2D3142);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Background for dropdown area
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600, // Lighter color for label
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4), // Spacing between label and dropdown
          DropdownButtonHideUnderline(
            // Hides the default underline
            child: DropdownButton<String>(
              value: value,
              isDense: true, // Reduces vertical padding
              isExpanded: true, // Makes dropdown take available width
              icon: Icon(
                Icons.arrow_drop_down, // Standard dropdown icon
                color: isLocked
                    ? Colors.grey.shade400
                    : Colors.grey.shade700, // Icon color based on lock state
              ),
              onChanged: isLocked
                  ? null
                  : (newValue) => onChanged(newValue!), // Disable if locked
              items: items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12, // Font size for items
                      color: isLocked
                          ? Colors.grey
                          : textPrimaryColor, // Text color based on state
                      fontWeight: FontWeight.w500,
                    ),
                    overflow:
                        TextOverflow.ellipsis, // Prevent long text overflow
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutletItem(Map<String, dynamic> fo, Color cardColor,
      Color textPrimaryColor, Color textSecondaryColor) {
    return FutureBuilder(
      future: _fetchOutletLocation(
          fo['qr_code'].toString(), Provider.of<AuthProvider>(context).token),
      builder: (context, snapshot) {
        String distanceText = 'Calculating distance...';

        if (_currentPosition == null) {
          distanceText = 'Waiting for location...';
        } else if (!_outletLocations.containsKey(fo['qr_code'].toString())) {
          distanceText = 'Loading distance...';
        } else {
          final location = _outletLocations[fo['qr_code'].toString()]!;
          if (location['latitude'] != null && location['longitude'] != null) {
            try {
              double distance = _calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                double.parse(location['latitude'].toString()), // Ensure parsing
                double.parse(
                    location['longitude'].toString()), // Ensure parsing
              );
              distanceText = 'Distance: ${_formatDistance(distance)}';
            } catch (e) {
              distanceText = 'Distance unavailable'; // Handle parsing error
            }
          } else {
            distanceText = 'Distance unavailable';
          }
        }

        // Determine the background color based on brand and program
        Color labelColor = _getLabelColor(fo['brand'], fo['program']);
        Color labelTextColor = _getLabelTextColor(fo['brand'], fo['program']);
        bool showLabelBackground = labelColor != Colors.white;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: cardColor,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailOutlet(
                    qrCode: fo['qr_code'].toString(),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                fo['outlet_name'],
                                style: TextStyle(
                                  fontSize: 14, // Slightly larger
                                  fontWeight: FontWeight.w600, // Bolder
                                  color: textPrimaryColor,
                                ),
                                maxLines: 2, // Allow two lines
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: showLabelBackground ? 8 : 0,
                                  vertical: showLabelBackground ? 2 : 0),
                              decoration: showLabelBackground
                                  ? BoxDecoration(
                                      color: labelColor,
                                      borderRadius: BorderRadius.circular(10),
                                    )
                                  : null,
                              child: Text(
                                '${fo['brand']} | ${fo['program'] ?? '-'}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: showLabelBackground
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: labelTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${fo['qr_code']}',
                          style: TextStyle(
                              fontSize: 12, color: textSecondaryColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          distanceText,
                          style: const TextStyle(
                            fontSize: 11, // Slightly smaller
                            color: Colors.blueAccent, // Different blue
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios,
                      color: textSecondaryColor.withOpacity(0.7), size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build empty state (copied from outlet.dart style)
  Widget _buildEmptyState(String title, String subtitle, Color textPrimaryColor,
      Color textSecondaryColor) {
    return Container(
      // Wrap in a container for potential styling or margin
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Match card background
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.grey.shade200, width: 1), // Subtle border
      ),
      child: Center(
        child: Padding(
          // Add padding inside the empty state
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take minimum space
            children: [
              Icon(
                Icons.search_off_rounded, // Icon indicating no results
                size: 48,
                color: Colors.grey.shade400, // Muted color for icon
              ),
              const SizedBox(height: 12), // Space between icon and text
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor, // Use defined primary text color
                ),
              ),
              const SizedBox(height: 4), // Space between title and subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondaryColor, // Use defined secondary text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ...existing code... (Keep _getLabelColor and _getLabelTextColor)
  Color _getLabelColor(String brand, String program) {
    if (brand == 'IM3') {
      // For IM3: White if program is missing/empty, Yellow otherwise
      if (program == '' || program == '-') {
        return Colors.white;
      } else {
        return const Color.fromRGBO(242, 179, 31, 1); // Yellow
      }
    } else if (brand == '3ID') {
      // For 3ID: White if program is missing/empty, Magenta otherwise
      if (program == '' || program == '-') {
        return Colors.white;
      } else {
        return const Color.fromRGBO(255, 0, 255, 1); // Magenta
      }
    } else {
      // Default color for other brands
      return Colors.white;
    }
  }

  Color _getLabelTextColor(String brand, String program) {
    if ((brand == 'IM3' || brand == '3ID') &&
        (program == '' || program == '-')) {
      // For white background labels
      return Colors.black;
    } else if (brand == 'IM3' && program != '' && program != '-') {
      // For yellow background labels
      return Colors.black;
    } else if (brand == '3ID' && program != '' && program != '-') {
      // For magenta background labels
      return Colors.white;
    } else {
      // Default text color
      return Colors.black;
    }
  }
}
