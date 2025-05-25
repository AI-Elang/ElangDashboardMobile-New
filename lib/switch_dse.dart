import 'package:elang_dashboard_new_ui/detail_dse_daily.dart';
import 'package:elang_dashboard_new_ui/detail_dse_monthly.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'auth_provider.dart';

class SwitchDse extends StatefulWidget {
  final String dseId;
  final String branchName;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;

  const SwitchDse({
    required this.dseId,
    required this.branchName,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
    super.key,
  });

  @override
  State<SwitchDse> createState() => _SwitchDseState();
}

class _SwitchDseState extends State<SwitchDse> {
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

  final String _selectedDropdown1 = 'Circle Java';
  String? _selectedDropdown2;
  String? _selectedDropdown3;
  String? _selectedDropdown4;

  // Add this near the top of _SwitchDseState class
  final List<Map<String, String>> menuOptions = [
    {
      'title': 'SUMMARY DATA MONTHLY',
    },
    {
      'title': 'SUMMARY DSE DAILY',
    }
  ];

  bool _isFiltersCollapsed = true; // Start collapsed

  @override
  void initState() {
    super.initState();

    _selectedDropdown2 = widget.selectedRegion;
    _selectedDropdown3 = widget.selectedArea;
    _selectedDropdown4 = widget.selectedBranch;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final role = Provider.of<AuthProvider>(context).role;
    final territory = Provider.of<AuthProvider>(context).territory;

    // Define our color scheme to match home_page.dart
    const primaryColor = Color(0xFF6A62B7); // Softer purple
    const accentColor = Color(0xFFEE92C2); // Soft pink
    const backgroundColor = Color(0xFFF8F9FA); // Off-white background
    const cardColor = Colors.white;
    const textPrimaryColor = Color(0xFF2D3142); // Dark blue-gray
    const textSecondaryColor = Color(0xFF8D8D92); // Medium gray

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content area
            Column(
              children: [
                // App header with gradient background
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
                      'SWITCH DSE',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Main content
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Profile & Filters Card
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: cardColor,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    // User info row
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
                                              color:
                                                  accentColor.withOpacity(0.6),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const CircleAvatar(
                                            radius: 30,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: primaryColor
                                                    .withOpacity(0.1),
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

// Filters section with collapsible functionality (like pt.dart)
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
                                              "Selected Filters", // Changed label
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
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Column(
                                                  children: [
                                                    // First row of filters
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: _buildFilterItem(
                                                              // Use original item builder
                                                              "Circle",
                                                              _selectedDropdown1),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child:
                                                              _buildFilterItem(
                                                                  // Use original item builder
                                                                  "Region",
                                                                  _selectedDropdown2 ??
                                                                      'N/A'),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Second row of filters
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              _buildFilterItem(
                                                                  // Use original item builder
                                                                  "Area",
                                                                  _selectedDropdown3 ??
                                                                      'N/A'),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child:
                                                              _buildFilterItem(
                                                                  // Use original item builder
                                                                  "Branch",
                                                                  _selectedDropdown4 ??
                                                                      'N/A'),
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

                            const SizedBox(height: 16),

                            // Menu options title
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                "DSE Report Options",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor.withOpacity(0.8),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Menu options
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: menuOptions.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      // Handle tap for each option
                                      if (index == 0) {
                                        // Handle SUMMARY DATA MONTHLY tap
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DetailDseMonthly(
                                              dseId: widget.dseId,
                                              branchName: widget.branchName,
                                            ),
                                          ),
                                        );
                                      } else {
                                        // Handle SUMMARY DSE DAILY tap
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DetailDseDaily(
                                              selectedRegion:
                                                  widget.selectedRegion,
                                              selectedArea: widget.selectedArea,
                                              selectedBranch:
                                                  widget.selectedBranch,
                                              dseId: widget.dseId,
                                              branchName: widget.branchName,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Icon container
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: index == 0
                                                  ? primaryColor
                                                      .withOpacity(0.1)
                                                  : accentColor
                                                      .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              index == 0
                                                  ? Icons.calendar_month_rounded
                                                  : Icons
                                                      .calendar_today_rounded,
                                              color: index == 0
                                                  ? primaryColor
                                                  : accentColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Menu text
                                          Expanded(
                                            child: Text(
                                              menuOptions[index]['title']!,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: textPrimaryColor,
                                              ),
                                            ),
                                          ),
                                          // Arrow icon
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: index == 0
                                                ? primaryColor
                                                : accentColor,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                            color: primaryColor,
                            size: 22,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Home",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  // Helper method to build filter items (Modified for grayed-out style)
  Widget _buildFilterItem(String label, String value) {
    // Define colors locally or pass them if needed
    const textLockedColor = Color(0xFF8D8D92); // Medium gray for locked text
    const labelColor = Color(0xFF8D8D92); // Medium gray for label

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Background for filter item
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: labelColor, // Gray label color
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2), // Spacing between label and value
          Text(
            value,
            style: const TextStyle(
              fontSize: 12, // Font size for value
              color: textLockedColor, // Gray text color for value
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis, // Prevent long text overflow
          ),
        ],
      ),
    );
  }
}
