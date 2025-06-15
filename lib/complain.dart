import 'package:elang_dashboard_new_ui/complaint_detail.dart';
import 'package:elang_dashboard_new_ui/complaint_add.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'dart:convert';

class Complain extends StatefulWidget {
  const Complain({super.key});

  @override
  State<Complain> createState() => _ComplainState();
}

// Add WidgetsBindingObserver
class _ComplainState extends State<Complain> with WidgetsBindingObserver {
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

  var baseURL = dotenv.env['baseURL'];

  // New variables for date picker and complaints
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _complaints = [];
  bool _isLoadingComplaints = false;

  // Format date for display (29 Desember 2026)
  String _formatDateForDisplay(DateTime date) {
    // Using Indonesian month names
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Format date for API (yyyy-mm-dd)
  String _formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Show date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Set loading true immediately for better UX
        _isLoadingComplaints = true;
        _complaints = []; // Clear previous complaints immediately
      });

      // Fetch complaints for the selected date (already correctly placed)
      _fetchComplaints();
    }
  }

  // Fetch complaints from API
  Future<void> _fetchComplaints() async {
    // Store the current loading state to check later if it was the initial load
    final bool wasLoading = _isLoadingComplaints;
    // Only set loading state if not already loading
    if (!wasLoading) {
      // Check mount status before calling setState
      if (mounted) {
        setState(() {
          _isLoadingComplaints = true;
        });
      } else {
        // If not mounted, don't proceed with the fetch
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final dateParam = _formatDateForApi(_selectedDate);

    try {
      final response = await http.get(
        Uri.parse('$baseURL/api/v1/complaints?date=$dateParam'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Check if the widget is still mounted before processing the response
      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> newData = responseData.containsKey('data')
            ? (responseData['data'] is List
                ? responseData['data']
                : [responseData['data']])
            : (responseData is List
                ? responseData
                : [responseData]); // Ensure newData is always a List

        // Compare new data with existing data using JSON strings
        final String currentDataJson = json.encode(_complaints);
        final String newDataJson = json.encode(newData);

        // Only update state if data is different or if it was the initial load/refresh trigger
        if (currentDataJson != newDataJson || wasLoading) {
          setState(() {
            _complaints = newData;
            _isLoadingComplaints = false;
          });
        } else {
          // Data is the same, just ensure loading indicator is turned off if it was on
          if (_isLoadingComplaints) {
            setState(() {
              _isLoadingComplaints = false;
            });
          }
        }
      } else {
        // Handle error: Only update state if it was loading
        if (_isLoadingComplaints) {
          setState(() {
            _isLoadingComplaints = false;
            _complaints = []; // Clear complaints on error
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load complaints'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Handle error: Only update state if it was loading
      if (_isLoadingComplaints) {
        setState(() {
          _isLoadingComplaints = false;
          _complaints = []; // Clear complaints on error
        });
      }
      // Avoid showing snackbar if context is no longer valid
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
    _fetchComplaints(); // Initial fetch
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    super.dispose();
  }

  // Add didChangeAppLifecycleState
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Fetch complaints when app is resumed
      _fetchComplaints();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define color scheme - matching search.dart style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor, // Use background color
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // App header with gradient background - matching search.dart
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
                        'COMPLAIN',
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
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: backgroundColor, // Use background color
                      // Keep background image if desired, adjust opacity/alignment
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO3.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08, // Adjusted opacity
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    // Remove SingleChildScrollView, use Column + Expanded for list
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        // Main column for content
                        children: [
                          // User Profile Section (Non-scrollable)
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          AssetImage('assets/LOGO3.png'),
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
                                            fontSize: 11, // Adjusted size
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
                                            fontSize: 14, // Adjusted size
                                            fontWeight: FontWeight.bold,
                                            color: textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Date info - styled like search.dart
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
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
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Add Complaint Button Card (Non-scrollable)
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const NewComplaint()),
                                    ).then((_) {
                                      _fetchComplaints();
                                    });
                                  },
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text(
                                    'Add Complaint',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        primaryColor, // Use primary color
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0, // Consistent elevation
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Date Picker and Title Card (Non-scrollable)
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
                                  // Title
                                  const Text(
                                    'All Complaints',
                                    style: TextStyle(
                                      fontSize: 16, // Adjusted size
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor, // Use primary color
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Date Picker Container
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors
                                            .white, // Keep white or use backgroundColor
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12
                                                .withOpacity(0.05),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                        border: Border.all(
                                            color: Colors.grey
                                                .shade200) // Optional subtle border
                                        ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Select Date:',
                                          style: TextStyle(
                                            fontSize: 12, // Adjusted size
                                            fontWeight: FontWeight.w600,
                                            color: textPrimaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () => _selectDate(context),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey
                                                      .shade300), // Lighter border
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8), // Rounded corners
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDateForDisplay(
                                                      _selectedDate),
                                                  style: const TextStyle(
                                                      fontSize:
                                                          14, // Adjusted size
                                                      color: textPrimaryColor),
                                                ),
                                                const Icon(
                                                  Icons.calendar_today,
                                                  color:
                                                      primaryColor, // Use primary color
                                                  size: 20, // Adjusted size
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // List is moved outside this card
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 4), // Space before the list

                          // Scrollable Complaints List Area
                          Expanded(
                            child: _isLoadingComplaints
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: primaryColor))
                                : _complaints.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                              24.0), // Add padding for empty message
                                          child: Text(
                                            'No complaints found for ${_formatDateForDisplay(_selectedDate)}',
                                            style: const TextStyle(
                                              fontSize: 14, // Adjusted size
                                              fontStyle: FontStyle.italic,
                                              color: textSecondaryColor,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    // Pass colors to the list builder
                                    : _buildComplaintList(primaryColor,
                                        textPrimaryColor, textSecondaryColor),
                          ),
                          const SizedBox(
                            height: 60,
                          ), // Space before the list
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Bottom navigation bar - styled like search.dart
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60, // Consistent height
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the single item
                  children: [
                    // Use the same builder function as search.dart for consistency
                    _buildBottomNavItem(
                        Icons.home, 'Home', false, primaryColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the complaint list items with new styling
  Widget _buildComplaintList(
      Color primaryColor, Color textPrimaryColor, Color textSecondaryColor) {
    // This ListView.builder is now directly inside an Expanded widget
    return ListView.builder(
      itemCount: _complaints.length,
      itemBuilder: (context, index) {
        final complaint = _complaints[index];
        // Use Card for each item - similar to search results
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1, // Subtle elevation
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
              side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 0.5) // Optional subtle border
              ),
          color: Colors.white,
          child: InkWell(
            // Make the whole card tappable
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (complaint['id'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComplaintDetail(
                      complaintId: complaint['id'].toString(),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Cannot view details: Complaint ID not found'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Row(
                // Use Row for better alignment with icon
                children: [
                  // Optional: Add an icon based on category or status
                  // Icon(Icons.report_problem_outlined, color: primaryColor, size: 24),
                  // SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: ${complaint['id'] ?? 'N/A'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15, // Adjusted size
                            color: textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Category: ${complaint['category_name'] ?? 'Not Specified'}',
                          style: TextStyle(
                            fontSize: 13, // Adjusted size
                            color: textPrimaryColor.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Submitted by: ${complaint['username'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 11, // Adjusted size
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    // Trailing icon
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: textSecondaryColor.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Bottom Navigation Item builder - copied from search.dart for consistency
  Widget _buildBottomNavItem(
      IconData icon, String label, bool isActive, Color primaryColor) {
    return InkWell(
      onTap: () {
        if (label == 'Home') {
          // Avoid pushing if already on the home-related page (Complain is not Home)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Homepage()),
          );
        }
        // Add other navigation logic if needed
      },
      // Add padding to increase tap area if needed
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Important for centering
          children: [
            Icon(
              icon,
              color: primaryColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: primaryColor,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
