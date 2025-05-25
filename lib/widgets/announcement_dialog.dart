import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuMigrationStatus {
  final String menuName;
  final MigrationStatus status;

  MenuMigrationStatus({required this.menuName, required this.status});
}

enum MigrationStatus { notStarted, inProgress, completed }

// Changed to StatefulWidget to support animations
class BetaAnnouncementDialog extends StatefulWidget {
  final List<MenuMigrationStatus> menuStatuses;

  const BetaAnnouncementDialog({
    super.key,
    required this.menuStatuses,
  });

  static Future<void> showIfFirstLaunch(
      BuildContext context, List<MenuMigrationStatus> statuses) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenAnnouncement =
        prefs.getBool('has_seen_beta_announcement') ?? false;

    if (!hasSeenAnnouncement) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => BetaAnnouncementDialog(menuStatuses: statuses),
        );

        // Save that user has seen the announcement
        await prefs.setBool('has_seen_beta_announcement', true);
      }
    }
  }

  @override
  State<BetaAnnouncementDialog> createState() => _BetaAnnouncementDialogState();
}

class _BetaAnnouncementDialogState extends State<BetaAnnouncementDialog>
    with SingleTickerProviderStateMixin {
  // Animation controller for the gradient
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 3), // Animation duration
      vsync: this,
    );

    // Create animation that cycles continuously
    _animation =
        Tween<double>(begin: -0.5, end: 1.5).animate(_animationController);

    // Start animation and loop it
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Modern, pleasant color palette
    const primaryColor = Color(0xFF6A62B7);
    const backgroundColor = Color(0xFFF8F9FA);
    const accentColor = Color(0xFFEE92C2);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Center(
                  child: Column(
                    children: [
                      Text(
                        "Welcome to New Elang",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Beta announcement text with BETA badge
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "We're excited to introduce the new Elang UI BETA",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF2D3142),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Animated BETA badge
                            AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor,
                                        accentColor.withOpacity(0.7),
                                      ],
                                      begin: Alignment(_animation.value, 0),
                                      end: Alignment(_animation.value + 1, 1),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    "BETA",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          "We've redesigned Elang with a fresher, more spacious, and visually appealing interface. As we're still in the beta phase, some menus are in the process of being migrated to the new design.",
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "You may notice some inconsistency between old and new UI elements as we complete the migration process. We appreciate your patience during this transition.",
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Migration status section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.auto_fix_high,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "UI Migration Status",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Status list
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: widget.menuStatuses.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = widget.menuStatuses[index];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        _buildStatusIcon(item.status),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item.menuName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF2D3142),
                                            ),
                                          ),
                                        ),
                                        _buildStatusText(item.status),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 12),

                              // Legend - Fixed to prevent overflow
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Legend:",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4A4A4A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8, // horizontal spacing
                                    runSpacing: 8, // vertical spacing
                                    children: [
                                      _buildLegendItem(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red, size: 12),
                                        label: "Not started",
                                      ),
                                      _buildLegendItem(
                                        icon: const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.amber),
                                          ),
                                        ),
                                        label: "In progress",
                                      ),
                                      _buildLegendItem(
                                        icon: const Icon(Icons.check_circle,
                                            color: Colors.green, size: 12),
                                        label: "Completed",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Button
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: primaryColor,
                  ),
                  child: const Text(
                    "Got it",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build legend items consistently
  Widget _buildLegendItem({required Widget icon, required String label}) {
    return Row(
      mainAxisSize:
          MainAxisSize.min, // Important to prevent Row from taking full width
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(MigrationStatus status) {
    switch (status) {
      case MigrationStatus.notStarted:
        return const Icon(
          Icons.close,
          color: Colors.red,
          size: 16,
        );
      case MigrationStatus.inProgress:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
        );
      case MigrationStatus.completed:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 16,
        );
    }
  }

  Widget _buildStatusText(MigrationStatus status) {
    String text;
    Color color;

    switch (status) {
      case MigrationStatus.notStarted:
        text = "Not Started";
        color = Colors.red.shade300;
        break;
      case MigrationStatus.inProgress:
        text = "In Progress";
        color = Colors.amber;
        break;
      case MigrationStatus.completed:
        text = "Completed";
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }
}
