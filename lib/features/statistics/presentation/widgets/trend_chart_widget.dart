// This file defines the TrendChartWidget, which displays spending trends as line charts.
// It uses fl_chart for enhanced visualizations and demonstrates chart integration.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';

/// A widget that displays spending trends as a line chart.
/// Uses fl_chart for enhanced visualizations.
class TrendChartWidget extends StatefulWidget {
  /// The list of trend data to display.
  final List trends;

  /// Constructor with required trend data.
  const TrendChartWidget({
    super.key,
    required this.trends,
  });

  @override
  State<TrendChartWidget> createState() => _TrendChartWidgetState();
}

class _TrendChartWidgetState extends State<TrendChartWidget> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // Delay chart rendering to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (widget.trends.isEmpty) {
      return const Center(
        child: Text('No trend data available'),
      );
    }

    // Convert trends to chart data
    final chartData = _convertTrendsToChartData();

    // Additional validation for chart data
    if (chartData.isEmpty) {
      return const Center(
        child: Text('Invalid trend data'),
      );
    }

    // Ensure we have valid chart data
    if (chartData.length < 2) {
      return const Center(
        child: Text('Insufficient data for chart'),
      );
    }

    // Validate chart data values
    final hasValidData = chartData.any((point) => point.value > 0);
    if (!hasValidData) {
      return const Center(
        child: Text('No spending data to display'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure we have valid constraints with minimum size
        if (constraints.maxWidth <= 50 || constraints.maxHeight <= 50) {
          return const Center(
            child: Text('Chart area too small'),
          );
        }

        // Ensure we have reasonable constraints
        if (constraints.maxWidth.isInfinite ||
            constraints.maxHeight.isInfinite) {
          return const Center(
            child: Text('Chart needs defined dimensions'),
          );
        }

        try {
          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: _getHorizontalInterval(chartData),
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300]!,
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300]!,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < chartData.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            chartData[value.toInt()].label,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _getHorizontalInterval(chartData),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        CurrencyUtils.formatAbbreviatedCurrency(value),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey[400]!),
              ),
              minX: 0,
              maxX: (chartData.length - 1).toDouble(),
              minY: 0,
              maxY: _getMaxY(chartData),
              lineBarsData: [
                LineChartBarData(
                  spots: chartData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
                  }).toList(),
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [
                      Color(AppConstants.primaryColor),
                      Color(AppConstants.secondaryColor),
                    ],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: const Color(AppConstants.primaryColor),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(AppConstants.primaryColor).withOpacity(0.3),
                        const Color(AppConstants.secondaryColor)
                            .withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      final data = chartData[touchedSpot.x.toInt()];
                      return LineTooltipItem(
                        '${data.label}\n${CurrencyUtils.formatCurrency(data.value)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          );
        } catch (e) {
          // Fallback to error message if chart rendering fails
          return const Center(
            child: Text('Error rendering chart'),
          );
        }
      },
    );
  }

  /// Converts trend data to chart data format.
  List<ChartDataPoint> _convertTrendsToChartData() {
    final chartData = <ChartDataPoint>[];

    for (int i = 0; i < widget.trends.length; i++) {
      final trend = widget.trends[i];

      // Validate trend object
      if (trend == null) continue;

      // Safely extract totalSpending with fallback
      double totalSpending = 0.0;
      try {
        if (trend.totalSpending != null) {
          totalSpending = (trend.totalSpending is double)
              ? trend.totalSpending
              : double.tryParse(trend.totalSpending.toString()) ?? 0.0;
        }
      } catch (e) {
        totalSpending = 0.0;
      }

      // Safely extract period with fallback
      String period = 'Period ${i + 1}';
      try {
        if (trend.period != null) {
          period = trend.period.toString();
        }
      } catch (e) {
        period = 'Period ${i + 1}';
      }

      // Safely extract startDate with fallback
      DateTime startDate = DateTime.now();
      try {
        if (trend.startDate != null) {
          startDate =
              (trend.startDate is DateTime) ? trend.startDate : DateTime.now();
        }
      } catch (e) {
        startDate = DateTime.now();
      }

      chartData.add(ChartDataPoint(
        label: _formatPeriodLabel(period, startDate),
        value: totalSpending,
      ));
    }

    return chartData;
  }

  /// Formats period label for chart display.
  String _formatPeriodLabel(String period, DateTime startDate) {
    switch (period.toLowerCase()) {
      case 'daily':
        return '${startDate.month}/${startDate.day}';
      case 'weekly':
        return 'Week ${startDate.difference(DateTime(startDate.year, 1, 1)).inDays ~/ 7}';
      case 'monthly':
        return '${startDate.month}/${startDate.year}';
      case 'yearly':
        return '${startDate.year}';
      default:
        return '${startDate.month}/${startDate.day}';
    }
  }

  /// Gets the maximum Y value for the chart.
  double _getMaxY(List<ChartDataPoint> chartData) {
    if (chartData.isEmpty) return 100;

    final maxValue =
        chartData.map((point) => point.value).reduce((a, b) => a > b ? a : b);
    return maxValue * 1.2; // Add 20% padding
  }

  /// Gets the horizontal interval for grid lines.
  double _getHorizontalInterval(List<ChartDataPoint> chartData) {
    if (chartData.isEmpty) return 100;

    final maxValue =
        chartData.map((point) => point.value).reduce((a, b) => a > b ? a : b);
    if (maxValue <= 100) return 20;
    if (maxValue <= 500) return 100;
    if (maxValue <= 1000) return 200;
    if (maxValue <= 5000) return 1000;
    return 2000;
  }
}

/// Data point for chart visualization.
class ChartDataPoint {
  /// The label for this data point.
  final String label;

  /// The value for this data point.
  final double value;

  /// Constructor with required label and value.
  ChartDataPoint({
    required this.label,
    required this.value,
  });
}
