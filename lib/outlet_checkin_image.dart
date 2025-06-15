import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:convert';

class PhotoViewPage extends StatelessWidget {
  final String imageUrl;

  const PhotoViewPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo View'),
      ),
      body: Center(child: PhotoView(imageProvider: NetworkImage(imageUrl))),
    );
  }
}

class OutletCheckinImage extends StatefulWidget {
  final String checkinId;
  final String username;

  const OutletCheckinImage({
    super.key,
    required this.checkinId,
    required this.username,
  });

  @override
  State<OutletCheckinImage> createState() => _OutletCheckinImageState();
}

class _OutletCheckinImageState extends State<OutletCheckinImage> {
  Map<String, dynamic> _checkinImageData = {};
  bool _isLoading = true;
  var baseURL = dotenv.env['baseURL'];

  // Define color scheme - matching detail_foto_ai.dart
  static const primaryColor = Color(0xFF6A62B7);
  static const accentColor = Color(0xFFEE92C2);
  static const backgroundColor = Color(0xFFF8F9FA);
  static const cardColor = Colors.white;
  static const textPrimaryColor = Color(0xFF2D3142);
  static const textSecondaryColor = Color(0xFF8D8D92);

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

  Future<void> fetchOutletCheckinImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    final url = '$baseURL/api/v1/outlet/checkins/image/${widget.checkinId}';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _checkinImageData = data['data'] ?? {};
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
    fetchOutletCheckinImage();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final mediaQueryWidth = MediaQuery.of(context).size.width;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Accessing data from maps
    final String outletId =
        _checkinImageData['outlet_id']?.toString() ?? 'Loading...';
    final String outletName =
        _checkinImageData['outlet_name']?.toString() ?? 'Loading...';
    final String? latitude = _checkinImageData['latitude']?.toString();
    final String? longitude = _checkinImageData['longitude']?.toString();
    final String? imageUrl = _checkinImageData['image']?.toString();
    final String description =
        _checkinImageData['description']?.toString() ?? 'No description';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Modern header with gradient
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
                      'OUTLET CHECKIN IMAGE',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: primaryColor,
                                  strokeWidth: 3,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              mediaQueryWidth * 0.04,
                              mediaQueryHeight * 0.02,
                              mediaQueryWidth * 0.04,
                              mediaQueryHeight * 0.1,
                            ),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User info card
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: cardColor,
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(mediaQueryWidth * 0.04),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: mediaQueryWidth * 0.15,
                                          height: mediaQueryWidth * 0.15,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                primaryColor.withOpacity(0.1),
                                                accentColor.withOpacity(0.1)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: const CircleAvatar(
                                            backgroundImage:
                                                AssetImage('assets/LOGO3.png'),
                                            backgroundColor: Colors.transparent,
                                          ),
                                        ),
                                        SizedBox(width: mediaQueryWidth * 0.03),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                territory,
                                                style: TextStyle(
                                                  fontSize:
                                                      mediaQueryWidth * 0.025,
                                                  color: textSecondaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(
                                                  height:
                                                      mediaQueryHeight * 0.005),
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
                                                style: TextStyle(
                                                  fontSize:
                                                      mediaQueryWidth * 0.035,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    mediaQueryWidth * 0.02,
                                                vertical:
                                                    mediaQueryHeight * 0.005,
                                              ),
                                              decoration: BoxDecoration(
                                                color: primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _formattedDate(),
                                                style: TextStyle(
                                                  fontSize:
                                                      mediaQueryWidth * 0.025,
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: mediaQueryHeight * 0.02),

                                // Outlet Info Card
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: cardColor,
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(mediaQueryWidth * 0.04),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            SizedBox(
                                                width: mediaQueryWidth * 0.02),
                                            const Text(
                                              'Outlet Information',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                            height: mediaQueryHeight * 0.02),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildInfoTile(
                                                'Outlet ID',
                                                outletId,
                                                Icons.store,
                                                const Color(0xFFFF9800),
                                                mediaQueryWidth,
                                              ),
                                            ),
                                            SizedBox(
                                                width: mediaQueryWidth * 0.03),
                                            Expanded(
                                              child: _buildInfoTile(
                                                'Outlet Name',
                                                outletName,
                                                Icons.business,
                                                const Color(0xFF4CAF50),
                                                mediaQueryWidth,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: mediaQueryHeight * 0.02),

                                // Location Card
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: cardColor,
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(mediaQueryWidth * 0.04),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE91E63),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            SizedBox(
                                                width: mediaQueryWidth * 0.02),
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
                                        SizedBox(
                                            height: mediaQueryHeight * 0.02),
                                        Container(
                                          height: mediaQueryHeight * 0.25,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: latitude != null &&
                                                    longitude != null &&
                                                    double.tryParse(latitude) !=
                                                        null &&
                                                    double.tryParse(
                                                            longitude) !=
                                                        null
                                                ? GoogleMap(
                                                    initialCameraPosition:
                                                        CameraPosition(
                                                      target: LatLng(
                                                        double.parse(latitude),
                                                        double.parse(longitude),
                                                      ),
                                                      zoom: 15,
                                                    ),
                                                    markers: {
                                                      Marker(
                                                        markerId: const MarkerId(
                                                            'outlet_location'),
                                                        position: LatLng(
                                                          double.parse(
                                                              latitude),
                                                          double.parse(
                                                              longitude),
                                                        ),
                                                        icon: BitmapDescriptor
                                                            .defaultMarkerWithHue(
                                                          BitmapDescriptor
                                                              .hueRed,
                                                        ),
                                                      ),
                                                    },
                                                    myLocationEnabled: false,
                                                    zoomControlsEnabled: true,
                                                    mapType: MapType.normal,
                                                  )
                                                : const Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.location_off,
                                                          size: 48,
                                                          color:
                                                              textSecondaryColor,
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'No location data',
                                                          style: TextStyle(
                                                            color:
                                                                textSecondaryColor,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: mediaQueryHeight * 0.02),

                                // Image Card
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: cardColor,
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(mediaQueryWidth * 0.04),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF9C27B0),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            SizedBox(
                                                width: mediaQueryWidth * 0.02),
                                            const Text(
                                              'Check-in Image',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                            height: mediaQueryHeight * 0.02),
                                        Container(
                                          height: mediaQueryHeight * 0.25,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: imageUrl != null &&
                                                    imageUrl.isNotEmpty
                                                ? GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              PhotoViewPage(
                                                                  imageUrl:
                                                                      imageUrl),
                                                        ),
                                                      );
                                                    },
                                                    child: Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            color: primaryColor,
                                                            strokeWidth: 2,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .broken_image_rounded,
                                                                size: 48,
                                                                color:
                                                                    textSecondaryColor,
                                                              ),
                                                              SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'Failed to load image',
                                                                style:
                                                                    TextStyle(
                                                                  color:
                                                                      textSecondaryColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : const Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .no_photography_rounded,
                                                          size: 48,
                                                          color:
                                                              textSecondaryColor,
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'No image available',
                                                          style: TextStyle(
                                                            color:
                                                                textSecondaryColor,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: mediaQueryHeight * 0.02),

                                // Description Card
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: cardColor,
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(mediaQueryWidth * 0.04),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2196F3),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            SizedBox(
                                                width: mediaQueryWidth * 0.02),
                                            const Text(
                                              'Description',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                            height: mediaQueryHeight * 0.015),
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(
                                              mediaQueryWidth * 0.03),
                                          decoration: BoxDecoration(
                                            color: backgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: Text(
                                            description,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: textPrimaryColor,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),

            // Modern bottom navigation
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
                      borderRadius: BorderRadius.circular(30),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
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

  // Helper widget for info tiles
  Widget _buildInfoTile(String label, String value, IconData icon,
      Color iconColor, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                label,
                style: TextStyle(
                  fontSize: screenWidth * 0.025,
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w600,
              color: textPrimaryColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
