import 'package:flutter/material.dart';

class ReusableDataTableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color sectionColor;
  final Color textPrimaryColor;
  final Color cardColor;
  final List<Map<String, dynamic>> data;
  final Map<String, dynamic>
      fixedColumn; // e.g., {'key': 'KPI_NAME', 'header': 'KPI NAME', 'width': 120.0}
  final List<Map<String, String>>
      scrollableColumns; // e.g., [{'key': 'target', 'header': 'TARGET'}, ...]
  final bool isLoading;
  final String emptyStateTitle;
  final String emptyStateSubtitle;
  final IconData emptyStateIcon;
  final String Function(dynamic) numberFormatter;
  final Function(Map<String, dynamic> rowData)? onFixedCellTap; // New callback

  const ReusableDataTableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.sectionColor,
    required this.textPrimaryColor,
    required this.cardColor,
    required this.data,
    required this.fixedColumn,
    required this.scrollableColumns,
    required this.isLoading,
    required this.emptyStateTitle,
    required this.emptyStateSubtitle,
    this.emptyStateIcon = Icons.person_search_outlined, // Default icon
    required this.numberFormatter,
    this.onFixedCellTap, // Initialize new callback
  });

  DataColumn _buildStyledColumn(String title, Color headerTextColor,
      {bool isHeaderLeft = false}) {
    return DataColumn(
      label: Container(
        alignment: isHeaderLeft ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: headerTextColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  DataCell _buildStyledDataCell(
    String text, {
    bool isLeftAligned = false,
    VoidCallback? onTap, // New: onTap callback for the cell
    bool isTappable =
        false, // New: flag to indicate if cell should be styled as a link
  }) {
    Widget cellContent = Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: isTappable
            ? Colors.blue
            : Colors.grey.shade800, // Link color if tappable
        fontWeight: FontWeight.w500,
        decoration: isTappable
            ? TextDecoration.underline
            : TextDecoration.none, // Underline if tappable
      ),
      overflow: TextOverflow.ellipsis,
    );

    if (onTap != null) {
      cellContent = InkWell(
        onTap: onTap,
        child: cellContent,
      );
    }

    return DataCell(
      Container(
        alignment: isLeftAligned ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4.0),
        child: cellContent,
      ),
    );
  }

  Widget _buildEmptyStateWidget(BuildContext context) {
    const textSecondaryColor =
        Color(0xFF8D8D92); // Assuming this color from detail_mitra
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              emptyStateIcon,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              emptyStateTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              emptyStateSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (data.isEmpty) {
      return _buildEmptyStateWidget(context);
    }

    Color headerTextColor = sectionColor.withOpacity(0.8);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sectionColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: sectionColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                // The Column that was at line 162 is removed.
                // Its child Row is now the child of SingleChildScrollView.
                child: SingleChildScrollView(
                  // Added for vertical scrolling of the table content
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed Column
                      SizedBox(
                        width: fixedColumn['width'] as double? ?? 120.0,
                        child: DataTable(
                          horizontalMargin: 8,
                          columnSpacing: 4,
                          headingRowHeight: 36,
                          dataRowHeight: 32,
                          headingRowColor: WidgetStateProperty.all(
                              sectionColor.withOpacity(0.1)),
                          columns: [
                            _buildStyledColumn(
                                fixedColumn['header'] as String? ?? 'HEADER',
                                headerTextColor,
                                isHeaderLeft: true),
                          ],
                          rows: data.map((item) {
                            final index = data.indexOf(item);
                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color>(
                                  (states) => index % 2 == 0
                                      ? Colors.white
                                      : const Color(0xFFFAFAFF)),
                              cells: [
                                _buildStyledDataCell(
                                  item[fixedColumn['key'] as String]
                                          ?.toString() ??
                                      'N/A',
                                  isLeftAligned: true,
                                  onTap: onFixedCellTap != null
                                      ? () => onFixedCellTap!(item)
                                      : null, // Pass item to callback
                                  isTappable: onFixedCellTap != null &&
                                      (fixedColumn['key'] as String ==
                                              'username' ||
                                          fixedColumn['key'] as String ==
                                              'username_display'), // Apply link style if tappable
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      // Scrollable Columns
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                minWidth: 300), // Adjust minWidth as needed
                            child: DataTable(
                              horizontalMargin: 8,
                              columnSpacing: 10,
                              headingRowHeight: 36,
                              dataRowHeight: 32,
                              headingRowColor: WidgetStateProperty.all(
                                  sectionColor.withOpacity(0.1)),
                              columns: scrollableColumns.map((col) {
                                return _buildStyledColumn(
                                    col['header']!, headerTextColor);
                              }).toList(),
                              rows: data.map((item) {
                                final index = data.indexOf(item);
                                return DataRow(
                                  color: WidgetStateProperty.resolveWith<Color>(
                                      (states) => index % 2 == 0
                                          ? Colors.white
                                          : const Color(0xFFFAFAFF)),
                                  cells: scrollableColumns.map((col) {
                                    final value = item[col['key']!];
                                    // Check if the column key indicates a numeric value that needs formatting
                                    bool isNumericField = [
                                      'target',
                                      'poin',
                                      'mtd',
                                      'allocation', // Added from braind.dart context
                                      'actual', // Added from braind.dart context
                                      'remainder' // Added from braind.dart context
                                    ].contains(col['key']);
                                    String displayValue = isNumericField
                                        ? numberFormatter(value)
                                        : value?.toString() ?? 'N/A';
                                    return _buildStyledDataCell(displayValue);
                                  }).toList(),
                                );
                              }).toList(),
                            ),
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
      ),
    );
  }
}
