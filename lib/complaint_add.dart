import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for PlatformException
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class NewComplaint extends StatefulWidget {
  const NewComplaint({super.key});

  @override
  State<NewComplaint> createState() => _NewComplaintState();
}

class _NewComplaintState extends State<NewComplaint> {
  final _formKey = GlobalKey<FormState>();
  var baseURL = dotenv.env['baseURL'];

  // State variables
  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  File? _imageFile;
  final TextEditingController _detailController = TextEditingController();
  bool _isLoadingCategories = false;
  bool _isSending = false;
  Timer? _clearDataTimer;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    // You might want to load saved data here if implementing persistence across app restarts
    _startClearDataTimer(); // Start timer when the page loads
  }

  @override
  void dispose() {
    _detailController.dispose();
    _clearDataTimer?.cancel(); // Cancel timer when the page is disposed
    super.dispose();
  }

  // Start or reset the 5-minute timer
  void _startClearDataTimer() {
    _clearDataTimer?.cancel(); // Cancel any existing timer
    _clearDataTimer = Timer(const Duration(minutes: 5), () {
      // Clear form data after 5 minutes of inactivity
      if (mounted) {
        // Check if the widget is still in the tree
        _clearForm(showSnackbar: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form data cleared due to inactivity.')),
        );
      }
    });
  }

  // Fetch complaint categories
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      final response = await http.get(
        Uri.parse('$baseURL/api/v1/complaints/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        setState(() {
          _categories = data is List ? data : [data];
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _isLoadingCategories = false;
          _categories = []; // Clear categories on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load complaint categories')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _categories = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: ${e.toString()}')),
      );
    }
  }

  // Pick image from gallery and crop it
  Future<void> _pickAndEditImage() async {
    _startClearDataTimer(); // Reset timer on user interaction
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile;

    try {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
                aspectRatioPresets: [
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9
                ],
                toolbarTitle: 'Crop Image',
                toolbarColor: Colors.blue,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: false),
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _imageFile = File(croppedFile.path);
          });
        }
      }
    } on PlatformException catch (e) {
      // Handle the platform exception specifically
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to pick image: ${e.message} (Code: ${e.code})')),
      );
    } catch (e) {
      // Handle other potential errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while picking image: $e')),
      );
    }
  }

  // Clear form data
  void _clearForm({bool showSnackbar = false}) {
    setState(() {
      _selectedCategoryId = null;
      _imageFile = null;
      _detailController.clear();
      _formKey.currentState?.reset(); // Reset validation state
    });
    _clearDataTimer?.cancel(); // Stop timer after clearing
    if (showSnackbar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form cleared.')),
      );
    }
  }

  // Send complaint data to API
  Future<void> _sendComplaint() async {
    _clearDataTimer?.cancel(); // Stop timer during submission attempt

    // Validate form
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      _startClearDataTimer(); // Restart timer if validation fails
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image.')),
      );
      _startClearDataTimer(); // Restart timer if validation fails
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _startClearDataTimer(); // Restart timer if validation fails
      return; // Validation failed for the detail field
    }

    setState(() {
      _isSending = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final uri = Uri.parse('$baseURL/api/v1/complaints');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] =
        'application/json'; // Important for API response

    // Add form fields
    request.fields['category_id'] = _selectedCategoryId!;
    request.fields['detail'] = _detailController.text;

    // Add image file
    request.files.add(
      await http.MultipartFile.fromPath(
        'image', // This key must match the API expectation (e.g., 'image')
        _imageFile!.path,
        // You might need to specify filename and content type depending on the API
        // filename: _imageFile!.path.split('/').last,
        // contentType: MediaType('image', 'jpeg'), // Adjust content type if needed
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isSending = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle 201 Created as well
        final responseData = json.decode(response.body);
        final message = responseData['meta']?['message'] ??
            'Complaint submitted successfully!';

        showDialog(
          context: context,
          barrierDismissible: false, // User must tap button to close
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _clearForm(); // Clear form after successful submission
                    Navigator.of(context)
                        .pop(); // Go back to the previous screen (Complain page)
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Attempt to parse error message from API response
        String errorMessage =
            'Failed to submit complaint. Status code: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
          // Check for specific validation errors if the API provides them
          if (errorData['errors'] != null && errorData['errors'] is Map) {
            final errors = errorData['errors'] as Map;
            errors.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errorMessage += '\n- ${value.first}';
              }
            });
          }
        } catch (e) {
          // Could not parse JSON, use raw body or default message
          errorMessage += '\nResponse: ${response.body}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 4)),
        );
        _startClearDataTimer(); // Restart timer on failure
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending complaint: ${e.toString()}')),
      );
      _startClearDataTimer(); // Restart timer on failure
    }
  }

  // Copied from complain.dart
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

  @override
  Widget build(BuildContext context) {
    // Get values needed for the header UI
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    // final mediaQueryWidth = MediaQuery.of(context).size.width; // Less used now
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;
    final territory = authProvider.territory;

    // Define color scheme - matching complain.dart style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    return Scaffold(
      // Set resizeToAvoidBottomInset to false to prevent background movement
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor, // Use background color
      body: SafeArea(
        child: Stack(
          // Use Stack for bottom navigation bar overlay
          children: [
            Column(
              children: [
                // App header with gradient background - matching complain.dart
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
                  child: Stack(
                    // Use Stack to overlay back button
                    children: [
                      const Center(
                        child: Text(
                          'NEW COMPLAINT',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Optional: Add a back button
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Back',
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: backgroundColor, // Use background color
                      // Keep background image consistent with complain.dart
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08, // Adjusted opacity
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      // Main column for header and form
                      children: [
                        // Header Section (User Profile Card) - styled like complain.dart
                        Padding(
                          // Add padding around the card
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
                                  // Date info - styled like complain.dart
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
                        ),
                        // const SizedBox(height: 10), // Spacing adjusted by card margins

                        // Form Content Area
                        Expanded(
                          // Make the form scrollable and take remaining space
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Form(
                              key: _formKey,
                              onChanged: _startClearDataTimer,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Category Dropdown Card
                                  Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    color: cardColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: _isLoadingCategories
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : DropdownButtonFormField<String>(
                                              value: _selectedCategoryId,
                                              hint: const Text(
                                                  'Select Complaint Category',
                                                  style: TextStyle(
                                                      color:
                                                          textSecondaryColor)),
                                              isExpanded: true,
                                              items: _categories.map<
                                                      DropdownMenuItem<String>>(
                                                  (category) {
                                                return DropdownMenuItem<String>(
                                                  value:
                                                      category['id'].toString(),
                                                  child: Text(
                                                      category['name'] ??
                                                          'Unnamed Category',
                                                      style: const TextStyle(
                                                          color:
                                                              textPrimaryColor)),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _selectedCategoryId =
                                                      newValue;
                                                });
                                                _startClearDataTimer(); // Reset timer
                                              },
                                              validator: (value) => value ==
                                                      null
                                                  ? 'Please select a category'
                                                  : null,
                                              decoration: InputDecoration(
                                                labelText: 'Category',
                                                labelStyle: const TextStyle(
                                                    color: textSecondaryColor),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade300),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade300),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: const BorderSide(
                                                      color: primaryColor),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 15),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Image Picker/Viewer Card
                                  Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    color: cardColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Complaint Image',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimaryColor)),
                                          const SizedBox(height: 12),
                                          Center(
                                            child: _imageFile == null
                                                ? Container(
                                                    height: 150,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade300),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: Colors.grey[50],
                                                    ),
                                                    child: const Center(
                                                        child: Text(
                                                            'No Image Selected',
                                                            style: TextStyle(
                                                                color:
                                                                    textSecondaryColor))),
                                                  )
                                                : Container(
                                                    height: 200,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      image: DecorationImage(
                                                        image: FileImage(
                                                            _imageFile!),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(height: 12),
                                          Center(
                                            child: ElevatedButton.icon(
                                              onPressed: _pickAndEditImage,
                                              icon: const Icon(Icons.edit,
                                                  size: 18),
                                              label: Text(
                                                  _imageFile == null
                                                      ? 'Select & Edit Image'
                                                      : 'Change Image',
                                                  style: const TextStyle(
                                                      fontSize: 13)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    primaryColor.withOpacity(
                                                        0.1), // Lighter primary
                                                foregroundColor:
                                                    primaryColor, // Primary text
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Detail Text Field Card
                                  Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    color: cardColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: TextFormField(
                                        controller: _detailController,
                                        decoration: InputDecoration(
                                          labelText: 'Complaint Details',
                                          labelStyle: const TextStyle(
                                              color: textSecondaryColor),
                                          hintText: 'Describe the issue...',
                                          hintStyle: const TextStyle(
                                              color: textSecondaryColor),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: primaryColor),
                                          ),
                                          alignLabelWithHint: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 15),
                                        ),
                                        style: const TextStyle(
                                            color: textPrimaryColor),
                                        maxLines: 5,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter complaint details';
                                          }
                                          return null;
                                        },
                                        onTap: _startClearDataTimer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Send Button
                                  ElevatedButton(
                                    onPressed:
                                        _isSending ? null : _sendComplaint,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          primaryColor, // Use primary color
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: _isSending
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Text('Send Complaint'),
                                  ),
                                  const SizedBox(height: 8),
                                  // Clear Button
                                  Center(
                                    child: TextButton(
                                      onPressed: () =>
                                          _clearForm(showSnackbar: true),
                                      child: const Text('Clear Form',
                                          style: TextStyle(
                                              color: textSecondaryColor)),
                                    ),
                                  ),
                                  const SizedBox(
                                      height:
                                          80), // Add padding at the bottom for nav bar
                                ],
                              ),
                            ),
                          ),
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
    );
  }
}
