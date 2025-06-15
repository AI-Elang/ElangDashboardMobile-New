import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class CheckinMitra extends StatefulWidget {
  final String partnerId;
  final String partnerName;

  const CheckinMitra({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<CheckinMitra> createState() => _CheckinMitraState();
}

class _CheckinMitraState extends State<CheckinMitra> {
  final _formKey = GlobalKey<FormState>(); // Still useful for image validation

  var baseURL = dotenv.env['baseURL'];

  // State variables
  File? _imageFile;
  Timer? _clearDataTimer;
  bool _isSending = false;
  final TextEditingController _notesController =
      TextEditingController(); // New controller

  // GPS related state
  double? _lockedLatitude;
  double? _lockedLongitude;
  bool _isFetchingInitialLocation = true;
  int _gpsInitialFetchAttempts = 0;
  bool _hasGpsAccess = false; // To track if GPS access was successful initially

  // Check if form is valid
  bool get _isFormValid {
    return _imageFile != null && _notesController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _checkRoleAndInitialize();
    _notesController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _checkRoleAndInitialize() async {
    // Defer context-dependent operations
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userRole = authProvider.role;

      if (![1, 2, 3, 4, 5].contains(userRole)) {
        // Updated role check
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Access Denied'),
            content:
                const Text('You do not have permission to access this page.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop(); // Close dialog
                  if (mounted) {
                    Navigator.of(context)
                        .pop(); // Go back from CheckinMitra page
                  }
                },
              ),
            ],
          ),
        );
      } else {
        // Proceed with GPS fetching and other initializations
        await _fetchInitialGpsLocation();
        _startClearDataTimer(); // Start timer when the page loads
      }
    });
  }

  @override
  void dispose() {
    _clearDataTimer?.cancel(); // Cancel timer when the page is disposed
    _notesController.dispose(); // Dispose the new controller
    super.dispose();
  }

  void _startClearDataTimer() {
    _clearDataTimer?.cancel();
    _clearDataTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        _clearImage(showSnackbar: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Image and notes cleared due to inactivity.')), // Updated message
        );
      }
    });
  }

  Future<void> _fetchInitialGpsLocation() async {
    if (!mounted) return;
    setState(() {
      _isFetchingInitialLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Location services are disabled. Please enable them.')));
        await Geolocator.openLocationSettings();
      }
      // Try again after user potentially enables it, or fail gracefully
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Location permissions are denied.')));
          setState(() {
            _lockedLatitude = 0.0;
            _lockedLongitude = 0.0;
            _isFetchingInitialLocation = false;
            _hasGpsAccess = false;
          });
          return;
        }
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')));
        setState(() {
          _lockedLatitude = 0.0;
          _lockedLongitude = 0.0;
          _isFetchingInitialLocation = false;
          _hasGpsAccess = false;
        });
      }
      return;
    }

    _gpsInitialFetchAttempts = 0;
    Position? currentPosition;

    while (_gpsInitialFetchAttempts < 3 && currentPosition == null) {
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 7), // Fast attempt
        );
        if (currentPosition.isMocked && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Mock location detected. Please disable mock locations.')),
          );
          currentPosition = null; // Invalidate mocked location
          // Optionally, set lat/long to 0 or handle as a failure
          _gpsInitialFetchAttempts = 3; // Force failure for mock
          break;
        }
      } catch (e) {
        // Handle timeout or other errors
      }
      _gpsInitialFetchAttempts++;
    }

    if (mounted) {
      setState(() {
        if (currentPosition != null) {
          _lockedLatitude = currentPosition.latitude;
          _lockedLongitude = currentPosition.longitude;
          _hasGpsAccess = true;
        } else {
          _lockedLatitude = 0.0;
          _lockedLongitude = 0.0;
          _hasGpsAccess = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to get location. Set to (0,0).')),
          );
        }
        _isFetchingInitialLocation = false;
      });
    }
  }

  Future<void> _pickAndEditImage() async {
    _startClearDataTimer(); // Reset timer on user interaction
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile;

    try {
      pickedFile = await picker.pickImage(
          source: ImageSource.camera); // Changed from ImageSource.gallery

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
                  CropAspectRatioPreset.ratio16x9,
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
          final File image = File(croppedFile.path);
          final int fileSize = await image.length(); // Get file size in bytes
          const int maxSizeInBytes = 5 * 1024 * 1024; // 5MB

          if (fileSize > maxSizeInBytes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Image size exceeds 5MB. Please select a smaller image.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            setState(() {
              _imageFile = image;
            });
          }
        }
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to pick image: ${e.message} (Code: ${e.code})')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while picking image: $e')),
      );
    }
  }

  void _clearImage({bool showSnackbar = false}) {
    setState(() {
      _imageFile = null;
      _notesController.clear(); // Clear the notes text field
    });
    _clearDataTimer?.cancel();
    if (showSnackbar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Image and notes cleared.')), // Updated message
      );
    }
    _startClearDataTimer(); // Restart timer after clearing
  }

  Future<void> _sendCheckinData() async {
    _clearDataTimer?.cancel();

    // Check form validation first
    if (!_isFormValid) {
      List<String> missingFields = [];
      if (_imageFile == null) missingFields.add('Image');
      if (_notesController.text.trim().isEmpty) missingFields.add('Notes');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${missingFields.join(' dan ')} belum terisi.'),
          backgroundColor: Colors.red,
        ),
      );
      _startClearDataTimer();
      return;
    }

    if (_isFetchingInitialLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, fetching location...')),
      );
      _startClearDataTimer();
      return;
    }

    if (_lockedLatitude == 0.0 && _lockedLongitude == 0.0 && !_hasGpsAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Cannot submit without a valid GPS location. Please ensure GPS is enabled and permissions are granted.')),
      );
      _startClearDataTimer();
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image.')),
      );
      _startClearDataTimer();
      return;
    }

    setState(() {
      _isSending = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final uri = Uri.parse('$baseURL/api/v1/mitra/detail/check-in');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['partner_id'] = widget.partnerId;
    request.fields['partner_name'] = widget.partnerName;
    request.fields['latitude_checkin'] = _lockedLatitude.toString();
    request.fields['longitude_checkin'] = _lockedLongitude.toString();
    request.fields['description'] = _notesController.text;

    request.files.add(
      await http.MultipartFile.fromPath('image', _imageFile!.path),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isSending = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final message = responseData['meta']?['message'] ??
            'Check-in submitted successfully!';

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _clearImage(); // Clear image after successful submission
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );
      } else {
        String errorMessage =
            'Failed to submit check-in. Status code: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
          if (errorData['errors'] != null && errorData['errors'] is Map) {
            final errors = errorData['errors'] as Map;
            errors.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errorMessage += '\n- ${value.first}';
              }
            });
          }
        } catch (e) {
          errorMessage += '\nResponse: ${response.body}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 4)),
        );
        _startClearDataTimer();
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending check-in: ${e.toString()}')),
      );
      _startClearDataTimer();
    }
  }

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
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    // final mediaQueryWidth = MediaQuery.of(context).size.width; // Less used now
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;
    final territory = authProvider.territory;

    // Define color scheme - matching complain_add.dart style (from checkin_mitra.dart)
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    // If role check is pending or denied, show minimal UI or loading
    if (![1, 2, 3, 4, 5].contains(role) && !_isFetchingInitialLocation) {
      return const Scaffold(body: Center(child: Text("Verifying access...")));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // App header with gradient background - matching complain_add.dart
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
                          'INPUT CHECK-IN MITRA', // Changed title
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
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
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: backgroundColor, // Use background color
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                            10), // Optional: if you want rounded corners from header
                        topRight: Radius.circular(10), // Optional
                      ),
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO3.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08, // Adjusted opacity
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header Section (User Profile Card) - styled like complain_add.dart
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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

                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              top: 8.0, // Adjusted top padding
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom + 20,
                            ),
                            child: Form(
                              key: _formKey,
                              onChanged:
                                  _startClearDataTimer, // Reset timer on any form interaction
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Partner Info Card
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
                                          const Text("Partner Information",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimaryColor)),
                                          const SizedBox(height: 12),
                                          Text("ID: ${widget.partnerId}",
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: textSecondaryColor)),
                                          const SizedBox(height: 6),
                                          Text("Name: ${widget.partnerName}",
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: textSecondaryColor)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // GPS Location Info Card
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
                                          const Text("Check-in Location",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimaryColor)),
                                          const SizedBox(height: 12),
                                          _isFetchingInitialLocation
                                              ? const Row(children: [
                                                  SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: primaryColor,
                                                      )),
                                                  SizedBox(width: 10),
                                                  Text("Fetching location...",
                                                      style: TextStyle(
                                                          color:
                                                              textSecondaryColor))
                                                ])
                                              : Text(
                                                  "Lat: ${_lockedLatitude?.toStringAsFixed(6) ?? 'N/A'}, Long: ${_lockedLongitude?.toStringAsFixed(6) ?? 'N/A'}",
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          textSecondaryColor)),
                                          if (!_isFetchingInitialLocation &&
                                              (_lockedLatitude == 0.0 &&
                                                  _lockedLongitude == 0.0 &&
                                                  !_hasGpsAccess))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                "GPS signal not found or permission denied. Location set to (0,0).",
                                                style: TextStyle(
                                                    color: Colors.red.shade700,
                                                    fontSize: 12),
                                              ),
                                            )
                                        ],
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
                                          const Row(
                                            children: [
                                              Text('Check-in Image',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                              Text(' *',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.red)),
                                            ],
                                          ),
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

                                  // Notes Text Field Card
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
                                          const Row(
                                            children: [
                                              Text("Notes",
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                              Text(' *',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.red)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _notesController,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Enter any notes here...',
                                              hintStyle: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 14),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color:
                                                        Colors.grey.shade300),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color:
                                                        Colors.grey.shade300),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color: primaryColor
                                                        .withOpacity(0.7),
                                                    width: 1.5),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10),
                                            ),
                                            maxLines: 3,
                                            style: const TextStyle(
                                                color: textPrimaryColor,
                                                fontSize: 14),
                                            onChanged: (_) =>
                                                _startClearDataTimer(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Send Button
                                  ElevatedButton(
                                    onPressed:
                                        _isSending || _isFetchingInitialLocation
                                            ? null
                                            : _sendCheckinData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFormValid
                                          ? primaryColor // Use primary color
                                          : Colors.grey, // Disabled color
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
                                        : const Text('Submit Check-in'),
                                  ),
                                  const SizedBox(height: 8),

                                  // Clear Button
                                  Center(
                                    child: TextButton(
                                      onPressed: () =>
                                          _clearImage(showSnackbar: true),
                                      child: const Text('Clear Image',
                                          style: TextStyle(
                                              color: textSecondaryColor)),
                                    ),
                                  ),
                                  const SizedBox(height: 20), // Bottom padding
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
