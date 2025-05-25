import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Helper class for chart data structure
class ChartData {
  ChartData(this.x, this.y, [this.color]); // Optional color
  final String x;
  final double y;
  final Color? color; // Store color if needed per data point
}

// --- New StatefulWidget for the Dashboard Card ---
class DashboardCard extends StatefulWidget {
  final String title;
  final double value;
  final String lastUpdate;
  final List<Map<String, dynamic>> subparameters;
  final Color color;
  final TickerProvider vsync; // Receive TickerProvider

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.lastUpdate,
    required this.subparameters,
    required this.color,
    required this.vsync, // Require TickerProvider
  });

  @override
  _DashboardCardState createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  late AnimationController _mainValueController;
  late Animation<double> _mainValueAnimation;
  late List<AnimationController> _subValueControllers;
  late List<Animation<double>> _subValueAnimations;

  @override
  void initState() {
    super.initState();

    // --- Main Value Animation ---
    _mainValueController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Animation duration
      vsync: widget.vsync, // Use received TickerProvider
    );
    // Ensure end value is not null and >= 0
    final validMainValue = (widget.value >= 0) ? widget.value : 0.0;
    _mainValueAnimation =
        Tween<double>(begin: 0.0, end: validMainValue).animate(
      CurvedAnimation(parent: _mainValueController, curve: Curves.easeInOut),
    )..addListener(() {
            if (mounted) {
              // Check if widget is still in the tree
              setState(() {});
            }
          });

    // --- Subparameter Animations ---
    _subValueControllers = [];
    _subValueAnimations = [];
    for (var subParam in widget.subparameters) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: widget.vsync,
      );
      final validSubValue = ((subParam['value'] as num?)?.toDouble() ?? 0.0);
      final endValue = (validSubValue >= 0) ? validSubValue : 0.0;
      final animation = Tween<double>(begin: 0.0, end: endValue).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      )..addListener(() {
          // --- Re-enable setState for subparameter animations ---
          if (mounted) {
            setState(() {});
          }
        });
      _subValueControllers.add(controller);
      _subValueAnimations.add(animation);
    }

    // Start animations after a short delay for better visual effect
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _mainValueController.forward();
        // --- Forward sub-controllers ---
        for (var controller in _subValueControllers) {
          controller.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _mainValueController.dispose();
    for (var controller in _subValueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Title Chip (Existing Code) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.show_chart, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- Chart and Subparameters Row ---
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Align chart and list vertically
              children: [
                // --- Single Radial Bar Chart (Existing Code) ---
                SizedBox(
                  height: 65,
                  width: 65,
                  child: SfCircularChart(
                    margin: EdgeInsets.zero,
                    annotations: <CircularChartAnnotation>[
                      CircularChartAnnotation(
                        widget: Text(
                          '${(_mainValueAnimation.value).toStringAsFixed(1)}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: widget.color),
                        ),
                      )
                    ],
                    series: <RadialBarSeries<ChartData, String>>[
                      RadialBarSeries<ChartData, String>(
                        dataSource: [
                          ChartData('Main',
                              _mainValueAnimation.value.clamp(0.0, 100.0))
                        ],
                        xValueMapper: (ChartData data, _) => data.x,
                        yValueMapper: (ChartData data, _) => data.y,
                        pointColorMapper: (ChartData data, _) => widget.color,
                        trackColor: widget.color.withOpacity(0.15),
                        trackBorderWidth: 0,
                        cornerStyle: CornerStyle.bothCurve,
                        maximumValue: 100,
                        radius: '100%',
                        innerRadius: '70%',
                        enableTooltip: false,
                        animationDuration: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // --- Redesigned Subparameters List ---
                Expanded(
                  child: Column(
                    // Align items within the column to the start
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Center vertically in the row
                    children: List.generate(
                        // Limit items shown, adjust as needed
                        widget.subparameters.length > 2
                            ? 2
                            : widget.subparameters.length, (index) {
                      final subParam = widget.subparameters[index];
                      final subParamName =
                          subParam['name']?.toString() ?? 'N/A';
                      final subValueAnimation = _subValueAnimations[index];
                      const subMaxValue = 100.0;
                      final progress = (subValueAnimation.value / subMaxValue)
                          .clamp(0.0, 1.0);

                      return Padding(
                        // Reduced vertical padding to fit more lines if needed
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Subparameter Name - Allow wrapping up to 2 lines
                            Text(
                              subParamName,
                              style: const TextStyle(
                                  fontSize: 10, // Keep small font
                                  color: Colors.black54),
                              overflow: TextOverflow
                                  .ellipsis, // Ellipsis if > 2 lines
                              maxLines:
                                  2, // Allow name to wrap to a second line
                            ),
                            const SizedBox(height: 2), // Small space

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: progress, // Use animated progress
                                backgroundColor: widget.color.withOpacity(0.15),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(widget.color),
                                minHeight: 5, // Slightly thinner bar
                              ),
                            ),
                            const SizedBox(height: 1), // Very small space

                            // Value Text - Below bar, aligned right
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                // Display animated value
                                '${subValueAnimation.value.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 9, // Keep small font for value
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .black54, // Consistent color below bar
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // --- Last Update (Existing Code) ---
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 4),
            Row(
              // ... (last update row code) ...
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.update, size: 10, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Text(
                  'Last update: ${widget.lastUpdate}',
                  style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
