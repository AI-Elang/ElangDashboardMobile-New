import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

class FotoMitraHistory extends StatefulWidget {
  final int checkInId; // Changed from imageUrl and title

  const FotoMitraHistory({
    super.key,
    required this.checkInId, // Changed
  });

  @override
  State<FotoMitraHistory> createState() => _FotoMitraHistoryState();
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

class _FotoMitraHistoryState extends State<FotoMitraHistory> {
  var baseURL = dotenv.env['baseURL'];

  String? _imageUrl;
  String? _username;
  String? _description;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCheckInDetails();
  }

  Future<void> _fetchCheckInDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      final url = Uri.parse(
          '$baseURL/api/v1/mitra/detail/check-in/${widget.checkInId}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          setState(() {
            _imageUrl = responseData['data']['image'];
            _username = responseData['data']['username'];
            _description = responseData['data']['description'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = "Failed to parse check-in details.";
          });
          _showErrorSnackBar("Failed to parse check-in details.");
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Failed to load check-in details: ${response.statusCode}";
        });
        _showErrorSnackBar(
            "Failed to load check-in details: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error fetching check-in details: $e";
      });
      _showErrorSnackBar("Error fetching check-in details: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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

    // Define our color scheme - matching DSE Report style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray

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
                                'FOTO CHECK-IN',
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
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              strokeWidth: 2,
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Username Card
                                if (_username != null && _username!.isNotEmpty)
                                  Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    color: cardColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
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
                                          const Icon(
                                            Icons.person,
                                            color: primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _username!,
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
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                // Photo Section
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
                                                color: accentColor,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Foto Check-in',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),

                                        // Photo content
                                        Container(
                                          height: 250,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F9FA),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: (_imageUrl != null &&
                                                  _imageUrl!.isNotEmpty)
                                              ? GestureDetector(
                                                  onTap: () =>
                                                      _openPhoto(_imageUrl!),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.network(
                                                      _imageUrl!,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            value: loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                            color: accentColor,
                                                            strokeWidth: 2,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .broken_image_rounded,
                                                                size: 40,
                                                                color: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                        0.5),
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'Image error',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey
                                                                      .withOpacity(
                                                                          0.7),
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
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .no_photography_rounded,
                                                        size: 40,
                                                        color: Colors.grey
                                                            .withOpacity(0.4),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'No Photo Available',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey
                                                              .withOpacity(0.7),
                                                          fontWeight:
                                                              FontWeight.w500,
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

                                const SizedBox(height: 16),

                                // Description Section
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
                                                color: primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.description,
                                              color: primaryColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Deskripsi',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _description?.isNotEmpty == true
                                              ? _description!
                                              : 'Tidak ada deskripsi tersedia',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _description?.isNotEmpty ==
                                                    true
                                                ? textPrimaryColor
                                                : Colors.grey.withOpacity(0.7),
                                            height: 1.5,
                                            fontStyle:
                                                _description?.isNotEmpty == true
                                                    ? FontStyle.normal
                                                    : FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Extra padding for bottom nav space
                                const SizedBox(height: 70),
                              ],
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
}
