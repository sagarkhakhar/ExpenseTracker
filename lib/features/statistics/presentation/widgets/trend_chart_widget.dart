// This file defines the TrendChartWidget, which displays spending trends as line charts.
// It uses fl_chart for enhanced visualizations and demonstrates chart integration.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';

/// A widget that displays spending trends as a line chart.
/// Uses fl_chart for enhanced visualizations.
class TrendChartWidget extends StatelessWidget {
  /// The list of trend data to display.
  final List trends;

  /// Constructor with required trend data.
  const TrendChartWidget({
    super.key,
    required this.trends,
  });

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const Center(
        child: Text('No trend data available'),
      );
    }

    // Convert trends to chart data
    final chartData = _convertTrendsToChartData();

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
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < chartData.length) {
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
            gradient: LinearGradient(
              colors: [
                const Color(AppConstants.primaryColor),
                const Color(AppConstants.secondaryColor),
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
                  const Color(AppConstants.secondaryColor).withOpacity(0.1),
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
  }

  /// Converts trend data to chart data format.
  List<ChartDataPoint> _convertTrendsToChartData() {
    final chartData = <ChartDataPoint>[];

    for (int i = 0; i < trends.length; i++) {
      final trend = trends[i];
      final totalSpending = trend.totalSpending as double? ?? 0.0;
      final period = trend.period as String? ?? 'Period ${i + 1}';

      chartData.add(ChartDataPoint(
        label: _formatPeriodLabel(period, trend.startDate),
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
