// This file defines the CategoryBreakdownWidget, which displays category spending breakdown.
// It uses fl_chart for enhanced visualizations and demonstrates chart integration.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';

/// A widget that displays category spending breakdown as a pie chart.
/// Uses fl_chart for enhanced visualizations.
class CategoryBreakdownWidget extends StatelessWidget {
  /// The category breakdown data to display.
  final Map<String, double> categoryBreakdown;

  /// Constructor with required category breakdown data.
  const CategoryBreakdownWidget({
    super.key,
    required this.categoryBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryBreakdown.isEmpty) {
      return const Center(
        child: Text('No category data available'),
      );
    }

    // Convert category breakdown to chart data
    final chartData = _convertCategoryBreakdownToChartData();

    // Additional validation for chart data
    if (chartData.isEmpty) {
      return const Center(
        child: Text('Invalid category data'),
      );
    }

    return SizedBox(
      height: 400, // Set a bounded height for the entire widget
      child: Column(
        children: [
          // Pie chart
          SizedBox(
            height: 150,
            child: Builder(
              builder: (context) {
                try {
                  return PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // Handle touch events if needed
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: chartData.map((data) {
                        return PieChartSectionData(
                          color: data.color,
                          value: data.value,
                          title: '${data.percentage.toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                } catch (e) {
                  return const Center(
                    child: Text('Error rendering chart'),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),

          // Category legend with flexible scrollable area
          Expanded(
            child: _buildCategoryLegend(chartData),
          ),
        ],
      ),
    );
  }

  /// Converts category breakdown to chart data format.
  List<CategoryChartData> _convertCategoryBreakdownToChartData() {
    final total =
        categoryBreakdown.values.fold<double>(0, (sum, value) => sum + value);
    final chartData = <CategoryChartData>[];

    // Define colors for categories
    final colors = [
      const Color(AppConstants.primaryColor),
      const Color(AppConstants.secondaryColor),
      const Color(AppConstants.errorColor),
      const Color(AppConstants.successColor),
      const Color(AppConstants.warningColor),
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.orange,
      Colors.pink,
    ];

    int colorIndex = 0;
    categoryBreakdown.forEach((category, amount) {
      final percentage = total > 0 ? ((amount / total) * 100).toDouble() : 0.0;

      chartData.add(CategoryChartData(
        category: category,
        value: amount,
        percentage: percentage,
        color: colors[colorIndex % colors.length],
      ));

      colorIndex++;
    });

    // Sort by value (descending) for better visualization
    chartData.sort((a, b) => b.value.compareTo(a.value));

    return chartData;
  }

  /// Builds the category legend with amounts and percentages.
  Widget _buildCategoryLegend(List<CategoryChartData> chartData) {
    return SingleChildScrollView(
      child: Column(
        children: chartData.map((data) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // Color indicator
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: data.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),

                // Category name
                Expanded(
                  child: Text(
                    data.category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Amount and percentage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyUtils.formatCurrency(data.value),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${data.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Data class for category chart visualization.
class CategoryChartData {
  /// The category name.
  final String category;

  /// The spending amount for this category.
  final double value;

  /// The percentage of total spending for this category.
  final double percentage;

  /// The color for this category in the chart.
  final Color color;

  /// Constructor with required data.
  CategoryChartData({
    required this.category,
    required this.value,
    required this.percentage,
    required this.color,
  });
}
