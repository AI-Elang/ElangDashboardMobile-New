import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:html_unescape/html_unescape.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';

class ExportDoc extends StatefulWidget {
  const ExportDoc({super.key});

  @override
  State<ExportDoc> createState() => _ExportDocState();
}

class _ExportDocState extends State<ExportDoc> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

  String? _selectedDropdown1 = 'Circle Java';
  String? _selectedDropdown2 = 'ALL';
  String? _selectedDropdown3 = 'ALL';
  String? _selectedDropdown4 = 'ALL';
  String? _selectedDropdown5 = 'ALL';
  String? _selectedCategory = 'DSE AI';

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _notificationId = 0;
  bool _isFiltersCollapsed = false; // Initially expanded

  String sanitizeInput(String input) {
    // Remove HTML tags and scripts
    var sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    // Escape special characters
    var unescape = HtmlUnescape();
    sanitized = unescape.convert(sanitized);
    // Limit length to prevent overflow attacks
    return sanitized
        .trim()
        .substring(0, sanitized.length > 100 ? 100 : sanitized.length);
  }

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _subRegions = [];
  List<Map<String, dynamic>> _subAreas = [];
  List<Map<String, dynamic>> _mcList = [];

  var baseURL = dotenv.env['baseURL'];

  bool _isDropdownLocked(int dropdownNumber) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.role == 5) {
      return dropdownNumber <= 5; // Locks dropdowns 1-5
    } else if (authProvider.role == 4) {
      return dropdownNumber <= 4; // Locks dropdowns 1-4
    } else if (authProvider.role == 3) {
      return dropdownNumber <= 3; // Locks dropdowns 1-3
    } else if (authProvider.role == 2) {
      return dropdownNumber <= 2; // Locks dropdowns 1-2
    } else if (authProvider.role == 1) {
      return dropdownNumber == 1; // Only locks dropdown 1 for role 1
    }
    return false; // No locks for other roles
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          debugPrint('Notification payload: $payload');
          await OpenFile.open(payload);
        }
      },
    );
  }

  // Show download progress notification
  Future<void> _showProgressNotification(double progress) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel',
      'File Downloads',
      channelDescription: 'Notifications for file downloads',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: (progress * 100).toInt(),
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      _notificationId,
      'Downloading',
      '${(progress * 100).toInt()}%',
      platformChannelSpecifics,
    );
  }

  // Show download complete notification
  Future<void> _showCompleteNotification(String filePath) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel',
      'File Downloads',
      channelDescription: 'Notifications for file downloads',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      _notificationId,
      'Download Complete',
      'File saved to ElangDashboardDocument. Tap to open.',
      platformChannelSpecifics,
      payload: filePath,
    );

    // Log the file path for debugging
    debugPrint('Notification payload: $filePath');
  }

  // Request storage permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.mediaLibrary,
        Permission.manageExternalStorage,
      ].request();

      // Log all permission statuses
      statuses.forEach((permission, status) {
        debugPrint('Permission $permission: $status');
      });

      // For Android 10+, we need to request special access for all files
      if (statuses[Permission.manageExternalStorage]?.isGranted == true) {
        debugPrint('MANAGE_EXTERNAL_STORAGE permission granted');
        return true;
      }

      // For older Android versions, storage permission is enough
      if (statuses[Permission.storage]?.isGranted == true) {
        debugPrint('STORAGE permission granted');
        return true;
      }

      debugPrint('No required permissions were granted');
      return false;
    }
    return true;
  }

  // Create download directory
  Future<Directory?> _createDownloadDirectory() async {
    try {
      // Use public Downloads directory for better accessibility
      if (Platform.isAndroid) {
        // First try the public downloads directory
        final publicDir =
            Directory('/storage/emulated/0/Download/ElangDashboardDocument');

        // If this approach fails, try the fallback
        try {
          if (!(await publicDir.exists())) {
            await publicDir.create(recursive: true);
          }
          debugPrint('Created public directory at: ${publicDir.path}');
          return publicDir;
        } catch (e) {
          debugPrint('Failed to create public directory: $e');
        }

        // Second approach: try a new method for public Downloads folder
        try {
          final downloadsDir =
              Directory('/storage/emulated/0/ElangDashboardDocument');
          if (!(await downloadsDir.exists())) {
            await downloadsDir.create(recursive: true);
          }
          debugPrint('Created directory at root: ${downloadsDir.path}');
          return downloadsDir;
        } catch (e) {
          debugPrint('Failed to create root directory: $e');
        }
      }

      // Fallback to app-specific directories if the above methods fail
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final appDir =
              Directory('${externalDir.path}/ElangDashboardDocument');
          if (!(await appDir.exists())) {
            await appDir.create(recursive: true);
          }
          debugPrint('Using app-specific directory: ${appDir.path}');
          return appDir;
        }
      } catch (e) {
        debugPrint('Failed to create app-specific directory: $e');
      }

      // Last resort: app documents directory
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final lastResortDir =
            Directory('${appDocDir.path}/ElangDashboardDocument');
        if (!(await lastResortDir.exists())) {
          await lastResortDir.create(recursive: true);
        }
        debugPrint('Using last resort directory: ${lastResortDir.path}');
        return lastResortDir;
      } catch (e) {
        debugPrint('All directory creation attempts failed: $e');
        return null;
      }
    } catch (e) {
      debugPrint('Error in _createDownloadDirectory: $e');
      return null;
    }
  }

  // Download Excel file
  Future<void> _downloadExcelFile() async {
    if (_startDate == null || _endDate == null) {
      _showErrorDialog('Please select both start and end dates.');
      return;
    }

    if (_selectedCategory == null) {
      _showErrorDialog('Please select a category.');
      return;
    }

    // Check if any required dropdown is not selected
    if (_selectedDropdown1 == null ||
        _selectedDropdown2 == null ||
        _selectedDropdown3 == null ||
        _selectedDropdown4 == null ||
        _selectedDropdown5 == null) {
      String missingDropdown = '';
      if (_selectedDropdown1 == null) {
        missingDropdown = 'Circle';
      } else if (_selectedDropdown2 == null) {
        missingDropdown = 'Region';
      } else if (_selectedDropdown3 == null) {
        missingDropdown = 'Area';
      } else if (_selectedDropdown4 == null) {
        missingDropdown = 'Branch';
      } else if (_selectedDropdown5 == null) {
        missingDropdown = 'MC';
      }

      _showErrorDialog('Data $missingDropdown belum dipilih.');
      return;
    }

    // Request permissions
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      _showErrorDialog('Storage permission denied. Cannot download file.');
      return;
    }

    // Create download directory
    final downloadDir = await _createDownloadDirectory();
    if (downloadDir == null) {
      _showErrorDialog(
          'Could not create download directory. Please check your storage permissions.');
      return;
    }

    // Log directory information
    debugPrint('Using download directory: ${downloadDir.path}');

    // Start download
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    // Show initial progress notification
    _notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _showProgressNotification(0.0);

    // Format dates for API
    final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate!);

    // Get circle, region, area, branch, and mc IDs
    const circleId = 1; // Assuming Circle Java is always ID 1

    final regionId = _selectedDropdown2 == 'ALL'
        ? 0
        : _regions.firstWhere((r) => r['name'] == _selectedDropdown2,
                orElse: () => {'id': 0})['id'] ??
            0;

    final areaId = _selectedDropdown3 == 'ALL'
        ? 0
        : _subRegions.firstWhere((a) => a['name'] == _selectedDropdown3,
                orElse: () => {'id': 0})['id'] ??
            0;

    final branchId = _selectedDropdown4 == 'ALL'
        ? 0
        : _subAreas.firstWhere((b) => b['name'] == _selectedDropdown4,
                orElse: () => {'id': 0})['id'] ??
            0;

    final mcId = _selectedDropdown5 == 'ALL'
        ? 0
        : _mcList.firstWhere((m) => m['name'] == _selectedDropdown5,
                orElse: () => {'id': 0})['id'] ??
            0;

    // Construct API URL
    String categoryParam = '';
    if (_selectedCategory == 'DSE AI') {
      categoryParam = 'dse_ai';
    } else if (_selectedCategory == 'DSE') {
      categoryParam = 'dse';
    } else if (_selectedCategory == 'Site') {
      categoryParam = 'site';
    } else if (_selectedCategory == 'Mitra') {
      categoryParam = 'mitra';
    }

    final url =
        '$baseURL/api/v1/export/excel?category=$categoryParam&start_date=$startDateStr&end_date=$endDateStr&circle=$circleId&region=$regionId&area=$areaId&branch=$branchId&mc=$mcId';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      // Create file name with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'export_${categoryParam}_$timestamp.xlsx';
      final filePath = '${downloadDir.path}/$fileName';
      debugPrint('Will save file to: $filePath');

      // Show a toast to inform the user where we'll save the file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading to ${downloadDir.path}'),
          duration: const Duration(seconds: 3),
        ),
      );

      // Use Dio for better download handling and progress tracking
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            setState(() {
              _downloadProgress = progress;
            });
            _showProgressNotification(progress);
          }
        },
      );

      // Verify file was created
      final file = File(filePath);
      if (await file.exists()) {
        debugPrint('File successfully saved to: $filePath');

        // Show complete notification
        await _showCompleteNotification(filePath);

        // Show snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download Complete'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _showErrorDialog(
            'File download appeared to succeed but the file was not found');
      }
    } catch (e) {
      _showErrorDialog('Error');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // REGION DATA (Dropdown 2)
  Future<void> fetchRegions(String? token) async {
    final url = '$baseURL/api/v1/dropdown/get-region-dashboard?circle=1';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> regionsData = data['data'];

        setState(() {
          _regions = regionsData
              .map((region) => {'id': region['id'], 'name': region['name']})
              .toList();
          // Tambahkan 'ALL' sebagai pilihan pertama
          _regions.insert(0, {'id': null, 'name': 'ALL'});
          _selectedDropdown2 =
              _regions.isNotEmpty ? _regions[0]['name'] : 'ALL';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to load regions: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error fetching data')));
    }
  }

  // AREA DATA (Dropdown 3)
  Future<void> fetchSubRegions(int regionId, String? token) async {
    final url =
        '$baseURL/api/v1/dropdown/get-region-dashboard?circle=1&region=$regionId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> subRegionsData = data['data'];

        setState(() {
          _subRegions = subRegionsData
              .map((subRegion) =>
                  {'id': subRegion['id'], 'name': subRegion['name']})
              .toList();
          // Tambahkan 'ALL' sebagai pilihan pertama
          _subRegions.insert(0, {'id': null, 'name': 'ALL'});
          _selectedDropdown3 =
              _subRegions.isNotEmpty ? _subRegions[0]['name'] : 'ALL';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Failed to load sub-regions: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error fetching data')));
    }
  }

  // BRANCH DATA (Dropdown 4)
  Future<void> fetchAreas(int regionId, int subRegionId, String? token) async {
    final url =
        '$baseURL/api/v1/dropdown/get-region-dashboard?circle=1&region=$regionId&area=$subRegionId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> areasData = data['data'];

        setState(() {
          _subAreas = areasData
              .map((area) => {'id': area['id'], 'name': area['name']})
              .toList();
          // Tambahkan 'ALL' sebagai pilihan pertama
          _subAreas.insert(0, {'id': null, 'name': 'ALL'});
          _selectedDropdown4 =
              _subAreas.isNotEmpty ? _subAreas[0]['name'] : 'ALL';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to load areas: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error fetching data')));
    }
  }

  // MC DATA (Dropdown 5)
  Future<void> fetchMC(int circleId, int regionId, int areaId, int branchId,
      String? token) async {
    final url =
        '$baseURL/api/v1/dropdown/get-region-dashboard?circle=$circleId&region=$regionId&area=$areaId&branch=$branchId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> mcData = data['data'];

        setState(() {
          _mcList = mcData
              .map((mc) => {
                    'id': mc['id'],
                    'id_secondary': mc['id_secondary'],
                    'name': mc['name'],
                    'display_name': '${mc['name']} (${mc['id']})'
                  })
              .toList();

          // Add 'ALL' as first option
          _mcList.insert(0, {
            'id': null,
            'id_secondary': null,
            'name': 'ALL',
            'display_name': 'ALL'
          });

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.mc != 0) {
            final mcEntry = _mcList.firstWhere(
                (mc) => mc['id'] == authProvider.mc,
                orElse: () => _mcList[0]);
            _selectedDropdown5 = mcEntry['name'];
          } else {
            _selectedDropdown5 = _mcList[0]['name'];
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to load MCs: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error fetching data')));
    }
  }

  // LOCKED DROPDOWNS
  Future<void> _initializeLockedDropdowns() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    await authProvider.fetchLockedDropdown();

    if (!mounted) return;

    setState(() {
      _selectedDropdown1 = 'Circle Java';
    });

    // Initialize region dropdown dan tunggu sampai selesai
    await fetchRegions(token);
    if (!mounted) return;

    setState(() {
      final regionName = _regions.firstWhere(
          (r) => r['id'] == authProvider.region,
          orElse: () => {'id': null, 'name': 'ALL'})['name'];
      _selectedDropdown2 = regionName;
    });

    // Initialize area dropdown jika ada region
    if (authProvider.region != 0) {
      await fetchSubRegions(authProvider.region, token);
      if (!mounted) return;

      setState(() {
        final areaName = _subRegions.firstWhere(
            (a) => a['id'] == authProvider.area,
            orElse: () => {'id': null, 'name': 'ALL'})['name'];
        _selectedDropdown3 = areaName;
      });

      // Initialize branch dropdown jika ada area
      if (authProvider.area != 0) {
        await fetchAreas(authProvider.region, authProvider.area, token);
        if (!mounted) return;

        setState(() {
          final branchName = _subAreas.firstWhere(
              (b) => b['id'] == authProvider.branch,
              orElse: () => {'id': null, 'name': 'ALL'})['name'];
          _selectedDropdown4 = branchName;
        });

        // Initialize MC dropdown jika ada branch
        if (authProvider.branch != 0) {
          await fetchMC(authProvider.circle, authProvider.region,
              authProvider.area, authProvider.branch, token);
          if (!mounted) return;

          setState(() {
            final mcData = _mcList.firstWhere(
                (mc) => mc['id'] == authProvider.mc,
                orElse: () => {'id': null, 'name': 'ALL'});
            _selectedDropdown5 = mcData['name'];
          });
        }
      }
    }
  }

  // Select date helper
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestPermissions(); // Request permissions on init

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.role >= 1 && authProvider.role <= 5) {
        _initializeLockedDropdowns();
      } else {
        fetchRegions(token);
      }

      // Pre-create the directory to avoid issues during download
      _createDownloadDirectory().then((dir) {
        if (dir == null) {
          debugPrint('Warning: Could not pre-create download directory');
        } else {
          debugPrint('Download directory created: ${dir.path}');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define our color scheme - matching dse.dart style
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // App header with gradient background
            Column(
              children: [
                // Header container
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
                                'EXPORT EXCEL',
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
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color:
                          backgroundColor, // Use the defined background color
                      image: DecorationImage(
                        image: AssetImage('assets/LOGO3.png'),
                        fit: BoxFit.cover,
                        opacity: 0.08,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(
                          bottom: 70), // Space for bottom nav
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // User Profile & Filters Card
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: cardColor,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    // User info row
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  accentColor.withOpacity(0.6),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const CircleAvatar(
                                            radius: 30,
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
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    // Filters section with collapsible functionality
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
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
                                                      ? 0.25
                                                      : 0,
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
                                        AnimatedCrossFade(
                                          firstChild: const SizedBox(
                                            height: 0,
                                            width: double.infinity,
                                          ),
                                          secondChild: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: backgroundColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                          child:
                                                              _buildFilterDropdown(
                                                        "Circle",
                                                        _selectedDropdown1 ??
                                                            'Circle Java',
                                                        _isDropdownLocked(1),
                                                        (value) {
                                                          setState(() {
                                                            _selectedDropdown1 =
                                                                value;
                                                          });
                                                        },
                                                        ['Circle Java'],
                                                      )),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                          child:
                                                              _buildFilterDropdown(
                                                        "Region",
                                                        _selectedDropdown2 ??
                                                            'ALL',
                                                        _isDropdownLocked(2),
                                                        (value) {
                                                          setState(() {
                                                            _selectedDropdown2 =
                                                                value;
                                                            final token =
                                                                Provider.of<AuthProvider>(
                                                                        context,
                                                                        listen:
                                                                            false)
                                                                    .token;
                                                            if (value ==
                                                                'ALL') {
                                                              _selectedDropdown3 =
                                                                  'ALL';
                                                              _selectedDropdown4 =
                                                                  'ALL';
                                                              _selectedDropdown5 =
                                                                  'ALL';
                                                              _subRegions
                                                                  .clear();
                                                              _subAreas.clear();
                                                              _mcList.clear();
                                                            } else {
                                                              int regionId = _regions
                                                                  .firstWhere((r) =>
                                                                      r['name'] ==
                                                                      value)['id'];
                                                              fetchSubRegions(
                                                                      regionId,
                                                                      token)
                                                                  .then((_) {
                                                                // Logic for role 1 or other roles can be added here if needed
                                                              });
                                                            }
                                                          });
                                                        },
                                                        _regions
                                                            .map((r) =>
                                                                r['name']
                                                                    as String)
                                                            .toList(),
                                                      )),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                          child:
                                                              _buildFilterDropdown(
                                                        "Area",
                                                        _selectedDropdown3 ??
                                                            'ALL',
                                                        _isDropdownLocked(3),
                                                        (value) {
                                                          setState(() {
                                                            _selectedDropdown3 =
                                                                value;
                                                            final token =
                                                                Provider.of<AuthProvider>(
                                                                        context,
                                                                        listen:
                                                                            false)
                                                                    .token;
                                                            if (value ==
                                                                'ALL') {
                                                              _selectedDropdown4 =
                                                                  'ALL';
                                                              _selectedDropdown5 =
                                                                  'ALL';
                                                              _subAreas.clear();
                                                              _mcList.clear();
                                                            } else {
                                                              _selectedDropdown4 =
                                                                  'ALL';
                                                              _selectedDropdown5 =
                                                                  'ALL';
                                                              _mcList.clear();
                                                              int areaId = _subRegions
                                                                  .firstWhere((sr) =>
                                                                      sr['name'] ==
                                                                      value)['id'];
                                                              int regionId = _regions
                                                                  .firstWhere((r) =>
                                                                      r['name'] ==
                                                                      _selectedDropdown2)['id'];
                                                              fetchAreas(
                                                                  regionId,
                                                                  areaId,
                                                                  token);
                                                            }
                                                          });
                                                        },
                                                        _subRegions
                                                            .map((sr) =>
                                                                sr['name']
                                                                    as String)
                                                            .toList(),
                                                      )),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                          child:
                                                              _buildFilterDropdown(
                                                        "Branch",
                                                        _selectedDropdown4 ??
                                                            'ALL',
                                                        _isDropdownLocked(4),
                                                        (value) {
                                                          setState(() {
                                                            _selectedDropdown4 =
                                                                value;
                                                            final token =
                                                                Provider.of<AuthProvider>(
                                                                        context,
                                                                        listen:
                                                                            false)
                                                                    .token;
                                                            if (value ==
                                                                'ALL') {
                                                              _selectedDropdown5 =
                                                                  'ALL';
                                                              _mcList.clear();
                                                            } else {
                                                              int branchId = _subAreas
                                                                  .firstWhere((area) =>
                                                                      area[
                                                                          'name'] ==
                                                                      value)['id'];
                                                              int regionId = _regions
                                                                  .firstWhere((r) =>
                                                                      r['name'] ==
                                                                      _selectedDropdown2)['id'];
                                                              int areaId = _subRegions
                                                                  .firstWhere((sr) =>
                                                                      sr['name'] ==
                                                                      _selectedDropdown3)['id'];
                                                              fetchMC(
                                                                      1,
                                                                      regionId,
                                                                      areaId,
                                                                      branchId,
                                                                      token)
                                                                  .then((_) {
                                                                // Maintain selection if possible
                                                              });
                                                            }
                                                          });
                                                        },
                                                        _subAreas
                                                            .map((a) =>
                                                                a['name']
                                                                    as String)
                                                            .toList(),
                                                      )),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _buildFilterDropdown(
                                                    "MC",
                                                    _selectedDropdown5 ?? 'ALL',
                                                    _isDropdownLocked(5),
                                                    (value) {
                                                      setState(() {
                                                        _selectedDropdown5 =
                                                            value;
                                                      });
                                                    },
                                                    _mcList
                                                        .map((mc) => mc['name']
                                                            as String)
                                                        .toList(),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                            const SizedBox(height: 16),

                            // Category Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Select Category',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      hint: const Text('Select category',
                                          style: TextStyle(
                                              color: textSecondaryColor)),
                                      value: _selectedCategory,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down,
                                          color: textSecondaryColor),
                                      items: <String>[
                                        'DSE AI',
                                        'DSE',
                                        'Site',
                                        'Mitra'
                                      ].map<DropdownMenuItem<String>>(
                                          (String value) {
                                        final bool isEnabled =
                                            value == 'DSE AI';
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          enabled: isEnabled,
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                              color: isEnabled
                                                  ? textPrimaryColor
                                                  : Colors.grey.shade400,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue == 'DSE AI') {
                                          setState(() {
                                            _selectedCategory = newValue;
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  '$newValue is not available yet.'),
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Date picker container
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Select Date Range',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () =>
                                              _selectDate(context, true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _startDate == null
                                                      ? 'Start Date'
                                                      : DateFormat('dd/MM/yyyy')
                                                          .format(_startDate!),
                                                  style: TextStyle(
                                                    color: _startDate == null
                                                        ? textSecondaryColor
                                                        : textPrimaryColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const Icon(Icons.calendar_today,
                                                    size: 18,
                                                    color: textSecondaryColor),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () =>
                                              _selectDate(context, false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _endDate == null
                                                      ? 'End Date'
                                                      : DateFormat('dd/MM/yyyy')
                                                          .format(_endDate!),
                                                  style: TextStyle(
                                                    color: _endDate == null
                                                        ? textSecondaryColor
                                                        : textPrimaryColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const Icon(Icons.calendar_today,
                                                    size: 18,
                                                    color: textSecondaryColor),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Download Button
                            SizedBox(
                              width: double.infinity, // Full width
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    _isDownloading ? null : _downloadExcelFile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isDownloading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Downloading ${(_downloadProgress * 100).toInt()}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Download Excel',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
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
                height: 60, // Adjusted height
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
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_filled, // Using filled icon
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
                    // Add other navigation items here if needed, following the same pattern
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build styled dropdowns (adapted from dse.dart)
  Widget _buildFilterDropdown(
    String label,
    String value,
    bool isLocked,
    Function(String) onChanged,
    List<String> items,
  ) {
    const textPrimaryColor = Color(0xFF2D3142);
    final bool isDisabled =
        isLocked || _isDownloading; // Consider download state

    // Ensure items list is not empty and contains a default placeholder if needed
    List<String> displayItems = List.from(items);
    if (displayItems.isEmpty) {
      displayItems.add('N/A'); // Placeholder for empty list
    }
    String currentValue = value;
    if (!displayItems.contains(currentValue) && displayItems.isNotEmpty) {
      currentValue =
          displayItems.first; // Default to first if current value not in list
    }
    if (displayItems.isEmpty && currentValue != 'N/A') {
      currentValue = 'N/A';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isDense: true,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              onChanged: isDisabled ||
                      displayItems.isEmpty ||
                      (displayItems.length == 1 && displayItems.first == 'N/A')
                  ? null
                  : (newValue) => onChanged(newValue!),
              items: displayItems.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDisabled ? Colors.grey.shade400 : textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
