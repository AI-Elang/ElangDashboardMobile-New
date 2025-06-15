import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class DetailFotoListComplain extends StatefulWidget {
  final String date;
  final String title;
  final String outletId;

  const DetailFotoListComplain({
    super.key,
    required this.date,
    required this.title,
    required this.outletId,
  });

  @override
  State<DetailFotoListComplain> createState() => _DetailFotoListComplainState();
}

// Photo View Page
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

class _DetailFotoListComplainState extends State<DetailFotoListComplain> {
  Map<String, dynamic> outletComplainDetails = {};

  var baseURL = dotenv.env['baseURL'];
  var fotoComplaint = '';

  bool isLoading = true;

  Future<void> _fetchData(String? token) async {
    final url = Uri.parse(
      '$baseURL/api/v1/dse-ai/complaints/${widget.outletId}/images?date=${widget.date}',
    );

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          // Store the outlet complaint details directly
          outletComplainDetails = responseData['data'] ?? {};
          fotoComplaint = outletComplainDetails['complaint_image'] ?? '';
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load data: ${response.statusCode}')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching data')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    _fetchData(token);
  }

  void _openPhoto(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewPage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    // final mediaQueryWidth = MediaQuery.of(context).size.width; // Can be removed if not directly used

    // Define color scheme - adapt from detail_foto_ai.dart or define new ones
    const primaryColor = Color(0xFF6A62B7); // Example color
    const accentColor = Color(0xFFEE92C2); // Example color
    const backgroundColor = Color(0xFFF8F9FA); // Example background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Example text color
    const textSecondaryColor = Color(0xFF8D8D92); // Example text color

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // App structure
            Column(
              children: [
                // Header container with gradient (similar to detail_foto_ai.dart)
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
                        'FOTO LIST COMPLAIN',
                        style: TextStyle(
                          fontSize: 16, // Adjusted size
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
                      color: backgroundColor,
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO3.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08, // Adjusted opacity
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: isLoading
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
                                  "Loading details...",
                                  style: TextStyle(
                                    color: textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                                16, 16, 16, 70), // Add padding for bottom nav
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Outlet information card
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: cardColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
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
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "${widget.outletId} - ${widget.title}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimaryColor,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 12),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 14,
                                                color: primaryColor
                                                    .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                outletComplainDetails[
                                                        'complaint_date'] ??
                                                    widget.date,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textPrimaryColor
                                                      .withOpacity(0.7),
                                                  fontWeight: FontWeight.w500,
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

                                // Complaint Photo Card
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: cardColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Section Header
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color:
                                                    accentColor, // Use accent color
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Foto Selfie Complain',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Use the helper method for photo display
                                        _buildPhotoCard(
                                          '', // No title needed inside the card itself
                                          fotoComplaint,
                                          accentColor, // Use accent color
                                          Icons
                                              .camera_alt_rounded, // Example icon
                                          isFullWidth: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Complaint Details Card
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: cardColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Section Header
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                    0xFF67C587), // Example color (soft green)
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Detail Outlet Complain',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Display details using styled Text or keep Table
                                        _buildDetailRow(
                                            'Category',
                                            outletComplainDetails['category'] ??
                                                '-'),
                                        const Divider(
                                            height: 16, thickness: 0.5),
                                        _buildDetailRow(
                                            'Detail',
                                            outletComplainDetails['detail'] ??
                                                '-'),
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

            // Bottom navigation bar (copied from detail_foto_ai.dart)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60, // Standard height
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
                    ),
                    // Add other navigation items if needed
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for displaying photos (adapted from detail_foto_ai.dart)
  Widget _buildPhotoCard(
      String title, String photoUrl, Color accentColor, IconData icon,
      {bool isFullWidth = false}) {
    // Define text colors locally if not using the main theme colors directly
    const textSecondaryColor = Color(0xFF8D8D92);

    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white, // Keep background white or slightly off-white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional: Photo header if title is needed above the image
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Photo content
          Container(
            // Adjust height as needed, make it responsive if possible
            height: 250, // Example fixed height, adjust as necessary
            width: double.infinity,
            decoration: BoxDecoration(
              // Use a light background color for the container
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: photoUrl.isNotEmpty
                ? GestureDetector(
                    onTap: () => _openPhoto(photoUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit
                            .contain, // Use contain to see the whole image
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: accentColor,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_rounded,
                                  size: 40,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image error',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondaryColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  )
                : Center(
                    // "No Photo" state
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.no_photography_rounded,
                          size: 40,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No Photo Available',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Helper for detail rows (replaces TableRow for better styling within Card)
  Widget _buildDetailRow(String label, String value) {
    const textPrimaryColor = Color(0xFF2D3142);
    const textSecondaryColor = Color(0xFF8D8D92);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80, // Fixed width for label
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimaryColor, // Use primary text color
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: textSecondaryColor, // Use secondary text color
              ),
            ),
          ),
        ],
      ),
    );
  }
}
