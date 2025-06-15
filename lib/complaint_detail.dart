import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class ComplaintDetail extends StatefulWidget {
  final String complaintId;

  const ComplaintDetail({super.key, required this.complaintId});

  @override
  State<ComplaintDetail> createState() => _ComplaintDetailState();
}

class _ComplaintDetailState extends State<ComplaintDetail> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _complaintData = {};
  final baseURL = dotenv.env['baseURL'];

  @override
  void initState() {
    super.initState();
    _fetchComplaintDetails();
  }

  Future<void> _fetchComplaintDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      final response = await http.get(
        Uri.parse('$baseURL/api/v1/complaints/${widget.complaintId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('data')) {
          setState(() {
            _complaintData = responseData['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Invalid data format from API';
          });
        }
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              errorData['meta']?['error'] ?? 'Failed to load complaint details';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Network error: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final formatter = DateFormat('dd MMMM yyyy, HH:mm');
      return formatter.format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define color scheme - matching complain.dart style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    return Scaffold(
      resizeToAvoidBottomInset: false, // Added for consistency
      backgroundColor: backgroundColor, // Use background color
      appBar: AppBar(
        title: const Text(
          'COMPLAINT DETAIL',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text for gradient appbar
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0, // Remove shadow if using gradient
        flexibleSpace: Container(
          // Use flexibleSpace for gradient
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, accentColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Keep foregroundColor for icon theming if needed, or set iconTheme explicitly
        // foregroundColor: Colors.white, // Or use iconTheme
        iconTheme:
            const IconThemeData(color: Colors.white), // Explicit icon color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: backgroundColor, // Use background color
            image: DecorationImage(
              image: AssetImage('assets/LOGO3.png'),
              fit: BoxFit.cover,
              opacity: 0.08, // Adjusted opacity like complain.dart
              alignment: Alignment.bottomRight,
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: primaryColor), // Use primary color
                )
              : _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchComplaintDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  primaryColor, // Use primary color
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Complaint ID - Styled Card
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .confirmation_number_outlined, // Changed icon
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Complaint #${_complaintData['id'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color:
                                            textPrimaryColor, // Use text color
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // User and category info - Styled Card
                          Card(
                            elevation: 1, // Consistent elevation
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  12), // Consistent radius
                            ),
                            color: cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Complaint Info',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          primaryColor, // Use primary color for title
                                    ),
                                  ),
                                  const Divider(
                                      height: 24,
                                      color:
                                          textSecondaryColor), // Use secondary color
                                  _buildInfoRow(
                                    'User',
                                    _complaintData['username'] ?? 'Unknown',
                                    Icons.person_outline, // Use outline icon
                                    textPrimaryColor, // Pass colors
                                    textSecondaryColor, // Pass colors
                                    primaryColor, // Pass colors
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    'Category',
                                    _complaintData['category_name'] ??
                                        'Not Specified',
                                    Icons.category_outlined, // Use outline icon
                                    textPrimaryColor,
                                    textSecondaryColor,
                                    primaryColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    'Date',
                                    _complaintData['date'] != null
                                        ? _formatDate(_complaintData['date'])
                                        : 'Not Available',
                                    Icons
                                        .calendar_today_outlined, // Use outline icon
                                    textPrimaryColor,
                                    textSecondaryColor,
                                    primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Complaint details - Styled Card
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor, // Use primary color
                                    ),
                                  ),
                                  const Divider(
                                      height: 24,
                                      color:
                                          textSecondaryColor), // Use secondary color
                                  Text(
                                    _complaintData['detail'] ??
                                        'No details provided',
                                    style: const TextStyle(
                                      fontSize: 15, // Slightly adjusted size
                                      color: textPrimaryColor, // Use text color
                                      height: 1.4, // Improve readability
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Image section - Styled Card
                          if (_complaintData['image'] != null &&
                              _complaintData['image'].toString().isNotEmpty)
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: cardColor,
                              clipBehavior:
                                  Clip.antiAlias, // Clip the image inside
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Attachment',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            primaryColor, // Use primary color
                                      ),
                                    ),
                                    const Divider(
                                        height: 24,
                                        color:
                                            textSecondaryColor), // Use secondary color
                                    ClipRRect(
                                      // Keep ClipRRect for image corners
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        // Consider making height flexible or responsive
                                        height:
                                            300, // Apply max height constraint here
                                        width: double.infinity,
                                        child: GestureDetector(
                                          onTap: () {
                                            // ... existing image preview navigation ...
                                            // Keep PhotoView logic as is
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => Scaffold(
                                                  appBar: AppBar(
                                                    backgroundColor:
                                                        Colors.black,
                                                    elevation: 0,
                                                    iconTheme:
                                                        const IconThemeData(
                                                            color:
                                                                Colors.white),
                                                    title: const Text(
                                                      'Image Preview',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                  body: Container(
                                                    color: Colors.black,
                                                    child: PhotoView(
                                                      imageProvider:
                                                          NetworkImage(
                                                              _complaintData[
                                                                  'image']),
                                                      // ... existing PhotoView properties ...
                                                      loadingBuilder:
                                                          (context, event) =>
                                                              Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          value: event == null
                                                              ? 0
                                                              : event.cumulativeBytesLoaded /
                                                                  (event.expectedTotalBytes ??
                                                                      1),
                                                          color: Colors
                                                              .white, // Loading indicator on black bg
                                                        ),
                                                      ),
                                                      // ... existing PhotoView errorBuilder ...
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Hero(
                                            tag:
                                                'complaint_image_${_complaintData['id']}',
                                            child: Image.network(
                                              _complaintData['image'],
                                              fit: BoxFit.cover,
                                              // Constraints moved to parent SizedBox
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  height:
                                                      200, // Placeholder height
                                                  alignment: Alignment.center,
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
                                                    color:
                                                        primaryColor, // Use primary color
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  height:
                                                      150, // Placeholder height
                                                  width: double.infinity,
                                                  alignment: Alignment.center,
                                                  color: Colors.grey
                                                      .shade200, // Lighter error bg
                                                  child: const Column(
                                                    // Icon and text for error
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                          color:
                                                              textSecondaryColor,
                                                          size: 40),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Failed to load image',
                                                        style: TextStyle(
                                                            color:
                                                                textSecondaryColor),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Center(
                                      child: Text(
                                        'Tap image to view full size', // Updated text
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              textSecondaryColor, // Use secondary color
                                          fontStyle: FontStyle.italic,
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
    );
  }

  // Updated _buildInfoRow to accept and use color parameters
  Widget _buildInfoRow(String title, String value, IconData icon,
      Color textPrimary, Color textSecondary, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor, // Use passed icon color (primaryColor)
        ),
        const SizedBox(width: 12), // Increased spacing
        Text(
          '$title:',
          style: TextStyle(
            fontWeight: FontWeight.w600, // Slightly bolder
            fontSize: 14,
            color: textSecondary, // Use secondary color for title
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: textPrimary, // Use primary text color for value
            ),
          ),
        ),
      ],
    );
  }
}
